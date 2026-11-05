const { FieldValue, Timestamp } = require('firebase-admin/firestore');
const db = require('../firebase');
const pushService = require('./push_service');
const { getTierByPoints, calculateMembershipDetails, TIERS } = require('./membership_service');

const TIER_THRESHOLDS = {
  bronze: { minPoints: 0, minSpent: 0, label: 'Thành viên Đồng', color: '#C5A880' },
  silver: { minPoints: 1000, minSpent: 1000000, label: 'Hạng Bạc', color: '#94A3B8' },
  gold: { minPoints: 5000, minSpent: 5000000, label: 'Hạng Vàng', color: '#F59E0B' },
  diamond: { minPoints: 15000, minSpent: 15000000, label: 'Kim Cương', color: '#38BDF8' },
};

function normalizeTier(tierString) {
  if (!tierString) return 'bronze';
  const t = String(tierString).trim().toLowerCase();
  if (['diamond', 'kim cương'].includes(t)) return 'diamond';
  if (['gold', 'vàng'].includes(t)) return 'gold';
  if (['silver', 'bạc'].includes(t)) return 'silver';
  return 'bronze';
}

function calculateTierFromMetrics(points = 0, lifetimeSpent = 0) {
  const p = Math.max(0, Number(points) || 0);
  const s = Math.max(0, Number(lifetimeSpent) || 0);

  if (p >= 15000 || s >= 15000000) return 'diamond';
  if (p >= 5000 || s >= 5000000) return 'gold';
  if (p >= 1000 || s >= 1000000) return 'silver';
  return 'bronze';
}

function serializeDate(val) {
  if (!val) return null;
  if (typeof val.toDate === 'function') return val.toDate().toISOString();
  if (val instanceof Date) return val.toISOString();
  if (typeof val === 'string') return val;
  return null;
}

/**
 * 1. Lấy thông tin hồ sơ khách hàng 360 độ toàn diện (Customer 360 Profile)
 */
async function getCustomer360Profile(customerId) {
  if (!customerId) {
    throw Object.assign(new Error('Mã khách hàng không được để trống.'), { statusCode: 400 });
  }

  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  // 1. Đọc dữ liệu tài khoản người dùng
  const userRef = db.collection('users').doc(customerId);
  const userSnap = await userRef.get();

  if (!userSnap.exists) {
    throw Object.assign(new Error(`Không tìm thấy hồ sơ khách hàng '${customerId}'.`), { statusCode: 404 });
  }

  const rawUser = userSnap.data();

  // 2. Đồng bộ hoặc chuẩn hóa Loyalty
  let points = Number(rawUser.loyalty?.points ?? rawUser.points ?? 0);
  let lifetimeSpent = Number(rawUser.loyalty?.lifetimeSpent ?? rawUser.totalSpent ?? 0);
  let currentTier = normalizeTier(rawUser.loyalty?.tier || rawUser.tier || calculateTierFromMetrics(points, lifetimeSpent));

  // Kiểm tra nếu có dữ liệu bên collection memberships
  try {
    const memberSnap = await db.collection('memberships').doc(customerId).get();
    if (memberSnap.exists) {
      const mData = memberSnap.data();
      if (mData.points != null && mData.points > points) points = Number(mData.points);
      if (mData.totalSpent != null && mData.totalSpent > lifetimeSpent) lifetimeSpent = Number(mData.totalSpent);
    }
  } catch (_) {}

  const loyaltyDetails = calculateMembershipDetails(points, lifetimeSpent);

  // 3. Chuẩn hóa Skin Profile
  const rawSkin = rawUser.skinProfile || {};
  const skinProfile = {
    skinType: rawSkin.skinType || 'normal',
    concerns: Array.isArray(rawSkin.concerns) ? rawSkin.concerns : [],
    knownAllergies: Array.isArray(rawSkin.knownAllergies) ? rawSkin.knownAllergies : [],
    contraindications: Array.isArray(rawSkin.contraindications) ? rawSkin.contraindications : [],
    currentRoutine: rawSkin.currentRoutine || '',
    lastConsultationAt: serializeDate(rawSkin.lastConsultationAt),
    consultedBy: rawSkin.consultedBy || null,
  };

  // 4. Lấy lịch sử điều trị lâm sàng (Subcollection users/{id}/treatment_records)
  let treatmentRecords = [];
  try {
    const trSnap = await userRef.collection('treatment_records')
      .limit(30)
      .get();

    treatmentRecords = trSnap.docs.map(doc => {
      const d = doc.data();
      return {
        id: doc.id,
        recordId: doc.id,
        ...d,
        scheduledAt: serializeDate(d.scheduledAt),
        createdAt: serializeDate(d.createdAt),
        updatedAt: serializeDate(d.updatedAt),
      };
    });

    treatmentRecords.sort((a, b) => {
      const timeA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
      const timeB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
      return timeB - timeA;
    });
  } catch (err) {
    console.warn(`[Customer360] Lỗi đọc treatment_records của ${customerId}:`, err.message);
  }

  // 5. Lấy lịch sử đơn hàng e-commerce
  let orders = [];
  try {
    const orderSnap = await db.collection('orders')
      .where('userId', '==', customerId)
      .limit(50)
      .get();

    orders = orderSnap.docs.map(doc => {
      const d = doc.data();
      return {
        id: doc.id,
        orderId: doc.id,
        ...d,
        createdAt: serializeDate(d.createdAt),
        confirmedAt: serializeDate(d.confirmedAt),
        updatedAt: serializeDate(d.updatedAt),
      };
    });

    orders.sort((a, b) => {
      const timeA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
      const timeB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
      return timeB - timeA;
    });
  } catch (err) {
    console.warn(`[Customer360] Lỗi đọc orders của ${customerId}:`, err.message);
  }

  // 6. Lấy lịch sử lịch hẹn spa
  let bookings = [];
  try {
    let bookingSnap = await db.collection('appointments')
      .where('userId', '==', customerId)
      .limit(50)
      .get();

    if (bookingSnap.empty) {
      bookingSnap = await db.collection('bookings')
        .where('userId', '==', customerId)
        .limit(50)
        .get();
    }

    bookings = bookingSnap.docs.map(doc => {
      const d = doc.data();
      return {
        id: doc.id,
        appointmentId: doc.id,
        ...d,
        startAt: serializeDate(d.startAt),
        endAt: serializeDate(d.endAt),
        createdAt: serializeDate(d.createdAt),
        confirmedAt: serializeDate(d.confirmedAt),
      };
    });

    bookings.sort((a, b) => {
      const timeA = a.startAt ? new Date(a.startAt).getTime() : 0;
      const timeB = b.startAt ? new Date(b.startAt).getTime() : 0;
      return timeB - timeA;
    });
  } catch (err) {
    console.warn(`[Customer360] Lỗi đọc bookings của ${customerId}:`, err.message);
  }

  // 7. Tổng hợp các chỉ số 360 CRM (Metrics Aggregation)
  const completedOrders = orders.filter(o => ['completed', 'shipping', 'packaging', 'confirmed'].includes(o.status));
  const orderSpend = completedOrders.reduce((sum, o) => sum + (Number(o.total) || 0), 0);
  
  const completedBookings = bookings.filter(b => b.status === 'completed');
  const cancelledBookings = bookings.filter(b => b.status === 'cancelled');
  const spaSpend = completedBookings.reduce((sum, b) => sum + (Number(b.price || b.billing?.totalAmount) || 0), 0);

  const calculatedTotalSpend = orderSpend + spaSpend;
  const effectiveLifetimeSpend = Math.max(lifetimeSpent, calculatedTotalSpend);

  const totalBookingAttempts = bookings.length;
  const noShowRate = totalBookingAttempts > 0 
    ? Math.round((cancelledBookings.length / totalBookingAttempts) * 100) 
    : 0;

  return {
    success: true,
    data: {
      customerId,
      uid: customerId,
      displayName: rawUser.displayName || rawUser.name || 'Khách hàng LUMI',
      email: rawUser.email || '',
      phone: rawUser.phone || rawUser.phoneNumber || '',
      photoUrl: rawUser.photoUrl || rawUser.avatarUrl || null,
      role: rawUser.role || 'customer',
      status: rawUser.status || 'active',
      suspendedReason: rawUser.suspendedReason || null,
      suspendedAt: serializeDate(rawUser.suspendedAt),
      suspendedBy: rawUser.suspendedBy || null,
      address: rawUser.address || rawUser.shippingAddress || '',
      createdAt: serializeDate(rawUser.createdAt),
      updatedAt: serializeDate(rawUser.updatedAt),
      lastLoginAt: serializeDate(rawUser.lastLoginAt),

      // Loyalty 360
      loyalty: {
        points,
        lifetimeSpent: effectiveLifetimeSpend,
        tier: currentTier,
        tierLabel: TIER_THRESHOLDS[currentTier]?.label || 'Thành viên Đồng',
        tierColor: TIER_THRESHOLDS[currentTier]?.color || '#C5A880',
        nextTier: loyaltyDetails.nextTier,
        nextTierLabel: loyaltyDetails.nextTierLabel,
        pointsToNextTier: loyaltyDetails.pointsToNextTier,
        spentToNextTier: loyaltyDetails.spentToNextTier,
        progress: loyaltyDetails.progress,
        benefits: loyaltyDetails.currentTierBenefits,
        discountPercent: loyaltyDetails.discountPercent,
      },

      // Clinical Skin Profile 360
      skinProfile,

      // Metrics 360
      metrics: {
        totalOrders: orders.length,
        completedOrders: completedOrders.length,
        totalOrderSpend: orderSpend,
        totalBookings: bookings.length,
        completedBookings: completedBookings.length,
        cancelledBookings: cancelledBookings.length,
        totalSpaSpend: spaSpend,
        lifetimeSpend: effectiveLifetimeSpend,
        noShowRate,
        treatmentRecordsCount: treatmentRecords.length,
      },

      // Dữ liệu chi tiết cho các Tabs
      treatmentRecords,
      recentOrders: orders.slice(0, 10),
      recentBookings: bookings.slice(0, 10),
    },
  };
}

/**
 * 2. Điều chỉnh Điểm thưởng & Hạng thành viên (Loyalty Adjustment with Audit Trail)
 */
async function adjustLoyalty({ customerId, pointsDelta = 0, newTier = null, reason = '', staffId = 'admin' }) {
  if (!customerId) {
    throw Object.assign(new Error('Mã khách hàng không được để trống.'), { statusCode: 400 });
  }

  const delta = Number(pointsDelta) || 0;
  if (delta === 0 && !newTier) {
    throw Object.assign(new Error('Cần nhập số điểm điều chỉnh hoặc chọn thứ hạng mới.'), { statusCode: 400 });
  }

  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  const userRef = db.collection('users').doc(customerId);
  const memberRef = db.collection('memberships').doc(customerId);

  let updatedResult = null;

  await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    if (!userSnap.exists) {
      throw Object.assign(new Error(`Không tìm thấy khách hàng '${customerId}'.`), { statusCode: 404 });
    }

    const userData = userSnap.data();
    const currentPoints = Number(userData.loyalty?.points ?? userData.points ?? 0);
    const currentSpend = Number(userData.loyalty?.lifetimeSpent ?? userData.totalSpent ?? 0);
    const oldTier = normalizeTier(userData.loyalty?.tier || userData.tier || calculateTierFromMetrics(currentPoints, currentSpend));

    const finalPoints = Math.max(0, currentPoints + delta);

    let finalTier = oldTier;
    if (newTier) {
      finalTier = normalizeTier(newTier);
    } else {
      finalTier = calculateTierFromMetrics(finalPoints, currentSpend);
    }

    const now = FieldValue.serverTimestamp();

    // 1. Cập nhật hồ sơ User
    tx.set(userRef, {
      points: finalPoints,
      'loyalty.points': finalPoints,
      'loyalty.tier': finalTier,
      'loyalty.tierUpdatedAt': now,
      updatedAt: now,
    }, { merge: true });

    // 2. Đồng bộ hồ sơ Membership
    tx.set(memberRef, {
      userId: customerId,
      points: finalPoints,
      tier: finalTier,
      updatedAt: now,
    }, { merge: true });

    // 3. Ghi vết kiểm toán (Loyalty Audit Log)
    const logRef = db.collection('loyalty_logs').doc();
    tx.set(logRef, {
      logId: logRef.id,
      customerId,
      staffId,
      pointsDelta: delta,
      prevPoints: currentPoints,
      newPoints: finalPoints,
      prevTier: oldTier,
      newTier: finalTier,
      reason: reason.trim() || 'Quản trị viên điều chỉnh thủ công',
      createdAt: now,
    });

    updatedResult = {
      customerId,
      prevPoints: currentPoints,
      newPoints: finalPoints,
      prevTier: oldTier,
      newTier: finalTier,
      tierUpgraded: oldTier !== finalTier,
    };
  });

  // Gửi thông báo đến khách hàng
  if (updatedResult) {
    const isUpgraded = updatedResult.tierUpgraded;
    const title = isUpgraded ? 'Chúc mừng bạn đã thay đổi hạng thành viên! 🌟' : 'Điểm thưởng LUMI của bạn đã thay đổi ✨';
    const message = isUpgraded
      ? `Hạng thành viên của bạn đã được nâng cấp lên ${TIER_THRESHOLDS[updatedResult.newTier]?.label || updatedResult.newTier}. Hãy mở app để khám phá các đặc quyền mới!`
      : `Tài khoản của bạn vừa được ${delta > 0 ? `cộng +${delta}` : `trừ ${delta}`} điểm LUMI. Lý do: ${reason.trim() || 'Điều chỉnh từ quản trị viên'}.`;

    db.collection('notifications').add({
      userId: customerId,
      title,
      message,
      type: 'loyalty',
      isRead: false,
      createdAt: FieldValue.serverTimestamp(),
    }).catch(err => console.warn('[Loyalty] Lỗi tạo thông báo:', err.message));

    pushService.sendPushToUser({
      userId: customerId,
      title,
      body: message,
      data: {
        type: 'loyalty',
        newTier: updatedResult.newTier,
        points: String(updatedResult.newPoints),
      },
    }).catch(err => console.warn('[Loyalty] Lỗi gửi push:', err.message));
  }

  return {
    success: true,
    message: 'Điều chỉnh điểm và hạng thành viên thành công.',
    data: updatedResult,
  };
}

/**
 * 3. Khóa / Mở khóa tài khoản khách hàng (Customer Moderation)
 */
async function moderateCustomer({ customerId, status, reason = '', staffId = 'admin' }) {
  if (!customerId) {
    throw Object.assign(new Error('Mã khách hàng không được để trống.'), { statusCode: 400 });
  }

  const validStatuses = ['active', 'suspended'];
  if (!validStatuses.includes(status)) {
    throw Object.assign(new Error(`Trạng thái không hợp lệ. Chỉ chấp nhận 'active' hoặc 'suspended'.`), { statusCode: 400 });
  }

  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  const userRef = db.collection('users').doc(customerId);
  const userSnap = await userRef.get();

  if (!userSnap.exists) {
    throw Object.assign(new Error(`Không tìm thấy khách hàng '${customerId}'.`), { statusCode: 404 });
  }

  const now = FieldValue.serverTimestamp();
  const updatePayload = {
    status,
    suspendedReason: status === 'suspended' ? (reason.trim() || 'Tạm khóa theo quyết định của ban quản lý') : null,
    suspendedAt: status === 'suspended' ? now : null,
    suspendedBy: status === 'suspended' ? staffId : null,
    updatedAt: now,
  };

  await userRef.update(updatePayload);

  // Ghi nhật ký kiểm toán quản trị
  await db.collection('customer_moderation_logs').add({
    customerId,
    staffId,
    action: status === 'suspended' ? 'suspend' : 'reactivate',
    reason: reason.trim() || (status === 'suspended' ? 'Tạm khóa tài khoản' : 'Kích hoạt lại tài khoản'),
    createdAt: now,
  });

  return {
    success: true,
    message: status === 'suspended' ? 'Đã tạm khóa tài khoản khách hàng thành công.' : 'Đã mở khóa tài khoản khách hàng thành công.',
    data: {
      customerId,
      status,
      reason: updatePayload.suspendedReason,
    },
  };
}

/**
 * 4. Cập nhật Hồ sơ Da liễu & Hoạt chất Dị ứng (Skin Profile & Contraindications)
 */
async function updateSkinProfile({
  customerId,
  skinType,
  concerns = [],
  knownAllergies = [],
  contraindications = [],
  currentRoutine = '',
  staffId = 'specialist',
}) {
  if (!customerId) {
    throw Object.assign(new Error('Mã khách hàng không được để trống.'), { statusCode: 400 });
  }

  const validSkinTypes = ['normal', 'oily', 'dry', 'combination', 'sensitive'];
  if (skinType && !validSkinTypes.includes(skinType.toLowerCase())) {
    throw Object.assign(new Error(`Loại da '${skinType}' không hợp lệ.`), { statusCode: 400 });
  }

  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  const userRef = db.collection('users').doc(customerId);
  const userSnap = await userRef.get();

  if (!userSnap.exists) {
    throw Object.assign(new Error(`Không tìm thấy khách hàng '${customerId}'.`), { statusCode: 404 });
  }

  const now = FieldValue.serverTimestamp();
  const skinPayload = {
    skinType: (skinType || 'normal').toLowerCase(),
    concerns: Array.isArray(concerns) ? concerns.map(s => String(s).trim()).filter(Boolean) : [],
    knownAllergies: Array.isArray(knownAllergies) ? knownAllergies.map(s => String(s).trim()).filter(Boolean) : [],
    contraindications: Array.isArray(contraindications) ? contraindications.map(s => String(s).trim()).filter(Boolean) : [],
    currentRoutine: typeof currentRoutine === 'string' ? currentRoutine.trim() : '',
    lastConsultationAt: now,
    consultedBy: staffId,
  };

  await userRef.update({
    skinProfile: skinPayload,
    updatedAt: now,
  });

  return {
    success: true,
    message: 'Cập nhật hồ sơ da liễu và hoạt chất dị ứng thành công.',
    data: {
      customerId,
      skinProfile: {
        ...skinPayload,
        lastConsultationAt: new Date().toISOString(),
      },
    },
  };
}

/**
 * 5. Cập nhật Thông Tin Hồ Sơ Khách Hàng (Tên, SĐT, Email, Địa chỉ, Ghi chú, Giới tính, Ngày sinh)
 */
async function updateCustomerProfile({
  customerId,
  displayName,
  phone,
  email,
  address,
  notes,
  gender,
  birthday,
  staffId = 'admin',
}) {
  if (!customerId) {
    throw Object.assign(new Error('Mã khách hàng không được để trống.'), { statusCode: 400 });
  }

  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  const userRef = db.collection('users').doc(customerId);
  const userSnap = await userRef.get();

  if (!userSnap.exists) {
    throw Object.assign(new Error(`Không tìm thấy khách hàng '${customerId}'.`), { statusCode: 404 });
  }

  const now = FieldValue.serverTimestamp();
  const updates = {
    updatedAt: now,
  };

  if (displayName !== undefined && typeof displayName === 'string' && displayName.trim()) {
    updates.displayName = displayName.trim();
    updates.name = displayName.trim();
  }

  if (phone !== undefined && typeof phone === 'string' && phone.trim()) {
    updates.phone = phone.trim();
    updates.phoneNumber = phone.trim();
  }

  if (email !== undefined && typeof email === 'string' && email.trim()) {
    updates.email = email.trim();
  }

  if (address !== undefined && typeof address === 'string') {
    updates.address = address.trim();
    updates.shippingAddress = address.trim();
  }

  if (notes !== undefined && typeof notes === 'string') {
    updates.adminNotes = notes.trim();
    updates.notes = notes.trim();
  }

  if (gender !== undefined && typeof gender === 'string') {
    updates.gender = gender.trim();
  }

  if (birthday !== undefined && typeof birthday === 'string') {
    updates.birthday = birthday.trim();
  }

  await userRef.set(updates, { merge: true });

  // Đồng bộ displayName sang Firebase Auth nếu khả dụng
  try {
    const { getAuth } = require('firebase-admin/auth');
    const authUpdates = {};
    if (updates.displayName) authUpdates.displayName = updates.displayName;
    if (Object.keys(authUpdates).length > 0) {
      await getAuth().updateUser(customerId, authUpdates);
    }
  } catch (_) {}

  // Ghi nhật ký kiểm toán quản trị
  try {
    await db.collection('customer_audit_logs').add({
      customerId,
      staffId,
      action: 'update_profile',
      updates,
      createdAt: now,
    });
  } catch (_) {}

  const full360 = await getCustomer360Profile(customerId);
  return {
    success: true,
    message: 'Cập nhật hồ sơ khách hàng thành công.',
    data: full360.data,
  };
}

/**
 * 6. Tra cứu danh sách Khách hàng kèm Chỉ số CRM KPI 360 độ (List Customers with CRM 360 Metrics)
 */
async function listCustomersWith360Metrics({
  query = '',
  tier = 'all',
  status = 'all',
  sortBy = 'spent_desc',
  limit = 50,
  page = 1,
}) {
  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  const snapshot = await db.collection('users').limit(200).get();

  let allUsers = snapshot.docs.map(doc => {
    const d = doc.data();
    const id = doc.id;
    const points = Number(d.loyalty?.points ?? d.points ?? 0);
    const lifetimeSpent = Number(d.loyalty?.lifetimeSpent ?? d.totalSpent ?? 0);
    const currentTier = normalizeTier(d.loyalty?.tier || d.tier || calculateTierFromMetrics(points, lifetimeSpent));

    const skin = d.skinProfile || {};
    const knownAllergies = Array.isArray(skin.knownAllergies) ? skin.knownAllergies : [];
    const contraindications = Array.isArray(skin.contraindications) ? skin.contraindications : [];

    return {
      id,
      uid: id,
      displayName: d.displayName || d.name || 'Khách hàng LUMI',
      email: d.email || '',
      phone: d.phone || d.phoneNumber || '',
      photoUrl: d.photoUrl || d.avatarUrl || null,
      role: d.role || 'customer',
      status: d.status || 'active',
      suspendedReason: d.suspendedReason || null,
      address: d.address || d.shippingAddress || '',
      points,
      lifetimeSpent,
      tier: currentTier,
      tierLabel: TIER_THRESHOLDS[currentTier]?.label || 'Thành viên Đồng',
      tierColor: TIER_THRESHOLDS[currentTier]?.color || '#C5A880',
      skinType: skin.skinType || 'normal',
      knownAllergies,
      contraindications,
      hasAllergyWarning: knownAllergies.length > 0 || contraindications.length > 0,
      bookingCount: Number(d.bookingCount) || 0,
      orderCount: Number(d.orderCount) || 0,
      createdAt: serializeDate(d.createdAt),
      updatedAt: serializeDate(d.updatedAt),
    };
  });

  // Tính toán KPI Metrics toàn diện của toàn bộ tệp khách hàng
  const totalCustomers = allUsers.length;
  const activeCustomers = allUsers.filter(u => u.status === 'active').length;
  const suspendedCustomers = allUsers.filter(u => u.status === 'suspended').length;
  const vipCustomers = allUsers.filter(u => ['gold', 'diamond'].includes(u.tier)).length;
  
  const totalSystemSpent = allUsers.reduce((sum, u) => sum + u.lifetimeSpent, 0);
  const averageSpend = totalCustomers > 0 ? Math.round(totalSystemSpent / totalCustomers) : 0;

  const tierBreakdown = {
    bronze: allUsers.filter(u => u.tier === 'bronze').length,
    silver: allUsers.filter(u => u.tier === 'silver').length,
    gold: allUsers.filter(u => u.tier === 'gold').length,
    diamond: allUsers.filter(u => u.tier === 'diamond').length,
  };

  // Áp dụng bộ lọc
  let filtered = [...allUsers];

  if (tier && tier !== 'all') {
    const targetTier = normalizeTier(tier);
    filtered = filtered.filter(u => u.tier === targetTier);
  }

  if (status && status !== 'all') {
    const s = status.toLowerCase();
    filtered = filtered.filter(u => u.status.toLowerCase() === s);
  }

  if (query && query.trim()) {
    const term = query.trim().toLowerCase();
    filtered = filtered.filter(u => {
      return u.displayName.toLowerCase().includes(term) ||
             u.email.toLowerCase().includes(term) ||
             u.phone.toLowerCase().includes(term) ||
             u.id.toLowerCase().includes(term);
    });
  }

  // Sắp xếp
  switch (sortBy) {
    case 'points_desc':
      filtered.sort((a, b) => b.points - a.points);
      break;
    case 'recent':
      filtered.sort((a, b) => {
        const tA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
        const tB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
        return tB - tA;
      });
      break;
    case 'name_asc':
      filtered.sort((a, b) => a.displayName.localeCompare(b.displayName, 'vi'));
      break;
    case 'spent_desc':
    default:
      filtered.sort((a, b) => b.lifetimeSpent - a.lifetimeSpent);
      break;
  }

  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const limitNum = Math.max(1, parseInt(limit, 10) || 50);
  const startIndex = (pageNum - 1) * limitNum;
  const paginatedData = filtered.slice(startIndex, startIndex + limitNum);

  return {
    success: true,
    stats: {
      totalCustomers,
      activeCustomers,
      suspendedCustomers,
      vipCustomers,
      averageSpend,
      tierBreakdown,
    },
    count: filtered.length,
    page: pageNum,
    totalPages: Math.ceil(filtered.length / limitNum) || 1,
    data: paginatedData,
  };
}

module.exports = {
  getCustomer360Profile,
  adjustLoyalty,
  moderateCustomer,
  updateSkinProfile,
  updateCustomerProfile,
  listCustomersWith360Metrics,
  calculateTierFromMetrics,
  normalizeTier,
  TIER_THRESHOLDS,
};

