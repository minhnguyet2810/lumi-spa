function formatOrderId(raw) {
  if (!raw) return 'LUMI - 000000';
  const str = String(raw).trim();
  if (!str) return 'LUMI - 000000';
  if (/^LUMI\s*-\s*[A-Za-z0-9]+$/i.test(str)) {
    return str.replace(/^LUMI\s*-\s*([A-Za-z0-9]+)$/i, (_, code) => `LUMI - ${code.toUpperCase()}`);
  }
  if (str.toUpperCase().startsWith('LUMI-')) {
    return `LUMI - ${str.substring(5).trim().toUpperCase()}`;
  }
  if (str.toUpperCase().startsWith('LUMI -')) {
    return `LUMI - ${str.substring(6).trim().toUpperCase()}`;
  }
  const clean = str.replace(/[^A-Za-z0-9]/g, '').toUpperCase();
  const short = clean.length > 6 ? clean.substring(0, 6) : clean.padEnd(6, '0');
  return `LUMI - ${short}`;
}

const { FieldValue } = require('firebase-admin/firestore');
const pushService = require('./push_service');

const CONVERSION_RATE = 1000; // 1000 VNĐ = 1 điểm tích luỹ

const TIERS = [
  {
    id: 'member',
    name: 'Member',
    label: 'Thành viên',
    minPoints: 0,
    maxPoints: 999,
    minSpent: 0,
    maxSpent: 999000,
    discountPercent: 0,
    color: '#C5A880',
    badge: 'Bronze',
    benefits: [
      'Tích lũy 1 điểm cho mỗi 1.000 VNĐ chi tiêu',
      'Quà tặng chào mừng: Voucher 5% cho đơn hàng đầu tiên',
      'Cập nhật thông tin ưu đãi & dịch vụ mới nhất từ LUMI',
      'Tư vấn chăm sóc da chuyên sâu 1:1 miễn phí tại spa',
    ],
  },
  {
    id: 'silver',
    name: 'Silver',
    label: 'Hạng Bạc',
    minPoints: 1000,
    maxPoints: 4999,
    minSpent: 1000000,
    maxSpent: 4999000,
    discountPercent: 5,
    color: '#94A3B8',
    badge: 'Silver',
    benefits: [
      'Toàn bộ đặc quyền của hạng Thành viên',
      'Giảm 5% trực tiếp trên mọi hóa đơn dịch vụ spa & mỹ phẩm',
      'Tặng Voucher sinh nhật trị giá 100.000 VNĐ',
      'Ưu tiên chọn khung giờ hẹn và chuyên viên yêu thích',
    ],
  },
  {
    id: 'gold',
    name: 'Gold',
    label: 'Hạng Vàng',
    minPoints: 5000,
    maxPoints: 14999,
    minSpent: 5000000,
    maxSpent: 14999000,
    discountPercent: 10,
    color: '#F59E0B',
    badge: 'Gold',
    benefits: [
      'Toàn bộ đặc quyền của hạng Bạc',
      'Giảm 10% trực tiếp trên mọi hóa đơn dịch vụ spa & mỹ phẩm',
      'Miễn phí vận chuyển (Freeship) toàn quốc cho mọi đơn hàng',
      'Tặng Voucher sinh nhật đặc biệt trị giá 300.000 VNĐ',
      'Miễn phí ngâm chân thảo mộc & thức uống cao cấp khi đến spa',
      'Hỗ trợ đổi lịch hẹn linh hoạt không phụ thu',
    ],
  },
  {
    id: 'diamond',
    name: 'Diamond',
    label: 'Kim Cương',
    minPoints: 15000,
    maxPoints: null,
    minSpent: 15000000,
    maxSpent: null,
    discountPercent: 15,
    color: '#38BDF8',
    badge: 'Diamond',
    benefits: [
      'Toàn bộ đặc quyền của hạng Vàng',
      'Giảm 15% VIP trọn đời trên mọi hóa đơn dịch vụ & mỹ phẩm',
      'Tặng 01 liệu trình chăm sóc da mặt chuyên sâu miễn phí tháng sinh nhật',
      'Trải nghiệm phòng dịch vụ VIP riêng biệt & Master KTV chăm sóc',
      'Chuyên viên chăm sóc khách hàng ưu tiên 24/7',
      'Vé mời VIP tham dự Private Workshop & sự kiện ra mắt độc quyền LUMI',
    ],
  },
];

function getTierByPoints(points) {
  const safePoints = Math.max(0, Number.isFinite(points) ? Math.floor(points) : 0);
  for (let i = TIERS.length - 1; i >= 0; i--) {
    if (safePoints >= TIERS[i].minPoints) {
      return TIERS[i];
    }
  }
  return TIERS[0];
}

function calculateMembershipDetails(rawPoints, rawTotalSpent) {
  const points = Number.isFinite(rawPoints) && rawPoints >= 0 ? Math.floor(rawPoints) : 0;
  const totalSpent = Number.isFinite(rawTotalSpent) && rawTotalSpent >= 0 ? Math.floor(rawTotalSpent) : 0;

  // Điểm tích luỹ tính hạng: căn cứ theo tổng chi tiêu hoàn tất hoặc điểm hiện có
  const tierPoints = totalSpent > 0 ? Math.floor(totalSpent / CONVERSION_RATE) : points;
  const effectivePoints = Math.max(tierPoints, points);

  const currentTier = getTierByPoints(effectivePoints);
  const currentIndex = TIERS.findIndex(t => t.id === currentTier.id);

  let nextTier = null;
  let pointsToNextTier = 0;
  let spentToNextTier = 0;
  let progress = 1.0;

  if (currentIndex < TIERS.length - 1) {
    nextTier = TIERS[currentIndex + 1];
    const effectivePoints = Math.max(totalSpent > 0 ? Math.floor(totalSpent / CONVERSION_RATE) : points, points);
    pointsToNextTier = Math.max(0, nextTier.minPoints - effectivePoints);
    spentToNextTier = pointsToNextTier * CONVERSION_RATE;
    const tierRange = nextTier.minPoints - currentTier.minPoints;
    const currentProgress = effectivePoints - currentTier.minPoints;
    progress = tierRange > 0 ? Math.min(1.0, Math.max(0.0, currentProgress / tierRange)) : 0;
  }

  return {
    tier: currentTier.name,
    tierLabel: currentTier.label,
    points,
    totalSpent,
    conversionRate: CONVERSION_RATE,
    discountPercent: currentTier.discountPercent,
    color: currentTier.color,
    badge: currentTier.badge,
    nextTier: nextTier ? nextTier.name : null,
    nextTierLabel: nextTier ? nextTier.label : null,
    pointsToNextTier,
    spentToNextTier,
    progress: Math.round(progress * 100) / 100,
    currentTierBenefits: currentTier.benefits,
    allTiers: TIERS.map(t => ({
      id: t.id,
      name: t.name,
      label: t.label,
      minPoints: t.minPoints,
      maxPoints: t.maxPoints,
      minSpent: t.minSpent,
      maxSpent: t.maxSpent,
      discountPercent: t.discountPercent,
      color: t.color,
      badge: t.badge,
      benefits: t.benefits,
    })),
  };
}

/**
 * Tích lũy điểm khi hoàn tất chi tiêu (Đơn hàng hoặc Dịch vụ spa)
 * Thực thi an toàn bên trong Firestore Transaction
 */
async function awardPointsInTransaction(tx, db, { userId, amount, sourceId, sourceType = 'order', description = '' }) {
  if (!userId || !Number.isSafeInteger(amount) || amount <= 0) {
    return { pointsAwarded: 0, upgraded: false };
  }

  const pointsToAdd = Math.floor(amount / CONVERSION_RATE);
  if (pointsToAdd <= 0) {
    return { pointsAwarded: 0, upgraded: false };
  }

  const memberRef = db.collection('memberships').doc(userId);
  const memberDoc = await tx.get(memberRef);

  const prevPoints = memberDoc.exists ? (Number(memberDoc.data().points) || 0) : 0;
  const prevSpent = memberDoc.exists ? (Number(memberDoc.data().totalSpent) || 0) : 0;

  const newPoints = prevPoints + pointsToAdd;
  const newSpent = prevSpent + amount;

  const oldTierObj = getTierByPoints(prevPoints);
  const newTierObj = getTierByPoints(newPoints);
  const upgraded = oldTierObj.id !== newTierObj.id && newTierObj.minPoints > oldTierObj.minPoints;

  const dataToSave = {
    userId,
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
    tx.create(memberRef, {
      ...dataToSave,
      createdAt: FieldValue.serverTimestamp(),
    });
  }

  return {
    pointsAwarded: pointsToAdd,
    newPoints,
    newSpent,
    oldTier: oldTierObj.name,
    newTier: newTierObj.name,
    newTierLabel: newTierObj.label,
    upgraded,
  };
}

/**
 * Gửi thông báo tích điểm và thăng hạng sau khi transaction thành công
 */
async function sendPointsNotification(db, { userId, pointsAwarded, newPoints, newTier, newTierLabel, upgraded, sourceId, sourceType }) {
  if (!userId || !db.hasCredentials || pointsAwarded <= 0) return;

  const isOrder = sourceType !== 'booking';
  const sourceName = isOrder ? 'đơn hàng' : 'liệu trình spa';
  const formattedSourceId = isOrder && sourceId ? formatOrderId(sourceId) : sourceId;

  try {
    // 1. Thông báo tích điểm
    await db.collection('notifications').add({
      userId,
      title: 'Tích điểm thành công ✨',
      message: `Bạn nhận được +${pointsAwarded.toLocaleString('vi-VN')} điểm từ ${sourceName} #${formattedSourceId || ''} (Quy đổi 1.000 VNĐ = 1 điểm). Tổng điểm hiện tại: ${newPoints.toLocaleString('vi-VN')} điểm.`,
      type: 'points',
      isRead: false,
      createdAt: FieldValue.serverTimestamp(),
    });

    await pushService.sendPushToUser({
      userId,
      title: 'Tích điểm thành công ✨',
      body: `+${pointsAwarded.toLocaleString('vi-VN')} điểm vừa được cộng từ ${sourceName} #${formattedSourceId || ''}! `,
      data: {
        type: 'points',
        points: String(newPoints),
      },
    });

    // 2. Nếu có thăng hạng
    if (upgraded) {
      await db.collection('notifications').add({
        userId,
        title: `Chúc mừng thăng hạng ${newTierLabel} 🎉`,
        message: `Tuyệt vời! Bạn đã chính thức đạt hạng ${newTierLabel} (${newTier}) tại LUMI SPA. Hãy mở Thẻ thành viên để khám phá các đặc quyền mới nhất!`,
        type: 'membership',
        isRead: false,
        createdAt: FieldValue.serverTimestamp(),
      });

      await pushService.sendPushToUser({
        userId,
        title: `Chúc mừng thăng hạng ${newTierLabel} 🎉`,
        body: `Bạn đã được nâng lên hạng ${newTierLabel} tại LUMI SPA với nhiều ưu đãi độc quyền!`,
        data: {
          type: 'membership',
          tier: newTier,
        },
      });
    }
  } catch (err) {
    console.warn('[MembershipService] Notification error:', err.message);
  }
}

module.exports = {
  formatOrderId,
  CONVERSION_RATE,
  TIERS,
  getTierByPoints,
  calculateMembershipDetails,
  awardPointsInTransaction,
  sendPointsNotification,
};
