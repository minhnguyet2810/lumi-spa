const express = require('express');
const { FieldValue } = require('firebase-admin/firestore');
const db = require('../firebase');
const { requireAuth } = require('../auth');
const pushService = require('../services/push_service');
const {
  calculateMembershipDetails,
  getTierByPoints,
  CONVERSION_RATE,
} = require('../services/membership_service');

const router = express.Router();
router.use(requireAuth);

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

const REWARD_CATALOG = [
  {
    id: 'voucher_30k',
    type: 'voucher',
    title: 'Voucher giảm 30.000 đ',
    description: 'Áp dụng cho mọi đơn mua mỹ phẩm LUMI, không yêu cầu giá trị tối thiểu.',
    pointsRequired: 300,
    badgeText: '-30.000 đ',
    discountValue: 30000,
    minOrder: 0,
    discountType: 'fixed',
    stock: 50,
    icon: 'confirmation_number_outlined',
  },
  {
    id: 'voucher_50k',
    type: 'voucher',
    title: 'Voucher giảm 50.000 đ',
    description: 'Áp dụng cho đơn hàng mỹ phẩm từ 250.000 đ trở lên.',
    pointsRequired: 500,
    badgeText: '-50.000 đ',
    discountValue: 50000,
    minOrder: 250000,
    discountType: 'fixed',
    stock: 35,
    icon: 'confirmation_number_outlined',
  },
  {
    id: 'voucher_freeship',
    type: 'voucher',
    title: 'Voucher Miễn phí vận chuyển',
    description: 'Miễn phí giao hàng toàn quốc trị giá 30.000 đ cho toàn bộ đơn hàng.',
    pointsRequired: 300,
    badgeText: 'FREESHIP',
    isFreeShipping: true,
    minOrder: 0,
    discountType: 'freeship',
    stock: 60,
    icon: 'local_shipping_outlined',
  },
  {
    id: 'voucher_100k',
    type: 'voucher',
    title: 'Voucher VIP giảm 100.000 đ',
    description: 'Đặc quyền cho đơn hàng từ 500.000 đ, tiết kiệm ngay 100.000 đ.',
    pointsRequired: 1000,
    badgeText: '-100.000 đ',
    discountValue: 100000,
    minOrder: 500000,
    discountType: 'fixed',
    stock: 20,
    icon: 'workspace_premium_outlined',
  },
  {
    id: 'voucher_percent_15',
    type: 'voucher',
    title: 'Voucher giảm 15% tổng đơn',
    description: 'Giảm 15% tối đa 120.000 đ cho đơn hàng từ 350.000 đ.',
    pointsRequired: 800,
    badgeText: 'GIẢM 15%',
    percentDiscount: 0.15,
    maxDiscount: 120000,
    minOrder: 350000,
    discountType: 'percent',
    stock: 25,
    icon: 'discount_outlined',
  },
  {
    id: 'gift_collagen_mask',
    type: 'gift',
    title: '01 Hộp Mặt nạ Collagen LUMI',
    description: 'Hộp 5 miếng mặt nạ tinh chất Collagen thủy phân cấp ẩm căng bóng.',
    pointsRequired: 500,
    badgeText: 'MỸ PHẨM',
    stock: 20,
    icon: 'card_giftcard_rounded',
  },
  {
    id: 'gift_herbal_foot',
    type: 'spa',
    title: '01 Liệu trình Ngâm chân thảo mộc (30p)',
    description: 'Thư giãn huyệt đạo bàn chân với thảo mộc cổ truyền tại LUMI SPA.',
    pointsRequired: 1200,
    badgeText: 'DỊCH VỤ SPA',
    stock: 15,
    icon: 'spa_outlined',
  },
  {
    id: 'gift_serum_b5',
    type: 'gift',
    title: '01 Serum Phục Hồi B5 LUMI (15ml mini)',
    description: 'Tinh chất cấp ẩm chuyên sâu, làm dịu da nhạy cảm tức thì.',
    pointsRequired: 2000,
    badgeText: 'QUÀ TẶNG VIP',
    stock: 10,
    icon: 'sanitizer_outlined',
  },
  {
    id: 'gift_facial_treatment',
    type: 'spa',
    title: '01 Liệu trình Chăm sóc da chuyên sâu 60p',
    description: 'Liệu trình chăm sóc da mặt 9 bước chuẩn y khoa cùng KTV chuyên nghiệp.',
    pointsRequired: 3500,
    badgeText: 'VIP SPA',
    stock: 5,
    icon: 'face_retouching_natural_rounded',
  },
];

// GET /api/membership
router.get('/', async (req, res) => {
  try {
    const uid = req.user.uid;
    const doc = await db.collection('memberships').doc(uid).get();

    if (!doc.exists) {
      const details = calculateMembershipDetails(0, 0);
      return res.json({
        success: true,
        data: {
          userId: uid,
          isDefault: true,
          ...details,
        },
      });
    }

    const data = doc.data();
    const points = data.points ?? 0;
    const totalSpent = data.totalSpent ?? 0;
    const details = calculateMembershipDetails(points, totalSpent);

    return res.json({
      success: true,
      data: {
        userId: uid,
        isDefault: false,
        updatedAt: data.updatedAt?.toDate?.().toISOString() || null,
        ...details,
      },
    });
  } catch (error) {
    console.error('Membership error:', error);
    return res.status(500).json({
      success: false,
      message: 'Không thể tải thông tin thành viên.',
    });
  }
});

// GET /api/membership/rewards - Danh mục quà tặng & voucher có thể đổi bằng điểm
router.get('/rewards', async (req, res) => {
  try {
    const inventoryMap = {};
    if (db.hasCredentials) {
      const snap = await db.collection('reward_inventory').get();
      snap.forEach(doc => {
        inventoryMap[doc.id] = Number(doc.data().redeemedCount) || 0;
      });
    }

    const rewards = REWARD_CATALOG.map(r => {
      const redeemed = inventoryMap[r.id] || 0;
      const remainingStock = Math.max(0, r.stock - redeemed);
      return {
        ...r,
        redeemedCount: redeemed,
        remainingStock,
        isOutOfStock: remainingStock <= 0,
      };
    });

    return res.json({ success: true, data: rewards });
  } catch (error) {
    console.error('Rewards error:', error);
    return res.json({
      success: true,
      data: REWARD_CATALOG.map(r => ({
        ...r,
        redeemedCount: 0,
        remainingStock: r.stock,
        isOutOfStock: false,
      })),
    });
  }
});

// GET /api/membership/my-rewards - Quà tặng và Voucher người dùng đã đổi
router.get('/my-rewards', async (req, res) => {
  try {
    const uid = req.user.uid;
    if (!db.hasCredentials) {
      return res.json({ success: true, data: { vouchers: [], gifts: [] } });
    }

    const [vouchersSnap, giftsSnap] = await Promise.all([
      db.collection('user_vouchers')
        .where('userId', '==', uid)
        .get(),
      db.collection('user_rewards')
        .where('userId', '==', uid)
        .get(),
    ]);

    const vouchers = vouchersSnap.docs
      .map(doc => ({ id: doc.id, ...serialize(doc.data()) }))
      .sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));

    const gifts = giftsSnap.docs
      .map(doc => ({ id: doc.id, ...serialize(doc.data()) }))
      .sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));

    return res.json({
      success: true,
      data: { vouchers, gifts },
    });
  } catch (error) {
    console.error('My rewards error:', error);
    return res.status(500).json({ success: false, message: 'Không thể tải quà đã đổi.' });
  }
});

// POST /api/membership/redeem - Đổi điểm thành voucher hoặc quà tặng
router.post('/redeem', async (req, res) => {
  try {
    const uid = req.user.uid;
    const { rewardId } = req.body || {};

    if (!rewardId || typeof rewardId !== 'string') {
      return res.status(400).json({ success: false, message: 'Vui lòng chọn quà tặng hoặc voucher muốn đổi.' });
    }

    const reward = REWARD_CATALOG.find(r => r.id === rewardId);
    if (!reward) {
      return res.status(404).json({ success: false, message: 'Quà tặng hoặc voucher không tồn tại.' });
    }

    const memberRef = db.collection('memberships').doc(uid);
    const inventoryRef = db.collection('reward_inventory').doc(reward.id);
    const suffix = Math.floor(1000 + Math.random() * 9000);

    let issuedCode = '';
    let newPoints = 0;

    await db.runTransaction(async tx => {
      const [memberDoc, inventoryDoc] = await Promise.all([
        tx.get(memberRef),
        tx.get(inventoryRef),
      ]);

      const currentPoints = memberDoc.exists ? (Number(memberDoc.data().points) || 0) : 0;
      if (currentPoints < reward.pointsRequired) {
        throw new Error('INSUFFICIENT_POINTS');
      }

      const redeemedCount = inventoryDoc.exists ? (Number(inventoryDoc.data().redeemedCount) || 0) : 0;
      const remainingStock = Math.max(0, reward.stock - redeemedCount);
      if (remainingStock <= 0) {
        throw new Error('OUT_OF_STOCK');
      }

      newPoints = currentPoints - reward.pointsRequired;

      // Cập nhật điểm của user (vẫn giữ nguyên totalSpent để bảo lưu hạng thành viên)
      tx.set(memberRef, {
        points: newPoints,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });

      // Cập nhật kho quà tặng
      tx.set(inventoryRef, {
        rewardId: reward.id,
        redeemedCount: FieldValue.increment(1),
        lastRedeemedAt: FieldValue.serverTimestamp(),
      }, { merge: true });

      if (reward.type === 'voucher') {
        const prefix = reward.discountValue
          ? `${reward.discountValue / 1000}K`
          : (reward.isFreeShipping ? 'FREE' : '15P');
        issuedCode = `LUMI${prefix}-${suffix}`;

        const vRef = db.collection('user_vouchers').doc();
        tx.set(vRef, {
          id: vRef.id,
          userId: uid,
          code: issuedCode,
          rewardId: reward.id,
          title: reward.title,
          description: reward.description,
          discountType: reward.discountType,
          discountValue: reward.discountValue || 0,
          percentDiscount: reward.percentDiscount || null,
          maxDiscount: reward.maxDiscount || null,
          isFreeShipping: reward.isFreeShipping === true,
          minOrder: reward.minOrder || 0,
          badgeText: reward.badgeText || 'ĐỔI TỪ ĐIỂM',
          isUsed: false,
          usedAt: null,
          usedOrder: null,
          createdAt: FieldValue.serverTimestamp(),
        });
      } else {
        issuedCode = `LUMIGIFT-${suffix}`;

        const gRef = db.collection('user_rewards').doc();
        tx.set(gRef, {
          id: gRef.id,
          userId: uid,
          code: issuedCode,
          rewardId: reward.id,
          title: reward.title,
          description: reward.description,
          type: reward.type,
          badgeText: reward.badgeText || 'QUÀ TẶNG',
          status: 'active',
          claimedAt: null,
          createdAt: FieldValue.serverTimestamp(),
        });
      }

      // Ghi nhận lịch sử giao dịch điểm
      const transRef = db.collection('point_transactions').doc();
      tx.set(transRef, {
        id: transRef.id,
        userId: uid,
        type: 'redeem',
        points: -reward.pointsRequired,
        rewardId: reward.id,
        rewardTitle: reward.title,
        code: issuedCode,
        createdAt: FieldValue.serverTimestamp(),
      });
    });

    // Gửi thông báo trong app & Push notification
    try {
      if (db.hasCredentials) {
        await db.collection('notifications').add({
          userId: uid,
          title: 'Đổi quà thành công 🎉',
          message: `Bạn đã đổi thành công "${reward.title}" với ${reward.pointsRequired.toLocaleString('vi-VN')} điểm. Mã ưu đãi của bạn: #${issuedCode}.`,
          type: 'reward',
          isRead: false,
          createdAt: FieldValue.serverTimestamp(),
        });

        await pushService.sendPushToUser({
          userId: uid,
          title: 'Đổi quà thành công 🎉',
          body: `Bạn đã đổi thành công "${reward.title}"! Mã ưu đãi của bạn: #${issuedCode}.`,
          data: {
            type: 'reward',
            code: issuedCode,
          },
        });
      }
    } catch (e) {
      console.warn('Redemption notification error:', e.message);
    }

    return res.json({
      success: true,
      message: `Đổi "${reward.title}" thành công!`,
      data: {
        rewardId: reward.id,
        rewardTitle: reward.title,
        code: issuedCode,
        type: reward.type,
        pointsDeducted: reward.pointsRequired,
        newPoints,
      },
    });
  } catch (error) {
    if (error.message === 'INSUFFICIENT_POINTS') {
      return res.status(400).json({ success: false, message: 'Số điểm tích lũy hiện tại không đủ để đổi phần quà này.' });
    }
    if (error.message === 'OUT_OF_STOCK') {
      return res.status(409).json({ success: false, message: 'Phần quà hoặc mã voucher này hiện đã hết số lượng.' });
    }
    console.error('Redeem error:', error);
    return res.status(500).json({ success: false, message: 'Không thể thực hiện đổi quà. Vui lòng thử lại sau.' });
  }
});

// POST /api/membership/sync (Đồng bộ lại điểm từ các đơn hàng đã hoàn tất nếu chưa được tích điểm)
router.post('/sync', async (req, res) => {
  try {
    const uid = req.user.uid;
    if (!db.hasCredentials) {
      const details = calculateMembershipDetails(0, 0);
      return res.json({ success: true, data: { userId: uid, isDefault: true, ...details } });
    }

    const ordersSnap = await db.collection('orders')
      .where('userId', '==', uid)
      .where('status', '==', 'completed')
      .get();

    let uncountedSpent = 0;
    const uncountedOrderDocs = [];
    ordersSnap.docs.forEach(d => {
      const o = d.data();
      if (o.pointsAwarded !== true) {
        uncountedSpent += (Number(o.total) || 0);
        uncountedOrderDocs.push(d);
      }
    });

    if (uncountedSpent > 0) {
      await db.runTransaction(async tx => {
        const memberRef = db.collection('memberships').doc(uid);
        const memberDoc = await tx.get(memberRef);
        const prevPoints = memberDoc.exists ? (Number(memberDoc.data().points) || 0) : 0;
        const prevSpent = memberDoc.exists ? (Number(memberDoc.data().totalSpent) || 0) : 0;

        const newSpent = prevSpent + uncountedSpent;
        const newPoints = prevPoints + Math.floor(uncountedSpent / CONVERSION_RATE);
        const newTierObj = getTierByPoints(newPoints);

        const dataToSave = {
          userId: uid,
          points: newPoints,
          totalSpent: newSpent,
          tier: newTierObj.name,
          tierLabel: newTierObj.label,
          discountPercent: newTierObj.discountPercent,
          updatedAt: FieldValue.serverTimestamp(),
        };

        if (memberDoc.exists) {
          tx.update(memberRef, dataToSave);
        } else {
          tx.create(memberRef, { ...dataToSave, createdAt: FieldValue.serverTimestamp() });
        }

        for (const oDoc of uncountedOrderDocs) {
          tx.update(oDoc.ref, {
            pointsAwarded: true,
            earnedPoints: Math.floor((Number(oDoc.data().total) || 0) / CONVERSION_RATE),
          });
        }
      });
    }

    const updatedDoc = await db.collection('memberships').doc(uid).get();
    const data = updatedDoc.exists ? updatedDoc.data() : {};
    const details = calculateMembershipDetails(data.points ?? 0, data.totalSpent ?? 0);

    return res.json({
      success: true,
      message: 'Đồng bộ điểm thành công.',
      data: {
        userId: uid,
        isDefault: !updatedDoc.exists,
        updatedAt: data.updatedAt?.toDate?.().toISOString() || null,
        ...details,
      },
    });
  } catch (error) {
    console.error('Sync membership error:', error);
    return res.status(500).json({ success: false, message: 'Không thể đồng bộ điểm thành viên.' });
  }
});

module.exports = router;
