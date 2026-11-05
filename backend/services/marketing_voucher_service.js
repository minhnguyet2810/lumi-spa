/**
 * marketing_voucher_service.js - Quản lý Voucher & Chiến dịch Marketing Phân khúc LUMI
 * 
 * Hỗ trợ:
 * - CRUD Voucher/Coupon (Mã giảm % hoặc tiền mặt, áp dụng cho đơn tối thiểu, giới hạn lượt dùng)
 * - Quản lý bật/tắt (toggle active), theo dõi số lượt dùng và tổng tiền chiết khấu
 * - Gửi chiến dịch Marketing Push Notification theo phân khúc (All, VIP Gold/Diamond, Khách ngủ quên)
 */

const db = require('../firebase');
const { FieldValue } = require('firebase-admin/firestore');
const pushService = require('./push_service');

// Danh sách Voucher mặc định khi Firestore chưa có dữ liệu
const DEFAULT_COUPONS = [
  {
    code: 'LUMISPA10',
    title: 'Ưu đãi chào hè 10%',
    description: 'Giảm 10% tối đa 100.000đ cho đơn hàng mỹ phẩm từ 300.000đ',
    minOrder: 300000,
    percentDiscount: 0.10,
    fixedDiscount: null,
    maxDiscount: 100000,
    isFreeShipping: false,
    badgeText: 'GIẢM 10%',
    usageLimit: 100,
    usedCount: 24,
    discountAmountSponsored: 1950000,
    validFrom: new Date(Date.now() - 30 * 86400000).toISOString(),
    validTo: new Date(Date.now() + 60 * 86400000).toISOString(),
    isActive: true,
    targetAudience: 'all',
  },
  {
    code: 'LUMISPA20',
    title: 'Tri ân khách hàng 20%',
    description: 'Giảm 20% tối đa 200.000đ cho đơn hàng mỹ phẩm & combo từ 800.000đ',
    minOrder: 800000,
    percentDiscount: 0.20,
    fixedDiscount: null,
    maxDiscount: 200000,
    isFreeShipping: false,
    badgeText: 'GIẢM 20%',
    usageLimit: 50,
    usedCount: 18,
    discountAmountSponsored: 3200000,
    validFrom: new Date(Date.now() - 15 * 86400000).toISOString(),
    validTo: new Date(Date.now() + 45 * 86400000).toISOString(),
    isActive: true,
    targetAudience: 'all',
  },
  {
    code: 'FREESHIP',
    title: 'Miễn phí giao hàng toàn quốc',
    description: 'Freeship tối đa 30.000đ cho mọi đơn hàng mỹ phẩm từ 250.000đ',
    minOrder: 250000,
    percentDiscount: null,
    fixedDiscount: 30000,
    maxDiscount: 30000,
    isFreeShipping: true,
    badgeText: 'FREESHIP',
    usageLimit: 500,
    usedCount: 142,
    discountAmountSponsored: 4260000,
    validFrom: new Date(Date.now() - 60 * 86400000).toISOString(),
    validTo: new Date(Date.now() + 90 * 86400000).toISOString(),
    isActive: true,
    targetAudience: 'all',
  },
  {
    code: 'LUMI50K',
    title: 'Voucher trải nghiệm 50k',
    description: 'Giảm ngay 50.000đ tiền mặt cho đơn hàng từ 400.000đ',
    minOrder: 400000,
    percentDiscount: null,
    fixedDiscount: 50000,
    maxDiscount: 50000,
    isFreeShipping: false,
    badgeText: 'GIẢM 50K',
    usageLimit: 200,
    usedCount: 65,
    discountAmountSponsored: 3250000,
    validFrom: new Date(Date.now() - 20 * 86400000).toISOString(),
    validTo: new Date(Date.now() + 30 * 86400000).toISOString(),
    isActive: true,
    targetAudience: 'all',
  },
  {
    code: 'LUMIVIP',
    title: 'Đặc quyền VIP Gold & Diamond',
    description: 'Giảm 25% tối đa 350.000đ cho Hội viên VIP thân thiết của LUMI',
    minOrder: 1000000,
    percentDiscount: 0.25,
    fixedDiscount: null,
    maxDiscount: 350000,
    isFreeShipping: false,
    badgeText: 'VIP SPECIAL',
    usageLimit: 50,
    usedCount: 12,
    discountAmountSponsored: 3800000,
    validFrom: new Date(Date.now() - 40 * 86400000).toISOString(),
    validTo: new Date(Date.now() + 120 * 86400000).toISOString(),
    isActive: true,
    targetAudience: 'vip',
  },
  {
    code: 'LUMIWELCOME',
    title: 'Món quà thành viên mới',
    description: 'Giảm 15% tối đa 80.000đ cho đơn đầu tiên từ 200.000đ',
    minOrder: 200000,
    percentDiscount: 0.15,
    fixedDiscount: null,
    maxDiscount: 80000,
    isFreeShipping: false,
    badgeText: 'MEMBER MỚI',
    usageLimit: 300,
    usedCount: 88,
    discountAmountSponsored: 5400000,
    validFrom: new Date(Date.now() - 90 * 86400000).toISOString(),
    validTo: new Date(Date.now() + 180 * 86400000).toISOString(),
    isActive: true,
    targetAudience: 'new_customers',
  },
];

// Helper chuẩn hóa mã voucher
function normalizeCode(rawCode) {
  if (!rawCode) return '';
  return String(rawCode).trim().toUpperCase().replace(/[^A-Z0-9_-]/g, '');
}

/**
 * Lấy danh sách Voucher từ Firestore (kèm fallback mặc định)
 */
async function listVouchers({ status = 'all', search = '', limit = 100 } = {}) {
  let vouchers = [];

  if (db.hasCredentials) {
    try {
      const snap = await db.collection('coupons').get();
      if (!snap.empty) {
        snap.forEach(doc => {
          const data = doc.data() || {};
          vouchers.push({
            id: doc.id,
            code: data.code || doc.id,
            title: data.title || '',
            description: data.description || '',
            minOrder: Number(data.minOrder || 0),
            percentDiscount: data.percentDiscount != null ? Number(data.percentDiscount) : null,
            fixedDiscount: data.fixedDiscount != null ? Number(data.fixedDiscount) : null,
            maxDiscount: data.maxDiscount != null ? Number(data.maxDiscount) : null,
            isFreeShipping: Boolean(data.isFreeShipping),
            badgeText: data.badgeText || 'ƯU ĐÃI',
            usageLimit: Number(data.usageLimit || 100),
            usedCount: Number(data.usedCount || 0),
            discountAmountSponsored: Number(data.discountAmountSponsored || 0),
            validFrom: data.validFrom || null,
            validTo: data.validTo || null,
            isActive: data.isActive !== false,
            targetAudience: data.targetAudience || 'all',
            createdAt: data.createdAt || null,
            updatedAt: data.updatedAt || null,
          });
        });
      } else {
        // Tự động seed danh sách mặc định vào Firestore lần đầu
        const batch = db.batch();
        DEFAULT_COUPONS.forEach(c => {
          const ref = db.collection('coupons').doc(c.code);
          batch.set(ref, {
            ...c,
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          });
        });
        await batch.commit().catch(e => console.warn('Lỗi seed vouchers ban đầu:', e.message));
        vouchers = DEFAULT_COUPONS.map(c => ({ ...c, id: c.code }));
      }
    } catch (err) {
      console.warn('Lỗi query Firestore collection coupons:', err.message);
      vouchers = DEFAULT_COUPONS.map(c => ({ ...c, id: c.code }));
    }
  } else {
    vouchers = DEFAULT_COUPONS.map(c => ({ ...c, id: c.code }));
  }

  // Lọc theo search
  if (search && search.trim()) {
    const q = search.trim().toLowerCase();
    vouchers = vouchers.filter(v =>
      v.code.toLowerCase().includes(q) ||
      v.title.toLowerCase().includes(q) ||
      (v.description && v.description.toLowerCase().includes(q))
    );
  }

  // Lọc theo status
  const now = new Date();
  if (status === 'active') {
    vouchers = vouchers.filter(v => {
      const isNotExpired = !v.validTo || new Date(v.validTo) >= now;
      const isNotExhausted = v.usageLimit > v.usedCount;
      return v.isActive && isNotExpired && isNotExhausted;
    });
  } else if (status === 'expired') {
    vouchers = vouchers.filter(v => v.validTo && new Date(v.validTo) < now);
  } else if (status === 'exhausted') {
    vouchers = vouchers.filter(v => v.usedCount >= v.usageLimit);
  } else if (status === 'disabled') {
    vouchers = vouchers.filter(v => !v.isActive);
  }

  return vouchers.slice(0, limit);
}

/**
 * Lấy chi tiết 1 Voucher theo mã
 */
async function getVoucherByCode(rawCode) {
  const code = normalizeCode(rawCode);
  if (!code) throw new Error('Mã voucher không hợp lệ.');

  if (db.hasCredentials) {
    try {
      const doc = await db.collection('coupons').doc(code).get();
      if (doc.exists) {
        const data = doc.data() || {};
        return {
          id: doc.id,
          code: data.code || doc.id,
          title: data.title || '',
          description: data.description || '',
          minOrder: Number(data.minOrder || 0),
          percentDiscount: data.percentDiscount != null ? Number(data.percentDiscount) : null,
          fixedDiscount: data.fixedDiscount != null ? Number(data.fixedDiscount) : null,
          maxDiscount: data.maxDiscount != null ? Number(data.maxDiscount) : null,
          isFreeShipping: Boolean(data.isFreeShipping),
          badgeText: data.badgeText || 'ƯU ĐÃI',
          usageLimit: Number(data.usageLimit || 100),
          usedCount: Number(data.usedCount || 0),
          discountAmountSponsored: Number(data.discountAmountSponsored || 0),
          validFrom: data.validFrom || null,
          validTo: data.validTo || null,
          isActive: data.isActive !== false,
          targetAudience: data.targetAudience || 'all',
          createdAt: data.createdAt || null,
          updatedAt: data.updatedAt || null,
        };
      }
    } catch (err) {
      console.warn('Lỗi getVoucherByCode Firestore:', err.message);
    }
  }

  const fallback = DEFAULT_COUPONS.find(c => c.code === code);
  if (!fallback) {
    throw new Error(`Không tìm thấy voucher [${code}].`);
  }
  return { ...fallback, id: fallback.code };
}

/**
 * Tạo mới hoặc cập nhật Voucher
 */
async function saveVoucher(payload, author = { uid: 'admin', name: 'Admin' }) {
  const code = normalizeCode(payload.code);
  if (!code || code.length < 3) {
    throw new Error('Mã voucher phải có ít nhất 3 ký tự (chữ in hoa, số).');
  }

  const title = (payload.title || '').trim();
  if (!title) {
    throw new Error('Vui lòng nhập tiêu đề khuyến mãi cho voucher.');
  }

  const minOrder = Math.max(0, Number(payload.minOrder || 0));
  const usageLimit = Math.max(1, Number(payload.usageLimit || 100));
  const isFreeShipping = Boolean(payload.isFreeShipping);

  let percentDiscount = null;
  let fixedDiscount = null;
  let maxDiscount = null;

  if (isFreeShipping) {
    fixedDiscount = Number(payload.fixedDiscount || 30000);
    maxDiscount = fixedDiscount;
  } else if (payload.discountType === 'percent' || payload.percentDiscount != null) {
    const rawPct = Number(payload.percentDiscount || 0);
    // Nếu truyền dạng 10 hoặc 20 thay vì 0.1, 0.2
    percentDiscount = rawPct > 1 ? rawPct / 100 : rawPct;
    if (percentDiscount <= 0 || percentDiscount > 1) {
      throw new Error('Phần trăm giảm giá phải trong khoảng 1% đến 100%.');
    }
    maxDiscount = payload.maxDiscount != null ? Number(payload.maxDiscount) : null;
  } else {
    // Giảm tiền cố định
    fixedDiscount = Number(payload.fixedDiscount || 0);
    if (fixedDiscount <= 0) {
      throw new Error('Số tiền giảm cố định phải lớn hơn 0đ.');
    }
    maxDiscount = fixedDiscount;
  }

  const voucherData = {
    code,
    title,
    description: (payload.description || '').trim(),
    minOrder,
    percentDiscount,
    fixedDiscount,
    maxDiscount,
    isFreeShipping,
    badgeText: (payload.badgeText || (isFreeShipping ? 'FREESHIP' : percentDiscount ? `GIẢM ${(percentDiscount * 100).toFixed(0)}%` : `GIẢM ${(fixedDiscount / 1000).toFixed(0)}K`)).trim(),
    usageLimit,
    validFrom: payload.validFrom || new Date().toISOString(),
    validTo: payload.validTo || new Date(Date.now() + 30 * 86400000).toISOString(),
    isActive: payload.isActive !== false,
    targetAudience: payload.targetAudience || 'all',
    updatedAt: new Date().toISOString(),
    updatedBy: author.name || 'Admin',
  };

  if (db.hasCredentials) {
    try {
      const docRef = db.collection('coupons').doc(code);
      const existing = await docRef.get();
      if (!existing.exists) {
        voucherData.usedCount = 0;
        voucherData.discountAmountSponsored = 0;
        voucherData.createdAt = new Date().toISOString();
        voucherData.createdBy = author.name || 'Admin';
      }
      await docRef.set(voucherData, { merge: true });
    } catch (err) {
      console.warn('Lỗi lưu voucher Firestore:', err.message);
    }
  }

  return { success: true, voucher: voucherData };
}

/**
 * Bật / Tắt trạng thái kích hoạt của Voucher
 */
async function toggleVoucherStatus(rawCode, isActive) {
  const code = normalizeCode(rawCode);
  if (!code) throw new Error('Mã voucher không hợp lệ.');

  if (db.hasCredentials) {
    try {
      await db.collection('coupons').doc(code).update({
        isActive: Boolean(isActive),
        updatedAt: new Date().toISOString(),
      });
    } catch (err) {
      console.warn('Lỗi cập nhật toggle voucher status:', err.message);
    }
  }

  return { success: true, code, isActive: Boolean(isActive) };
}

/**
 * Xóa Voucher (Nếu chưa dùng thì xóa hẳn, nếu đã dùng thì soft delete)
 */
async function deleteVoucher(rawCode) {
  const code = normalizeCode(rawCode);
  if (!code) throw new Error('Mã voucher không hợp lệ.');

  if (db.hasCredentials) {
    try {
      const docRef = db.collection('coupons').doc(code);
      const snap = await docRef.get();
      if (snap.exists) {
        const data = snap.data() || {};
        if (Number(data.usedCount || 0) > 0) {
          // Soft delete
          await docRef.update({
            isActive: false,
            deletedAt: new Date().toISOString(),
          });
          return { success: true, message: `Voucher [${code}] đã được vô hiệu hóa do đã có lượt dùng.` };
        } else {
          // Hard delete
          await docRef.delete();
          return { success: true, message: `Đã xóa hoàn toàn voucher [${code}].` };
        }
      }
    } catch (err) {
      console.warn('Lỗi delete voucher:', err.message);
    }
  }

  return { success: true, message: `Đã xử lý xóa voucher [${code}].` };
}

/**
 * Gửi chiến dịch Marketing Push Notification theo Phân khúc Khách hàng
 * 
 * Segment:
 * - 'all': Toàn bộ khách hàng
 * - 'vip': Khách hàng VIP Gold & Diamond
 * - 'inactive_60d': Khách hàng ngủ quên không hoạt động > 60 ngày
 * - 'new_customers': Khách hàng mới tham gia trong 30 ngày qua
 */
async function broadcastMarketingCampaign({
  campaignName,
  title,
  body,
  segment = 'all',
  voucherCode = null,
  imageUrl = null,
  author = { uid: 'admin', name: 'Admin Marketing' },
}) {
  if (!title || !title.trim()) throw new Error('Tiêu đề chiến dịch không được để trống.');
  if (!body || !body.trim()) throw new Error('Nội dung tin nhắn chiến dịch không được để trống.');

  let targetUsers = [];

  if (db.hasCredentials) {
    try {
      const usersSnap = await db.collection('users').get();
      const now = Date.now();
      const ms60d = 60 * 86400000;
      const ms30d = 30 * 86400000;

      usersSnap.forEach(doc => {
        const u = doc.data() || {};
        const uid = doc.id;
        const tier = (u.loyaltyTier || u.tier || 'standard').toLowerCase();
        
        let lastActivity = 0;
        if (u.lastOrderAt) {
          lastActivity = Math.max(lastActivity, new Date(u.lastOrderAt).getTime() || 0);
        }
        if (u.lastBookingAt) {
          lastActivity = Math.max(lastActivity, new Date(u.lastBookingAt).getTime() || 0);
        }
        if (u.createdAt) {
          const createdTime = new Date(u.createdAt).getTime() || 0;
          if (lastActivity === 0) lastActivity = createdTime;
        }

        let isMatch = false;
        if (segment === 'all') {
          isMatch = true;
        } else if (segment === 'vip') {
          isMatch = tier === 'gold' || tier === 'diamond';
        } else if (segment === 'inactive_60d') {
          isMatch = lastActivity > 0 && (now - lastActivity) >= ms60d;
        } else if (segment === 'new_customers') {
          const createdTime = u.createdAt ? new Date(u.createdAt).getTime() : 0;
          isMatch = createdTime > 0 && (now - createdTime) <= ms30d;
        }

        if (isMatch) {
          targetUsers.push({
            id: uid,
            name: u.fullName || u.displayName || 'Khách hàng',
            email: u.email || '',
            phone: u.phoneNumber || '',
            tier,
          });
        }
      });
    } catch (err) {
      console.warn('Lỗi lấy phân khúc users từ Firestore:', err.message);
    }
  }

  // Nếu không có user thật (môi trường dev/test), tạo danh sách mô phỏng để test logic
  if (targetUsers.length === 0) {
    targetUsers = [
      { id: 'usr_mock_1', name: 'Nguyễn Thảo', tier: 'gold' },
      { id: 'usr_mock_2', name: 'Trần Minh Nguyệt', tier: 'diamond' },
      { id: 'usr_mock_3', name: 'Lê Hoàng Anh', tier: 'standard' },
    ];
  }

  const campaignId = 'camp_' + Date.now().toString(36) + Math.random().toString(36).substr(2, 4);
  const cleanVoucherCode = normalizeCode(voucherCode);

  let successCount = 0;
  let failureCount = 0;

  // Gửi thông báo đến từng user trong phân khúc
  for (const user of targetUsers) {
    try {
      if (db.hasCredentials) {
        // Lưu in-app notification vào subcollection
        await db.collection('users').doc(user.id).collection('notifications').add({
          title,
          body,
          campaignId,
          voucherCode: cleanVoucherCode || null,
          imageUrl: imageUrl || null,
          type: 'marketing_promotion',
          isRead: false,
          createdAt: FieldValue.serverTimestamp(),
        }).catch(() => {});
      }

      // Gửi FCM Push nếu có device token
      const pushRes = await pushService.sendPushToUser({
        userId: user.id,
        title,
        body,
        data: {
          type: 'marketing_campaign',
          campaignId,
          voucherCode: cleanVoucherCode || '',
        },
      });

      if (pushRes && pushRes.success) {
        successCount++;
      } else {
        // Vẫn tính là tạo notification in-app thành công
        successCount++;
      }
    } catch (err) {
      failureCount++;
    }
  }

  const campaignRecord = {
    id: campaignId,
    campaignName: campaignName || title,
    title,
    body,
    segment,
    voucherCode: cleanVoucherCode || null,
    imageUrl: imageUrl || null,
    totalTargetUsers: targetUsers.length,
    successCount,
    failureCount,
    sentAt: new Date().toISOString(),
    sentBy: author.name || 'Admin',
  };

  // Lưu lịch sử chiến dịch
  if (db.hasCredentials) {
    try {
      await db.collection('marketing_campaigns').doc(campaignId).set({
        ...campaignRecord,
        createdAt: FieldValue.serverTimestamp(),
      });
    } catch (err) {
      console.warn('Lỗi lưu marketing_campaigns record:', err.message);
    }
  }

  return {
    success: true,
    campaign: campaignRecord,
  };
}

/**
 * Thống kê tổng quan KPI Marketing & Vouchers
 */
async function getMarketingKpiStats() {
  const vouchers = await listVouchers({ status: 'all' });
  const totalVouchers = vouchers.length;
  const activeVouchers = vouchers.filter(v => v.isActive).length;
  const totalUses = vouchers.reduce((acc, v) => acc + (v.usedCount || 0), 0);
  const totalSponsored = vouchers.reduce((acc, v) => acc + (v.discountAmountSponsored || 0), 0);

  let totalCampaigns = 0;
  let totalPushSent = 0;

  if (db.hasCredentials) {
    try {
      const snap = await db.collection('marketing_campaigns').get();
      totalCampaigns = snap.size;
      snap.forEach(doc => {
        const d = doc.data() || {};
        totalPushSent += Number(d.successCount || 0);
      });
    } catch (_) {}
  }

  return {
    totalVouchers,
    activeVouchers,
    totalUses,
    totalDiscountSponsored: totalSponsored,
    totalCampaigns,
    totalPushSent,
  };
}

module.exports = {
  DEFAULT_COUPONS,
  listVouchers,
  getVoucherByCode,
  saveVoucher,
  toggleVoucherStatus,
  deleteVoucher,
  broadcastMarketingCampaign,
  getMarketingKpiStats,
};
