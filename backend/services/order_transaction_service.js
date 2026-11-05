const { FieldValue } = require('firebase-admin/firestore');
const db = require('../firebase');
const pushService = require('./push_service');
const mailService = require('./mail_service');

const ORDER_LIFECYCLE_MATRIX = {
  pending: ['confirmed', 'cancelled'],
  confirmed: ['packaging', 'cancelled'],
  packaging: ['shipping', 'cancelled'],
  shipping: ['completed', 'cancelled'],
  completed: [],
  cancelled: [],
};

/**
 * 1. Duyệt đơn hàng và trừ tồn kho chi nhánh nguyên tử (ACID Transaction)
 */
async function confirmOrderWithAtomicInventory({ orderId, staffId, branchId = 'central_hub', note = '' }) {
  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  const orderRef = db.collection('orders').doc(orderId);
  let orderData = null;

  await db.runTransaction(async (tx) => {
    const orderSnap = await tx.get(orderRef);
    if (!orderSnap.exists) {
      throw Object.assign(new Error(`Đơn hàng '${orderId}' không tồn tại.`), { statusCode: 404 });
    }

    orderData = orderSnap.data();

    if (orderData.status !== 'pending') {
      throw Object.assign(
        new Error(`Đơn hàng đang ở trạng thái '${orderData.status}', không thể duyệt.`),
        { statusCode: 409 }
      );
    }

    if (orderData.inventoryReserved === true) {
      throw Object.assign(new Error('Tồn kho của đơn hàng đã được giữ trước đó.'), { statusCode: 400 });
    }

    const items = orderData.items || [];
    if (items.length === 0) {
      throw Object.assign(new Error('Đơn hàng không có danh mục sản phẩm hợp lệ.'), { statusCode: 422 });
    }

    // Đọc đồng thời dữ liệu sản phẩm trong transaction
    const productRefs = items.map(item => db.collection('products').doc(item.productId));
    const productSnaps = await tx.getAll(...productRefs);

    // Kiểm tra tính sẵn sàng và số lượng tồn kho
    for (let i = 0; i < productSnaps.length; i++) {
      const pDoc = productSnaps[i];
      const item = items[i];

      if (!pDoc.exists || pDoc.data().isActive === false) {
        throw Object.assign(
          new Error(`Sản phẩm '${item.name || item.productId}' hiện không khả dụng.`),
          { statusCode: 400 }
        );
      }

      const pData = pDoc.data();
      const availableStock = pData.branchStocks?.[branchId] ?? pData.stock ?? 0;

      if (availableStock < item.quantity) {
        throw Object.assign(
          new Error(`Sản phẩm '${item.name || pData.name}' không đủ tồn kho tại chi nhánh (Hiện còn: ${availableStock}, yêu cầu: ${item.quantity}).`),
          { statusCode: 409 }
        );
      }
    }

    // Thực hiện trừ kho và tạo audit log
    for (let i = 0; i < productSnaps.length; i++) {
      const pDoc = productSnaps[i];
      const item = items[i];
      const pRef = productRefs[i];
      const pData = pDoc.data();
      const prevStock = pData.branchStocks?.[branchId] ?? pData.stock ?? 0;
      const nextStock = prevStock - item.quantity;

      tx.update(pRef, {
        [`branchStocks.${branchId}`]: FieldValue.increment(-item.quantity),
        stock: FieldValue.increment(-item.quantity),
        updatedAt: FieldValue.serverTimestamp(),
      });

      const logRef = db.collection('inventory_logs').doc();
      tx.set(logRef, {
        logId: logRef.id,
        productId: item.productId,
        sku: item.sku || pData.sku || item.productId,
        branchId,
        type: 'order_deduction',
        quantityDelta: -item.quantity,
        previousStock: prevStock,
        newStock: nextStock,
        referenceId: orderId,
        staffId,
        reason: `Duyệt đơn hàng #${orderId}`,
        timestamp: FieldValue.serverTimestamp(),
      });
    }

    const auditEntry = {
      fromStatus: 'pending',
      toStatus: 'confirmed',
      changedBy: staffId,
      branchId,
      note: note || 'Duyệt đơn và trừ tồn kho chi nhánh thành công.',
      timestamp: new Date().toISOString(),
    };

    tx.update(orderRef, {
      status: 'confirmed',
      inventoryReserved: true,
      branchId,
      confirmedAt: FieldValue.serverTimestamp(),
      confirmedBy: staffId,
      statusHistory: FieldValue.arrayUnion(auditEntry),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  // Gửi thông báo & email sau transaction
  try {
    if (orderData?.userId) {
      await db.collection('notifications').add({
        userId: orderData.userId,
        title: 'Đơn hàng đã được xác nhận ✨',
        message: `Đơn hàng ${pushService.formatOrderId(orderId)} đã được xác nhận và đang chuẩn bị xuất kho.`,
        type: 'order',
        orderId: pushService.formatOrderId(orderId),
        isRead: false,
        createdAt: FieldValue.serverTimestamp(),
      });

      await pushService.sendOrderStatusUpdatedPush({
        userId: orderData.userId,
        orderId,
        status: 'confirmed',
        statusText: 'đã được duyệt và đang chuẩn bị hàng ✨',
      });
    }
  } catch (err) {
    console.warn('[OrderTransaction] Gửi thông báo thất bại:', err.message);
  }

  return {
    success: true,
    orderId,
    status: 'confirmed',
    branchId,
    message: 'Duyệt đơn hàng và trừ tồn kho chi nhánh thành công!',
  };
}

/**
 * 2. Chuyển đổi trạng thái đơn hàng (Fulfillment Lifecycle: confirmed -> packaging -> shipping -> completed)
 */
async function transitionOrderStatus({
  orderId,
  toStatus,
  staffId,
  note = '',
  trackingNumber = null,
  shippingCarrier = null,
}) {
  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  const orderRef = db.collection('orders').doc(orderId);
  let orderData = null;

  await db.runTransaction(async (tx) => {
    const orderSnap = await tx.get(orderRef);
    if (!orderSnap.exists) {
      throw Object.assign(new Error(`Đơn hàng '${orderId}' không tồn tại.`), { statusCode: 404 });
    }

    orderData = orderSnap.data();
    const currentStatus = orderData.status || 'pending';
    const allowedNextStatuses = ORDER_LIFECYCLE_MATRIX[currentStatus] || [];

    if (!allowedNextStatuses.includes(toStatus)) {
      throw Object.assign(
        new Error(`Không thể chuyển trạng thái từ '${currentStatus}' sang '${toStatus}'.`),
        { statusCode: 409 }
      );
    }

    const updates = {
      status: toStatus,
      updatedAt: FieldValue.serverTimestamp(),
      lastUpdatedBy: staffId,
    };

    if (toStatus === 'packaging') {
      updates.packagedAt = FieldValue.serverTimestamp();
      updates.packagedBy = staffId;
    } else if (toStatus === 'shipping') {
      updates.shippedAt = FieldValue.serverTimestamp();
      updates.shippedBy = staffId;
      if (trackingNumber) updates.trackingNumber = trackingNumber.trim();
      if (shippingCarrier) updates.shippingCarrier = shippingCarrier.trim();
    } else if (toStatus === 'completed') {
      updates.completedAt = FieldValue.serverTimestamp();
      updates.completedBy = staffId;
    }

    const auditEntry = {
      fromStatus: currentStatus,
      toStatus,
      changedBy: staffId,
      note: note || `Chuyển trạng thái sang ${toStatus}`,
      trackingNumber: trackingNumber || null,
      timestamp: new Date().toISOString(),
    };

    updates.statusHistory = FieldValue.arrayUnion(auditEntry);
    tx.update(orderRef, updates);
  });

  // Kích hoạt thông báo đẩy theo từng chặng
  try {
    if (orderData?.userId) {
      const statusLabels = {
        packaging: 'đang được đóng gói cẩn thận 📦',
        shipping: `đã bàn giao cho đơn vị vận chuyển ${shippingCarrier || ''} 🚚`,
        completed: 'đã giao thành công đến bạn 🎉',
      };
      const text = statusLabels[toStatus] || `đã chuyển sang trạng thái "${toStatus}"`;

      await pushService.sendOrderStatusUpdatedPush({
        userId: orderData.userId,
        orderId,
        status: toStatus,
        statusText: text,
      });

      await db.collection('notifications').add({
        userId: orderData.userId,
        title: toStatus === 'shipping' ? 'Đơn hàng đang trên đường giao 🚚' : 'Cập nhật đơn hàng 🛍️',
        message: `Đơn hàng ${pushService.formatOrderId(orderId)} ${text}.`,
        type: 'order',
        orderId: pushService.formatOrderId(orderId),
        isRead: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    }
  } catch (err) {
    console.warn('[OrderTransaction] Lỗi thông báo chặng:', err.message);
  }

  return {
    success: true,
    orderId,
    status: toStatus,
    message: `Cập nhật trạng thái đơn hàng thành '${toStatus}' thành công!`,
  };
}

/**
 * 3. Hủy đơn hàng và tự động hoàn trả tồn kho (Rollback Inventory)
 */
async function cancelOrderWithAtomicRollback({ orderId, staffId, reason = '' }) {
  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  const orderRef = db.collection('orders').doc(orderId);
  let orderData = null;

  await db.runTransaction(async (tx) => {
    const orderSnap = await tx.get(orderRef);
    if (!orderSnap.exists) {
      throw Object.assign(new Error(`Đơn hàng '${orderId}' không tồn tại.`), { statusCode: 404 });
    }

    orderData = orderSnap.data();
    const currentStatus = orderData.status || 'pending';

    if (['completed', 'cancelled'].includes(currentStatus)) {
      throw Object.assign(
        new Error(`Đơn hàng đã '${currentStatus}', không thể hủy.`),
        { statusCode: 409 }
      );
    }

    const branchId = orderData.branchId || 'central_hub';
    const items = orderData.items || [];

    // Nếu tồn kho đã từng bị trừ (inventoryReserved = true), hoàn lại vào kho
    if (orderData.inventoryReserved === true && items.length > 0) {
      const productRefs = items.map(item => db.collection('products').doc(item.productId));
      const productSnaps = await tx.getAll(...productRefs);

      for (let i = 0; i < productSnaps.length; i++) {
        const pDoc = productSnaps[i];
        const item = items[i];
        const pRef = productRefs[i];

        if (pDoc.exists) {
          const pData = pDoc.data();
          const prevStock = pData.branchStocks?.[branchId] ?? pData.stock ?? 0;
          const newStock = prevStock + item.quantity;

          tx.update(pRef, {
            [`branchStocks.${branchId}`]: FieldValue.increment(item.quantity),
            stock: FieldValue.increment(item.quantity),
            updatedAt: FieldValue.serverTimestamp(),
          });

          const logRef = db.collection('inventory_logs').doc();
          tx.set(logRef, {
            logId: logRef.id,
            productId: item.productId,
            sku: item.sku || pData.sku || item.productId,
            branchId,
            type: 'order_restock',
            quantityDelta: item.quantity,
            previousStock: prevStock,
            newStock: newStock,
            referenceId: orderId,
            staffId,
            reason: `Hủy đơn hàng #${orderId}: ${reason || 'Không nêu lý do'}`,
            timestamp: FieldValue.serverTimestamp(),
          });
        }
      }
    }

    // Hoàn lại mã giảm giá nếu là user_vouchers
    if (orderData.couponCode && orderData.userId) {
      const uvSnap = await db.collection('user_vouchers')
        .where('userId', '==', orderData.userId)
        .where('code', '==', orderData.couponCode)
        .limit(1)
        .get();
      if (!uvSnap.empty) {
        tx.update(uvSnap.docs[0].ref, {
          isUsed: false,
          usedAt: null,
          usedOrder: null,
        });
      }
    }

    const auditEntry = {
      fromStatus: currentStatus,
      toStatus: 'cancelled',
      changedBy: staffId,
      reason: reason || 'Hủy bởi ban quản trị',
      timestamp: new Date().toISOString(),
    };

    tx.update(orderRef, {
      status: 'cancelled',
      cancelReason: reason || 'Hủy bởi quản trị viên',
      cancelledAt: FieldValue.serverTimestamp(),
      cancelledBy: staffId,
      inventoryReserved: false,
      statusHistory: FieldValue.arrayUnion(auditEntry),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  // Bắn thông báo và gửi mail báo hủy
  try {
    if (orderData?.userId) {
      await pushService.sendOrderStatusUpdatedPush({
        userId: orderData.userId,
        orderId,
        status: 'cancelled',
        statusText: `đã bị hủy (${reason || 'Liên hệ CSKH'}) ⚠️`,
      });

      await db.collection('notifications').add({
        userId: orderData.userId,
        title: 'Đơn hàng đã bị hủy ⚠️',
        message: `Đơn hàng ${pushService.formatOrderId(orderId)} đã bị hủy. Lý do: ${reason || 'Được hủy từ hệ thống.'}`,
        type: 'order',
        orderId: pushService.formatOrderId(orderId),
        isRead: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    }
  } catch (err) {
    console.warn('[OrderTransaction] Lỗi thông báo hủy:', err.message);
  }

  return {
    success: true,
    orderId,
    status: 'cancelled',
    message: 'Hủy đơn hàng và hoàn trả tồn kho thành công!',
  };
}

module.exports = {
  confirmOrderWithAtomicInventory,
  transitionOrderStatus,
  cancelOrderWithAtomicRollback,
};
