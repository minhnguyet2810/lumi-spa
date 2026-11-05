const express = require('express');
const { FieldValue } = require('firebase-admin/firestore');
const db = require('../firebase');
const { requireAuth } = require('../auth');
const mailService = require('../services/mail_service');
const pushService = require('../services/push_service');
const { formatOrderId } = pushService;
const {
  awardPointsInTransaction,
  sendPointsNotification,
  getTierByPoints,
} = require('../services/membership_service');

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

const COUPONS = {
  'LUMISPA10': {
    code: 'LUMISPA10',
    title: 'Giảm 10% đơn hàng',
    description: 'Áp dụng cho mọi đơn mua mỹ phẩm, giảm tối đa 100.000 đ.',
    minOrder: 0,
    percentDiscount: 0.10,
    maxDiscount: 100000,
    isFreeShipping: false,
    badgeText: 'GIẢM 10%',
    usageLimit: 50,
  },
  'LUMISPA20': {
    code: 'LUMISPA20',
    title: 'Giảm 20% cho đơn từ 500k',
    description: 'Áp dụng cho đơn hàng từ 500.000 đ, giảm tối đa 200.000 đ.',
    minOrder: 500000,
    percentDiscount: 0.20,
    maxDiscount: 200000,
    isFreeShipping: false,
    badgeText: 'GIẢM 20%',
    usageLimit: 30,
  },
  'FREESHIP': {
    code: 'FREESHIP',
    title: 'Miễn phí giao hàng toàn quốc',
    description: 'Miễn phí vận chuyển 30.000 đ cho toàn bộ đơn hàng.',
    minOrder: 0,
    isFreeShipping: true,
    badgeText: 'FREESHIP',
    usageLimit: 100,
  },
  'LUMI50K': {
    code: 'LUMI50K',
    title: 'Giảm trực tiếp 50.000 đ',
    description: 'Áp dụng cho đơn hàng từ 300.000 đ trở lên.',
    minOrder: 300000,
    fixedDiscount: 50000,
    isFreeShipping: false,
    badgeText: '-50.000 đ',
    usageLimit: 25,
  },
  'LUMIVIP': {
    code: 'LUMIVIP',
    title: 'Đặc quyền VIP giảm 100.000 đ',
    description: 'Ưu đãi tri ân khách hàng thân thiết cho đơn từ 600.000 đ.',
    minOrder: 600000,
    fixedDiscount: 100000,
    isFreeShipping: false,
    badgeText: '-100.000 đ',
    usageLimit: 10,
  },
  'LUMIWELCOME': {
    code: 'LUMIWELCOME',
    title: 'Chào đón bạn mới giảm 15%',
    description: 'Dành tặng khách hàng mới của LUMI SPA, giảm tối đa 80.000 đ.',
    minOrder: 0,
    percentDiscount: 0.15,
    maxDiscount: 80000,
    isFreeShipping: false,
    badgeText: 'BẠN MỚI',
    usageLimit: 50,
  },
};

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

// GET /api/orders/coupons
router.get('/coupons', async (req, res) => {
  try {
    const usageMap = {};
    if (db.hasCredentials) {
      const snapshot = await db.collection('coupon_usage').get();
      const docs = snapshot?.docs || (typeof snapshot?.forEach === 'function' ? snapshot : []);
      if (Array.isArray(docs)) {
        docs.forEach(doc => {
          usageMap[doc.id] = Number(doc.data().usedCount) || 0;
        });
      } else if (typeof docs.forEach === 'function') {
        docs.forEach(doc => {
          usageMap[doc.id] = Number(doc.data().usedCount) || 0;
        });
      }
    }

    const FEATURED_SYSTEM_COUPON_CODES = ['FREESHIP', 'LUMISPA10', 'LUMI50K'];
    let systemCoupons = [];

    if (db.hasCredentials) {
      try {
        const couponsSnap = await db.collection('coupons').get();
        const cDocs = couponsSnap?.docs || (typeof couponsSnap?.forEach === 'function' ? couponsSnap : []);
        const cDocsArr = Array.isArray(cDocs) ? cDocs : [];
        if (cDocsArr.length > 0) {
          const now = new Date();
          cDocsArr.forEach(doc => {
            const data = doc.data() || {};
            // Chỉ hiển thị các voucher đang kích hoạt và còn hạn
            if (data.isActive !== false) {
              if (!data.validTo || new Date(data.validTo) >= now) {
                const code = data.code || doc.id;
                const usedCount = Math.max(Number(data.usedCount || 0), usageMap[code] || 0);
                const usageLimit = Number(data.usageLimit || 100);
                const remainingUses = Math.max(0, usageLimit - usedCount);
                systemCoupons.push({
                  code,
                  title: data.title || '',
                  description: data.description || '',
                  minOrder: Number(data.minOrder || 0),
                  percentDiscount: data.percentDiscount != null ? Number(data.percentDiscount) : null,
                  fixedDiscount: data.fixedDiscount != null ? Number(data.fixedDiscount) : null,
                  maxDiscount: data.maxDiscount != null ? Number(data.maxDiscount) : null,
                  isFreeShipping: Boolean(data.isFreeShipping),
                  badgeText: data.badgeText || 'ƯU ĐÃI',
                  usageLimit,
                  usedCount,
                  remainingUses,
                  isExhausted: remainingUses <= 0,
                  isUserRedeemed: false,
                });
              }
            }
          });
        }
      } catch (err) {
        console.warn('[Coupons] Error fetching coupons collection:', err.message);
      }
    }

    if (systemCoupons.length === 0) {
      systemCoupons = Object.values(COUPONS).map(c => {
        const usedCount = usageMap[c.code] || 0;
        const remainingUses = Math.max(0, c.usageLimit - usedCount);
        return {
          ...c,
          usedCount,
          remainingUses,
          isExhausted: remainingUses <= 0,
          isUserRedeemed: false,
        };
      });
    }

    let userVouchers = [];
    if (db.hasCredentials && req.user && req.user.uid) {
      const uvSnap = await db.collection('user_vouchers')
        .where('userId', '==', req.user.uid)
        .where('isUsed', '==', false)
        .get();

      const uDocs = uvSnap?.docs || (typeof uvSnap?.forEach === 'function' ? uvSnap : []);
      const uDocsArr = Array.isArray(uDocs) ? uDocs : [];
      userVouchers = uDocsArr.map(doc => {
        const d = doc.data();
        return {
          code: d.code,
          title: d.title,
          description: d.description || 'Voucher đổi từ điểm tích luỹ LUMI',
          minOrder: d.minOrder || 0,
          fixedDiscount: d.discountValue || 0,
          percentDiscount: d.percentDiscount || null,
          maxDiscount: d.maxDiscount || null,
          isFreeShipping: d.isFreeShipping === true,
          badgeText: d.badgeText || 'ĐỔI TỪ ĐIỂM',
          usageLimit: 1,
          usedCount: 0,
          remainingUses: 1,
          isExhausted: false,
          isUserRedeemed: true,
        };
      });
    }

    let allCoupons = [...userVouchers, ...systemCoupons];

    // Hỗ trợ hiển thị voucher nổi bật khi được yêu cầu tường minh
    if (req.query.featured === 'true') {
      const featured = allCoupons.filter(c => FEATURED_SYSTEM_COUPON_CODES.includes(c.code));
      return res.json({ success: true, data: featured.slice(0, 3) });
    }

    // Hỗ trợ giới hạn số lượng voucher
    if (req.query.limit) {
      const limit = parseInt(req.query.limit, 10);
      if (!isNaN(limit) && limit > 0) {
        allCoupons = allCoupons.slice(0, limit);
      }
    }

    return res.json({ success: true, data: allCoupons });
  } catch (error) {
    console.error('Coupons error:', error);
    const FEATURED_SYSTEM_COUPON_CODES = ['FREESHIP', 'LUMISPA10', 'LUMI50K'];
    let fallbackCoupons = Object.values(COUPONS).map(c => ({
      ...c,
      usedCount: 0,
      remainingUses: c.usageLimit,
      isExhausted: false,
      isUserRedeemed: false,
    }));

    if (req.query.featured === 'true') {
      fallbackCoupons = fallbackCoupons.filter(c => FEATURED_SYSTEM_COUPON_CODES.includes(c.code)).slice(0, 3);
    } else if (req.query.limit) {
      const limit = parseInt(req.query.limit, 10);
      if (!isNaN(limit) && limit > 0) {
        fallbackCoupons = fallbackCoupons.slice(0, limit);
      }
    }

    return res.json({ success: true, data: fallbackCoupons });
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
    const { items, shippingAddress, phone, customerName = '', note = '', paymentMethod = 'cod', couponCode = '' } = req.body || {};
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
    const orderNumber = Math.floor(100000 + Math.random() * 900000);
    const customOrderId = `LUMI-${orderNumber}`;
    const orderRef = db.collection('orders').doc(customOrderId);

        // Kiểm tra trước nếu mã là voucher đổi điểm của người dùng
    let userVoucherDocId = null;
    const normCouponCode = (typeof couponCode === 'string' && couponCode.trim())
      ? couponCode.trim().toUpperCase()
      : null;

    if (normCouponCode && req.user.uid && db.hasCredentials) {
      const uvSnap = await db.collection('user_vouchers')
        .where('userId', '==', req.user.uid)
        .where('code', '==', normCouponCode)
        .where('isUsed', '==', false)
        .limit(1)
        .get();
      if (!uvSnap.empty) {
        userVoucherDocId = uvSnap.docs[0].id;
      }
    }

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

      // Membership & Tier Discount calculation
      let memberTier = 'Member';
      let memberTierLabel = 'Thành viên';
      let memberDiscountPercent = 0;
      let isGoldOrAbove = false;

      if (req.user.uid) {
        const memberRef = db.collection('memberships').doc(req.user.uid);
        const memberDoc = await tx.get(memberRef);
        if (memberDoc.exists) {
          const mData = memberDoc.data();
          const mPoints = Number(mData.points) || 0;
          const tierObj = getTierByPoints(mPoints);
          memberTier = tierObj.name;
          memberTierLabel = tierObj.label;
          memberDiscountPercent = tierObj.discountPercent || 0;
          if (tierObj.id === 'gold' || tierObj.id === 'diamond') {
            isGoldOrAbove = true;
          }
        }
      }

      const memberDiscount = memberDiscountPercent > 0
        ? Math.round((subtotal * memberDiscountPercent) / 100)
        : 0;

      // Shipping policy: Gold & Diamond members or subtotal >= 500k get Free shipping
      let shippingFee = (subtotal >= 500000 || isGoldOrAbove) ? 0 : 30000;
      let couponDiscount = 0;
      let appliedCoupon = null;
      let couponUsageRef = null;
      let isFromFirestoreCoupon = false;
      let firestoreCouponRef = null;

      let userVoucherRef = null;
      let couponDoc = null;
      if (normCouponCode) {
        if (userVoucherDocId) {
          userVoucherRef = db.collection('user_vouchers').doc(userVoucherDocId);
          const uvDoc = await tx.get(userVoucherRef);
          if (!uvDoc.exists || uvDoc.data().isUsed) {
            throw new Error('COUPON_EXHAUSTED');
          }
          const uvd = uvDoc.data();
          if (subtotal < (uvd.minOrder || 0)) {
            throw new Error('COUPON_MIN_ORDER_NOT_MET');
          }
          appliedCoupon = {
            code: uvd.code,
            title: uvd.title,
            isUserRedeemed: true,
          };
          if (uvd.isFreeShipping) {
            couponDiscount = shippingFee;
            shippingFee = 0;
          } else if (uvd.discountValue) {
            couponDiscount = Math.min(uvd.discountValue, subtotal);
          } else if (uvd.percentDiscount) {
            const calc = Math.round(subtotal * uvd.percentDiscount);
            couponDiscount = uvd.maxDiscount ? Math.min(calc, uvd.maxDiscount) : calc;
          }
        } else {
          // Tra cứu trực tiếp từ collection 'coupons' được Admin cấu hình trên Firestore
          let coupon = null;
          if (db.hasCredentials) {
            try {
              firestoreCouponRef = db.collection('coupons').doc(normCouponCode);
              const fsDoc = await tx.get(firestoreCouponRef);
              if (fsDoc.exists) {
                const fsData = fsDoc.data() || {};
                coupon = {
                  code: fsData.code || fsDoc.id,
                  title: fsData.title || '',
                  description: fsData.description || '',
                  minOrder: Number(fsData.minOrder || 0),
                  percentDiscount: fsData.percentDiscount != null ? Number(fsData.percentDiscount) : null,
                  fixedDiscount: fsData.fixedDiscount != null ? Number(fsData.fixedDiscount) : null,
                  maxDiscount: fsData.maxDiscount != null ? Number(fsData.maxDiscount) : null,
                  isFreeShipping: Boolean(fsData.isFreeShipping),
                  badgeText: fsData.badgeText || 'ƯU ĐÃI',
                  usageLimit: Number(fsData.usageLimit || 100),
                  usedCount: Number(fsData.usedCount || 0),
                  validFrom: fsData.validFrom || null,
                  validTo: fsData.validTo || null,
                  isActive: fsData.isActive !== false,
                };
                isFromFirestoreCoupon = true;
              }
            } catch (err) {
              console.warn('[Orders Checkout] Error reading coupon from Firestore:', err.message);
            }
          }

          if (!coupon) {
            coupon = COUPONS[normCouponCode];
          }

          if (!coupon) {
            throw new Error('INVALID_COUPON');
          }

          if (coupon.isActive === false) {
            throw new Error('COUPON_INACTIVE');
          }

          if (coupon.validTo && new Date(coupon.validTo) < new Date()) {
            throw new Error('COUPON_EXPIRED');
          }

          if (subtotal < coupon.minOrder) {
            throw new Error('COUPON_MIN_ORDER_NOT_MET');
          }

          couponUsageRef = db.collection('coupon_usage').doc(normCouponCode);
          couponDoc = await tx.get(couponUsageRef);
          const legacyUsedCount = couponDoc.exists ? (Number(couponDoc.data().usedCount) || 0) : 0;
          const currentUsedCount = isFromFirestoreCoupon ? Math.max(coupon.usedCount, legacyUsedCount) : legacyUsedCount;

          if (currentUsedCount >= coupon.usageLimit) {
            throw new Error('COUPON_EXHAUSTED');
          }

          appliedCoupon = coupon;
          if (coupon.isFreeShipping) {
            couponDiscount = shippingFee;
            shippingFee = 0;
          } else if (coupon.fixedDiscount) {
            couponDiscount = Math.min(coupon.fixedDiscount, subtotal);
          } else if (coupon.percentDiscount) {
            const calc = Math.round(subtotal * coupon.percentDiscount);
            couponDiscount = coupon.maxDiscount ? Math.min(calc, coupon.maxDiscount) : calc;
          }
        }
      }

      const totalDiscount = memberDiscount + couponDiscount;
      const total = Math.max(0, subtotal - totalDiscount) + shippingFee;

      for (let i = 0; i < docs.length; i++) {
        const product = docs[i].data();
        if (product.stock !== undefined && product.stock !== null) {
          tx.update(productRefs[i], {
            stock: FieldValue.increment(-quantities.get(productIds[i])),
          });
        }
      }

      if (userVoucherRef) {
        tx.update(userVoucherRef, {
          isUsed: true,
          usedAt: FieldValue.serverTimestamp(),
          usedOrder: orderRef.id,
        });
      } else if (appliedCoupon) {
        // Đồng bộ tăng usedCount và số tiền tài trợ trên Firestore collection 'coupons'
        if (isFromFirestoreCoupon && firestoreCouponRef) {
          tx.update(firestoreCouponRef, {
            usedCount: FieldValue.increment(1),
            discountAmountSponsored: FieldValue.increment(couponDiscount),
            updatedAt: FieldValue.serverTimestamp(),
          });
        }

        if (couponUsageRef) {
          const usageData = {
            code: appliedCoupon.code,
            usedCount: FieldValue.increment(1),
            usageLimit: appliedCoupon.usageLimit,
            lastUsedAt: FieldValue.serverTimestamp(),
          };
          if (typeof tx.set === 'function') {
            tx.set(couponUsageRef, usageData, { merge: true });
          } else if (couponDoc && couponDoc.exists) {
            tx.update(couponUsageRef, usageData);
          } else {
            tx.create(couponUsageRef, {
              ...usageData,
              usedCount: 1,
            });
          }
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
        discount: totalDiscount,
        memberDiscount,
        memberTier,
        memberTierLabel,
        memberDiscountPercent,
        couponCode: appliedCoupon ? appliedCoupon.code : null,
        couponDiscount,
        total,
        paymentMethod: paymentLabel,
        paymentStatus: 'unpaid',
        status: 'pending',
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      return {
        id: orderRef.id,
        total,
        subtotal,
        shippingFee,
        discount: totalDiscount,
        memberDiscount,
        memberTier,
        memberTierLabel,
        memberDiscountPercent,
        couponCode: appliedCoupon ? appliedCoupon.code : null,
        couponDiscount,
        items: orderItems,
      };
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
            message: 'Đơn hàng ' + formatOrderId(result.id) + ' trị giá ' + result.total.toLocaleString('vi-VN') + ' đ đã được tiếp nhận.',
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
      COUPON_EXHAUSTED: [409, 'Mã giảm giá đã hết lượt sử dụng.'],
      COUPON_MIN_ORDER_NOT_MET: [400, 'Đơn hàng chưa đạt giá trị tối thiểu để dùng mã giảm giá.'],
      INVALID_COUPON: [400, 'Mã giảm giá không hợp lệ.'],
      COUPON_INACTIVE: [400, 'Mã giảm giá hiện đang tạm ngưng áp dụng.'],
      COUPON_EXPIRED: [400, 'Mã giảm giá đã hết hạn sử dụng.'],
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

// PATCH /api/orders/:id/complete (Chỉ khách hàng sở hữu đơn mới có thể nhấn hoàn thành đơn hàng)
router.patch('/:id/complete', async (req, res) => {
  try {
    const ref = db.collection('orders').doc(req.params.id);

    let updatedOrder;
    let pointsResult = null;
    await db.runTransaction(async tx => {
      const order = await tx.get(ref);

      if (!order.exists || order.data().userId !== req.user.uid) {
        throw new Error('NOT_FOUND');
      }

      const currentStatus = (order.data().status || '').toLowerCase();
      // Cho phép hoàn thành khi đơn hàng đang giao hoặc đã xác nhận
      if (!['shipping', 'delivering', 'confirmed', 'processing'].includes(currentStatus)) {
        throw new Error('CANNOT_COMPLETE');
      }

      if (order.data().pointsAwarded !== true) {
        const orderTotal = Number(order.data().total) || 0;
        pointsResult = await awardPointsInTransaction(tx, db, {
          userId: req.user.uid,
          amount: orderTotal,
          sourceId: formatOrderId(req.params.id),
          sourceType: 'order',
        });
      }

      const earnedPoints = pointsResult?.pointsAwarded ?? (order.data().earnedPoints || 0);

      tx.update(ref, {
        status: 'completed',
        completedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        completedBy: req.user.uid,
        pointsAwarded: true,
        earnedPoints,
      });

      updatedOrder = {
        id: order.id,
        ...order.data(),
        status: 'completed',
        pointsAwarded: true,
        earnedPoints,
      };
    });

    try {
      if (req.user.uid && db.hasCredentials) {
        await db.collection('notifications').add({
          userId: req.user.uid,
          title: 'Đơn hàng hoàn tất 🎉',
          message: 'Bạn đã xác nhận nhận hàng thành công cho đơn ' + formatOrderId(req.params.id) + '. Cảm ơn bạn đã đồng hành cùng LUMI SPA!',
          type: 'order',
          isRead: false,
          createdAt: FieldValue.serverTimestamp(),
        });

        await pushService.sendPushToUser({
          userId: req.user.uid,
          title: 'Đơn hàng hoàn tất 🎉',
          body: 'Cảm ơn bạn đã xác nhận nhận hàng cho đơn ' + formatOrderId(req.params.id) + '!',
          data: {
            type: 'order',
            orderId: req.params.id,
            status: 'completed',
          },
        });

        if (pointsResult && pointsResult.pointsAwarded > 0) {
          await sendPointsNotification(db, {
            userId: req.user.uid,
            pointsAwarded: pointsResult.pointsAwarded,
            newPoints: pointsResult.newPoints,
            newTier: pointsResult.newTier,
            newTierLabel: pointsResult.newTierLabel,
            upgraded: pointsResult.upgraded,
            sourceId: req.params.id,
            sourceType: 'order',
          });
        }
      }
    } catch (e) {
      console.error('Notify complete order error:', e.message);
    }

    return res.json({
      success: true,
      message: 'Đã hoàn thành đơn hàng.',
      data: updatedOrder,
    });
  } catch (error) {
    if (error.message === 'NOT_FOUND') {
      return fail(res, 404, 'Không tìm thấy đơn hàng.');
    }
    if (error.message === 'CANNOT_COMPLETE') {
      return fail(res, 409, 'Đơn hàng chưa ở trạng thái có thể hoàn thành.');
    }

    console.error('Order complete error:', error);
    return fail(res, 500, 'Không thể hoàn thành đơn hàng.');
  }
});

module.exports = router;
