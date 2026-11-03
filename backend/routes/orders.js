const express = require('express');
const { FieldValue } = require('firebase-admin/firestore');
const db = require('../firebase');
const { requireAuth } = require('../auth');
const mailService = require('../services/mail_service');
const pushService = require('../services/push_service');

const router = express.Router();
router.use(requireAuth);

function fail(res, status, message) {
  return res.status(status).json({ success: false, message });
}

function serialize(value) {
  if (value == null) return value;
  if (typeof value.toDate === 'function') {
    return value.toDate().toISOString();
  }
  if (Array.isArray(value)) return value.map(serialize);
  if (typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value).map(([key, val]) => [key, serialize(val)])
    );
  }
  return value;
}

function getUnitPrice(product, now) {
  const basePrice = product.price;

  if (!Number.isSafeInteger(basePrice) || basePrice < 0) {
    throw new Error('INVALID_PRICE');
  }

  if (product.promotionActive === true) {
    const sale = product.salePrice;
    const start = product.promotionStartAt;
    const end = product.promotionEndAt;

    const startMs = start?.toMillis?.() ?? (
      start == null ? null : Date.parse(start)
    );
    const endMs = end?.toMillis?.() ?? (
      end == null ? null : Date.parse(end)
    );

    const validStart = startMs == null || (Number.isFinite(startMs) && now >= startMs);
    const validEnd = endMs == null || (Number.isFinite(endMs) && now <= endMs);

    if (
      validStart &&
      validEnd &&
      Number.isSafeInteger(sale) &&
      sale >= 0 &&
      sale <= basePrice
    ) {
      return sale;
    }
  }

  return basePrice;
}

// GET /api/orders
router.get('/', async (req, res) => {
  try {
    const snapshot = await db.collection('orders')
      .where('userId', '==', req.user.uid)
      .get();

    const orders = snapshot.docs
      .map(doc => ({ id: doc.id, ...serialize(doc.data()) }))
      .sort((a, b) =>
        (b.createdAt || '').localeCompare(a.createdAt || '')
      );

    return res.json({ success: true, data: orders });
  } catch (error) {
    console.error('Orders list error:', error);
    return fail(res, 500, 'Không thể tải đơn hàng.');
  }
});

// GET /api/orders/:id
router.get('/:id', async (req, res) => {
  try {
    const doc = await db.collection('orders').doc(req.params.id).get();

    if (!doc.exists || doc.data().userId !== req.user.uid) {
      return fail(res, 404, 'Không tìm thấy đơn hàng.');
    }

    return res.json({
      success: true,
      data: { id: doc.id, ...serialize(doc.data()) },
    });
  } catch (error) {
    console.error('Order detail error:', error);
    return fail(res, 500, 'Không thể tải đơn hàng.');
  }
});

// POST /api/orders
router.post('/', async (req, res) => {
  try {
    const { items, shippingAddress, phone, customerName = '', note = '', paymentMethod = 'cod' } = req.body || {};
    if (typeof customerName !== 'string' || customerName.trim().length > 100 ||
        typeof note !== 'string' || note.length > 1000 || !['cod', 'bank'].includes(paymentMethod)) {
      return fail(res, 400, 'Thông tin đơn hàng không hợp lệ.');
    }
    const paymentLabel = paymentMethod === 'bank' ? 'Chuyển khoản ngân hàng' : 'Thanh toán khi nhận hàng (COD)';

    if (!Array.isArray(items) || items.length < 1 || items.length > 30) {
      return fail(res, 400, 'Giỏ hàng không hợp lệ.');
    }

    if (
      typeof shippingAddress !== 'string' ||
      !shippingAddress.trim() ||
      shippingAddress.length > 300 ||
      typeof phone !== 'string' ||
      !/^[0-9+().\s-]{8,20}$/.test(phone.trim())
    ) {
      return fail(res, 400, 'Địa chỉ hoặc số điện thoại không hợp lệ.');
    }

    const quantities = new Map();

    for (const item of items) {
      if (
        !item ||
        typeof item.productId !== 'string' ||
        !/^[A-Za-z0-9_-]{1,100}$/.test(item.productId) ||
        !Number.isInteger(item.quantity) ||
        item.quantity < 1 ||
        item.quantity > 20
      ) {
        return fail(res, 400, 'Sản phẩm hoặc số lượng không hợp lệ.');
      }

      quantities.set(
        item.productId,
        (quantities.get(item.productId) || 0) + item.quantity
      );
    }

    if ([...quantities.values()].some(q => q > 20)) {
      return fail(res, 400, 'Số lượng mỗi sản phẩm tối đa là 20.');
    }

    const productIds = [...quantities.keys()].sort();
    const productRefs = productIds.map(id => db.collection('products').doc(id));
    const orderRef = db.collection('orders').doc();

    const result = await db.runTransaction(async tx => {
      const docs = await tx.getAll(...productRefs);
      const now = Date.now();
      const orderItems = [];
      let subtotal = 0;

      for (let i = 0; i < docs.length; i++) {
        const doc = docs[i];
        const id = productIds[i];
        const quantity = quantities.get(id);

        if (!doc.exists || doc.data().isActive === false) {
          throw new Error('PRODUCT_UNAVAILABLE');
        }

        const product = doc.data();
        const unitPrice = getUnitPrice(product, now);

        if (product.stock !== undefined && product.stock !== null) {
          if (!Number.isSafeInteger(product.stock) || product.stock < quantity) {
            throw new Error('OUT_OF_STOCK');
          }
        }

        const lineTotal = unitPrice * quantity;
        if (!Number.isSafeInteger(lineTotal)) {
          throw new Error('INVALID_PRICE');
        }

        subtotal += lineTotal;
        if (!Number.isSafeInteger(subtotal)) {
          throw new Error('INVALID_PRICE');
        }

        orderItems.push({
          productId: id,
          productName: product.name || id,
          name: product.name || id,
          price: unitPrice,
          quantity,
          unitPrice,
          subtotal: lineTotal,
        });
      }

      // Same shipping policy as checkout; calculated from trusted catalogue prices.
      const shippingFee = subtotal >= 500000 ? 0 : 30000;
      const total = subtotal + shippingFee;

      for (let i = 0; i < docs.length; i++) {
        const product = docs[i].data();
        if (product.stock !== undefined && product.stock !== null) {
          tx.update(productRefs[i], {
            stock: FieldValue.increment(-quantities.get(productIds[i])),
          });
        }
      }

      tx.create(orderRef, {
        id: orderRef.id,
        orderId: orderRef.id,
        customerName: customerName.trim() || req.user.name || '',
        customerEmail: req.user.email || '',
        note: note.trim(),
        inventoryReserved: true,
        userId: req.user.uid,
        items: orderItems,
        shippingAddress: shippingAddress.trim(),
        phone: phone.trim(),
        subtotal,
        shippingFee,
        total,
        paymentMethod: paymentLabel,
        paymentStatus: 'unpaid',
        status: 'pending',
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      return { id: orderRef.id, total, subtotal, shippingFee, items: orderItems };
    });

    (async () => {
      try {
        let customerEmail = req.user.email;
        if (!customerEmail && req.user.uid) {
          try {
            const uDoc = await db.collection('users').doc(req.user.uid).get();
            if (uDoc.exists) customerEmail = uDoc.data().email;
          } catch (_) {}
        }

        await mailService.sendOrderSuccessEmail({
          to: customerEmail,
          customerName: customerName.trim() || req.user.name || phone.trim(),
          orderId: result.id,
          items: result.items,
          subtotal: result.subtotal,
          shippingFee: result.shippingFee,
          total: result.total,
          shippingAddress: shippingAddress.trim(),
          phone: phone.trim(),
          paymentMethod: paymentLabel,
        });

        if (req.user.uid) {
          await db.collection('notifications').add({
            userId: req.user.uid,
            title: 'Đặt hàng thành công 🛍️',
            message: 'Đơn hàng #' + result.id + ' trị giá ' + result.total.toLocaleString('vi-VN') + ' đ đã được tiếp nhận.',
            type: 'order',
            isRead: false,
            createdAt: FieldValue.serverTimestamp(),
          });

          await pushService.sendOrderSuccessPush({
            userId: req.user.uid,
            orderId: result.id,
            itemCount: result.items?.length || 1,
            totalAmount: result.total,
          });
        }
      } catch (err) {
        console.error('[Order] Failed to send order email/notification:', err.message);
      }
    })();

    return res.status(201).json({
      success: true,
      data: { ...result, status: 'pending', paymentMethod: paymentLabel },
    });
  } catch (error) {
    const known = {
      PRODUCT_UNAVAILABLE: [409, 'Sản phẩm không còn khả dụng.'],
      OUT_OF_STOCK: [409, 'Sản phẩm không đủ tồn kho.'],
      INVALID_PRICE: [422, 'Giá sản phẩm chưa hợp lệ.'],
    };

    if (known[error.message]) {
      return fail(res, ...known[error.message]);
    }

    console.error('Order create error:', error);
    return fail(res, 500, 'Không thể tạo đơn hàng.');
  }
});

// PATCH /api/orders/:id/cancel
router.patch('/:id/cancel', async (req, res) => {
  try {
    const ref = db.collection('orders').doc(req.params.id);

    await db.runTransaction(async tx => {
      const order = await tx.get(ref);

      if (!order.exists || order.data().userId !== req.user.uid) {
        throw new Error('NOT_FOUND');
      }

      if (order.data().status !== 'pending') {
        throw new Error('CANNOT_CANCEL');
      }

      const items = order.data().items || [];
      // Historical client-created orders did not decrement inventory.
      const inventoryItems = order.data().inventoryReserved === true ? items : [];
      const refs = inventoryItems.map(item =>
        db.collection('products').doc(item.productId)
      );

      const docs = refs.length ? await tx.getAll(...refs) : [];

      for (let i = 0; i < inventoryItems.length; i++) {
        if (
          docs[i].exists &&
          docs[i].data().stock !== undefined &&
          docs[i].data().stock !== null
        ) {
          tx.update(refs[i], {
            stock: FieldValue.increment(inventoryItems[i].quantity),
          });
        }
      }

      tx.update(ref, {
        status: 'cancelled',
        cancelledAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    });

    return res.json({
      success: true,
      message: 'Đã hủy đơn hàng.',
    });
  } catch (error) {
    if (error.message === 'NOT_FOUND') {
      return fail(res, 404, 'Không tìm thấy đơn hàng.');
    }
    if (error.message === 'CANNOT_CANCEL') {
      return fail(res, 409, 'Đơn hàng không thể hủy.');
    }

    console.error('Order cancel error:', error);
    return fail(res, 500, 'Không thể hủy đơn hàng.');
  }
});

module.exports = router;
