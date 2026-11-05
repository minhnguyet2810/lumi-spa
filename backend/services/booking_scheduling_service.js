const { FieldValue, Timestamp } = require('firebase-admin/firestore');
const db = require('../firebase');
const pushService = require('./push_service');
const mailService = require('./mail_service');
const { awardPointsInTransaction, sendPointsNotification } = require('./membership_service');

const SLOT_INTERVAL_MINUTES = 15;
const SLOT_MS = SLOT_INTERVAL_MINUTES * 60 * 1000;

/**
 * Sinh danh sách các slot ID 15 phút để khóa tài nguyên Kỹ thuật viên & Phòng
 */
function generateSlotKeys(resourceType, resourceId, startTime, durationMinutes) {
  const keys = [];
  const startMs = startTime.getTime();
  const endMs = startMs + durationMinutes * 60 * 1000;

  for (let t = startMs; t < endMs; t += SLOT_MS) {
    keys.push(`${resourceType}_${resourceId}_${new Date(t).toISOString()}`);
  }
  return keys;
}

/**
 * 1. Lấy dữ liệu ma trận lịch hẹn (Timeline & Calendar Matrix)
 */
async function getTimelineMatrix({ branchId = 'central_hub', date, roomId, technicianId }) {
  if (!db.hasCredentials) {
    return { success: true, date, branchId, timeline: [], stats: { total: 0, occupancyRate: 0 } };
  }

  const queryDate = date || new Date().toISOString().split('T')[0];
  const [year, month, day] = queryDate.split('-').map(Number);
  const startOfDay = new Date(Date.UTC(year, month - 1, day, -7));
  const endOfDay = new Date(startOfDay.getTime() + 24 * 60 * 60 * 1000 - 1);

  // Truy vấn lịch hẹn trong ngày
  let apptQuery = db.collection('bookings')
    .where('startAt', '>=', Timestamp.fromDate(startOfDay))
    .where('startAt', '<=', Timestamp.fromDate(endOfDay));

  if (branchId && branchId !== 'all') {
    // Nếu có trường branchId thì lọc, nếu không bỏ qua
  }

  const [apptSnap, staffSnap, roomSnap] = await Promise.all([
    apptQuery.get(),
    db.collection('staff').get(),
    db.collection('rooms').get(),
  ]);

  const appointments = apptSnap.docs.map(d => {
    const data = d.data();
    return {
      id: d.id,
      ...data,
      startAt: data.startAt?.toDate ? data.startAt.toDate().toISOString() : data.startAt,
      endAt: data.endAt?.toDate ? data.endAt.toDate().toISOString() : null,
      createdAt: data.createdAt?.toDate ? data.createdAt.toDate().toISOString() : null,
    };
  });

  const staffList = staffSnap.docs.map(d => ({ id: d.id, ...d.data() }));
  const roomList = roomSnap.docs.map(d => ({ id: d.id, ...d.data() }));

  // Tính toán tỷ lệ lấp đầy công suất (Occupancy Rate)
  const totalBookedMinutes = appointments
    .filter(a => ['confirmed', 'approved', 'checked_in', 'in_progress', 'completed'].includes(a.status))
    .reduce((sum, a) => sum + (Number(a.durationMinutes) || 60), 0);

  // Spa mở từ 09:00 - 18:00 (540 phút/ngày) x số phòng
  const totalCapacityMinutes = Math.max(1, roomList.length) * 540;
  const occupancyRate = Math.min(100, Math.round((totalBookedMinutes / totalCapacityMinutes) * 100));

  return {
    success: true,
    date: queryDate,
    branchId,
    stats: {
      totalAppointments: appointments.length,
      pendingCount: appointments.filter(a => a.status === 'pending').length,
      confirmedCount: appointments.filter(a => ['confirmed', 'approved'].includes(a.status)).length,
      checkedInCount: appointments.filter(a => a.status === 'checked_in').length,
      inProgressCount: appointments.filter(a => a.status === 'in_progress').length,
      completedCount: appointments.filter(a => a.status === 'completed').length,
      occupancyRate,
    },
    staff: staffList,
    rooms: roomList,
    appointments,
  };
}

/**
 * 2. Duyệt lịch hẹn và khóa slot Kỹ thuật viên & Phòng trị liệu (ACID Transaction)
 */
async function confirmBookingAndReserveTechnician({
  appointmentId,
  technicianId,
  roomId,
  staffId,
  branchId = 'central_hub',
  note = '',
}) {
  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  const apptRef = db.collection('bookings').doc(appointmentId);
  let apptData = null;
  let allRequiredSlots = [];

  await db.runTransaction(async (tx) => {
    const apptSnap = await tx.get(apptRef);
    if (!apptSnap.exists) {
      throw Object.assign(new Error(`Lịch hẹn '${appointmentId}' không tồn tại.`), { statusCode: 404 });
    }

    apptData = apptSnap.data();
    if (apptData.status !== 'pending') {
      throw Object.assign(
        new Error(`Không thể duyệt lịch hẹn đang ở trạng thái '${apptData.status}'.`),
        { statusCode: 409 }
      );
    }

    const startAt = apptData.startAt?.toDate ? apptData.startAt.toDate() : new Date(apptData.startAt);
    const durationMinutes = Number(apptData.durationMinutes) || 60;

    if (startAt.getTime() <= Date.now()) {
      throw Object.assign(new Error('Không thể duyệt lịch hẹn đã quá giờ bắt đầu.'), { statusCode: 400 });
    }

    // 1. Tạo danh sách các slot 15 phút cần khóa cho chuyên viên và phòng
    const techSlots = generateSlotKeys('tech', technicianId, startAt, durationMinutes);
    const roomSlots = generateSlotKeys('room', roomId, startAt, durationMinutes);
    allRequiredSlots = [...techSlots, ...roomSlots];

    // 2. Đọc toàn bộ các slot tài nguyên trong transaction để kiểm tra xung đột
    const slotRefs = allRequiredSlots.map(id => db.collection('resource_slots').doc(id));
    const slotSnaps = await tx.getAll(...slotRefs);

    const conflicts = [];
    slotSnaps.forEach((snap, idx) => {
      if (snap.exists && snap.data().appointmentId !== appointmentId) {
        conflicts.push(allRequiredSlots[idx]);
      }
    });

    if (conflicts.length > 0) {
      throw Object.assign(
        new Error('Kỹ thuật viên hoặc Phòng trị liệu đã có lịch trong khung giờ này. Vui lòng chọn KTV hoặc phòng khác.'),
        { statusCode: 409, conflicts }
      );
    }

    // 3. Khóa tài nguyên trong `resource_slots`
    const slotPayload = {
      appointmentId,
      technicianId,
      roomId,
      branchId: branchId || apptData.branchId || 'central_hub',
      createdAt: FieldValue.serverTimestamp(),
    };

    allRequiredSlots.forEach((slotId) => {
      tx.set(db.collection('resource_slots').doc(slotId), slotPayload);
    });

    // 4. Cập nhật trạng thái lịch hẹn
    const auditEntry = {
      fromStatus: 'pending',
      toStatus: 'confirmed',
      technicianId,
      roomId,
      changedBy: staffId,
      note: note || 'Duyệt lịch và khóa KTV/phòng thành công.',
      timestamp: new Date().toISOString(),
    };

    tx.update(apptRef, {
      status: 'confirmed',
      technicianId,
      staffId: technicianId,
      roomId,
      resourceSlotIds: allRequiredSlots,
      confirmedAt: FieldValue.serverTimestamp(),
      confirmedBy: staffId,
      statusHistory: FieldValue.arrayUnion(auditEntry),
      updatedAt: FieldValue.serverTimestamp(),
    });

    // 5. Khởi tạo sẵn bản ghi bệnh án da rỗng trong `users/{uid}/treatment_records`
    if (apptData.userId) {
      const recordRef = db.collection('users').doc(apptData.userId).collection('treatment_records').doc();
      tx.set(recordRef, {
        recordId: recordRef.id,
        appointmentId,
        serviceId: apptData.serviceId,
        serviceName: apptData.serviceName || 'Dịch vụ Spa',
        technicianId,
        roomId,
        branchId: branchId || apptData.branchId || 'central_hub',
        scheduledAt: Timestamp.fromDate(startAt),
        status: 'awaiting_session',
        skinConditionBefore: '',
        treatmentStepsApplied: [],
        productsUsed: [],
        skinReactionAfter: '',
        homecareRecommendations: '',
        createdAt: FieldValue.serverTimestamp(),
      });
    }
  });

  // Gửi thông báo & email sau transaction
  try {
    if (apptData?.userId) {
      await pushService.sendBookingConfirmedPush({
        userId: apptData.userId,
        bookingId: appointmentId,
        serviceName: apptData.serviceName || 'Liệu trình Spa',
        date: apptData.startAt?.toDate ? apptData.startAt.toDate().toISOString().split('T')[0] : '',
        hour: apptData.startAt?.toDate ? apptData.startAt.toDate().getHours() : 9,
      });

      await db.collection('notifications').add({
        userId: apptData.userId,
        title: 'Lịch hẹn đã được xác nhận ✨',
        message: `Lịch hẹn "${apptData.serviceName || 'Dịch vụ Spa'}" đã được Lễ tân xác nhận. Hân hạnh đón tiếp quý khách!`,
        type: 'appointment',
        isRead: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    }
  } catch (err) {
    console.warn('[BookingScheduling] Lỗi thông báo duyệt lịch:', err.message);
  }

  return {
    success: true,
    appointmentId,
    technicianId,
    roomId,
    slotsReserved: allRequiredSlots.length,
    message: 'Duyệt lịch hẹn và phân công Kỹ thuật viên thành công!',
  };
}

/**
 * 3. Tiếp nhận khách tại chỗ (Check-in)
 */
async function checkInBooking({ appointmentId, staffId, note = '' }) {
  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  const apptRef = db.collection('bookings').doc(appointmentId);
  const snap = await apptRef.get();
  if (!snap.exists) {
    throw Object.assign(new Error('Không tìm thấy lịch hẹn.'), { statusCode: 404 });
  }

  const currentStatus = snap.data().status;
  if (!['confirmed', 'approved', 'pending'].includes(currentStatus)) {
    throw Object.assign(new Error(`Không thể check-in lịch đang ở trạng thái '${currentStatus}'.`), { statusCode: 409 });
  }

  const auditEntry = {
    fromStatus: currentStatus,
    toStatus: 'checked_in',
    changedBy: staffId,
    note: note || 'Khách hàng đã có mặt tại sảnh lễ tân.',
    timestamp: new Date().toISOString(),
  };

  await apptRef.update({
    status: 'checked_in',
    checkInAt: FieldValue.serverTimestamp(),
    checkedInBy: staffId,
    statusHistory: FieldValue.arrayUnion(auditEntry),
    updatedAt: FieldValue.serverTimestamp(),
  });

  return {
    success: true,
    appointmentId,
    status: 'checked_in',
    message: 'Khách hàng đã check-in thành công tại quầy lễ tân!',
  };
}

/**
 * 4. Bắt đầu phiên trị liệu (In-Progress) & Cập nhật Hồ sơ Liệu trình (Clinical Notes)
 */
async function updateTreatmentRecord({
  appointmentId,
  userId,
  technicianId,
  skinConditionBefore,
  treatmentStepsApplied = [],
  productsUsed = [],
  skinReactionAfter = '',
  homecareRecommendations = '',
}) {
  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  const apptRef = db.collection('bookings').doc(appointmentId);
  await apptRef.update({
    status: 'in_progress',
    updatedAt: FieldValue.serverTimestamp(),
  });

  if (userId) {
    const recordsSnap = await db.collection('users')
      .doc(userId)
      .collection('treatment_records')
      .where('appointmentId', '==', appointmentId)
      .limit(1)
      .get();

    if (!recordsSnap.empty) {
      await recordsSnap.docs[0].ref.update({
        status: 'in_progress',
        skinConditionBefore: skinConditionBefore || '',
        treatmentStepsApplied: Array.isArray(treatmentStepsApplied) ? treatmentStepsApplied : [],
        productsUsed: Array.isArray(productsUsed) ? productsUsed : [],
        skinReactionAfter: skinReactionAfter || '',
        homecareRecommendations: homecareRecommendations || '',
        technicianId,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  }

  return {
    success: true,
    appointmentId,
    message: 'Cập nhật ghi chú liệu trình và bệnh án da thành công!',
  };
}

/**
 * 5. Hoàn tất dịch vụ, tính hoa hồng cho Kỹ thuật viên & Tích điểm thành viên (Complete)
 */
async function completeBookingAndCalculateCommission({
  appointmentId,
  staffId,
  tips = 0,
  paymentMethod = 'counter_cash',
}) {
  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  const apptRef = db.collection('bookings').doc(appointmentId);
  let apptData = null;
  let pointsResult = null;
  let commissionData = null;

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(apptRef);
    if (!snap.exists) {
      throw Object.assign(new Error('Không tìm thấy lịch hẹn.'), { statusCode: 404 });
    }

    apptData = snap.data();
    const currentStatus = apptData.status;

    if (!['confirmed', 'approved', 'checked_in', 'in_progress'].includes(currentStatus)) {
      throw Object.assign(new Error(`Không thể hoàn tất lịch đang ở trạng thái '${currentStatus}'.`), { statusCode: 409 });
    }

    const price = Number(apptData.price) || 0;
    const technicianId = apptData.technicianId || apptData.staffId || staffId;

    // 1. Tích điểm cho khách hàng
    if (apptData.userId && apptData.pointsAwarded !== true && price > 0) {
      pointsResult = await awardPointsInTransaction(tx, db, {
        userId: apptData.userId,
        amount: price,
        sourceId: appointmentId,
        sourceType: 'booking',
      });
    }

    // 2. Tính hoa hồng KTV (10% giá trị liệu trình + 100% tiền tips)
    const commissionPercent = 10;
    const baseCommission = Math.round((price * commissionPercent) / 100);
    const totalCommission = baseCommission + (Number(tips) || 0);

    const commRef = db.collection('commissions').doc();
    commissionData = {
      commissionId: commRef.id,
      staffId: technicianId,
      branchId: apptData.branchId || 'central_hub',
      type: 'treatment_service',
      sourceId: appointmentId,
      serviceName: apptData.serviceName || 'Dịch vụ Spa',
      servicePrice: price,
      commissionPercent,
      baseCommission,
      tips: Number(tips) || 0,
      totalCommission,
      status: 'approved',
      period: new Date().toISOString().substring(0, 7), // YYYY-MM
      createdAt: FieldValue.serverTimestamp(),
    };
    tx.set(commRef, commissionData);

    // 3. Giải phóng các khóa tài nguyên trong `resource_slots`
    if (Array.isArray(apptData.resourceSlotIds) && apptData.resourceSlotIds.length > 0) {
      const slotRefs = apptData.resourceSlotIds.map(id => db.collection('resource_slots').doc(id));
      const slots = await tx.getAll(...slotRefs);
      slots.forEach((s, idx) => {
        if (s.exists && s.data().appointmentId === appointmentId) {
          tx.delete(slotRefs[idx]);
        }
      });
    }

    // 4. Cập nhật trạng thái hoàn tất
    const auditEntry = {
      fromStatus: currentStatus,
      toStatus: 'completed',
      changedBy: staffId,
      commissionEarned: totalCommission,
      timestamp: new Date().toISOString(),
    };

    tx.update(apptRef, {
      status: 'completed',
      completedAt: FieldValue.serverTimestamp(),
      completedBy: staffId,
      pointsAwarded: true,
      earnedPoints: pointsResult?.pointsAwarded ?? 0,
      commissionCalculated: true,
      commissionAmount: totalCommission,
      resourceSlotIds: [],
      statusHistory: FieldValue.arrayUnion(auditEntry),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  // Bắn thông báo hoàn tất & tích điểm
  try {
    if (apptData?.userId) {
      await db.collection('notifications').add({
        userId: apptData.userId,
        title: 'Liệu trình hoàn tất ✨',
        message: `Lịch hẹn "${apptData.serviceName || 'Dịch vụ Spa'}" đã hoàn tất. Cảm ơn quý khách đã trải nghiệm dịch vụ tại LUMI SPA!`,
        type: 'appointment',
        isRead: false,
        createdAt: FieldValue.serverTimestamp(),
      });

      if (pointsResult && pointsResult.pointsAwarded > 0) {
        await sendPointsNotification(db, {
          userId: apptData.userId,
          pointsAwarded: pointsResult.pointsAwarded,
          newPoints: pointsResult.newPoints,
          newTier: pointsResult.newTier,
          newTierLabel: pointsResult.newTierLabel,
          upgraded: pointsResult.upgraded,
          sourceId: appointmentId,
          sourceType: 'booking',
        });
      }
    }
  } catch (err) {
    console.warn('[BookingScheduling] Lỗi thông báo hoàn tất:', err.message);
  }

  return {
    success: true,
    appointmentId,
    status: 'completed',
    pointsAwarded: pointsResult?.pointsAwarded ?? 0,
    commission: commissionData,
    message: 'Hoàn tất liệu trình, giải phóng phòng và tính hoa hồng thành công!',
  };
}

/**
 * 6. Từ chối hoặc Hủy lịch hẹn và giải phóng tài nguyên
 */
async function cancelBookingAndReleaseResources({ appointmentId, staffId, reason = '' }) {
  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  const apptRef = db.collection('bookings').doc(appointmentId);
  let apptData = null;

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(apptRef);
    if (!snap.exists) {
      throw Object.assign(new Error('Không tìm thấy lịch hẹn.'), { statusCode: 404 });
    }

    apptData = snap.data();
    if (['completed', 'cancelled'].includes(apptData.status)) {
      throw Object.assign(new Error(`Lịch hẹn đã '${apptData.status}', không thể hủy.`), { statusCode: 409 });
    }

    // Giải phóng tài nguyên
    if (Array.isArray(apptData.resourceSlotIds) && apptData.resourceSlotIds.length > 0) {
      const slotRefs = apptData.resourceSlotIds.map(id => db.collection('resource_slots').doc(id));
      const slots = await tx.getAll(...slotRefs);
      slots.forEach((s, idx) => {
        if (s.exists && s.data().appointmentId === appointmentId) {
          tx.delete(slotRefs[idx]);
        }
      });
    }

    const auditEntry = {
      fromStatus: apptData.status,
      toStatus: 'cancelled',
      changedBy: staffId,
      reason: reason || 'Hủy từ ban quản lý',
      timestamp: new Date().toISOString(),
    };

    tx.update(apptRef, {
      status: 'cancelled',
      cancellationReason: reason || 'Hủy từ hệ thống',
      cancelledAt: FieldValue.serverTimestamp(),
      cancelledBy: staffId,
      resourceSlotIds: [],
      statusHistory: FieldValue.arrayUnion(auditEntry),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return {
    success: true,
    appointmentId,
    status: 'cancelled',
    message: 'Đã hủy lịch hẹn và giải phóng tài nguyên phòng/KTV thành công.',
  };
}

module.exports = {
  getTimelineMatrix,
  confirmBookingAndReserveTechnician,
  checkInBooking,
  updateTreatmentRecord,
  completeBookingAndCalculateCommission,
  cancelBookingAndReleaseResources,
};

