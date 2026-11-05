const { FieldValue, Timestamp } = require('firebase-admin/firestore');
const db = require('../firebase');

const SHIFT_TYPES = {
  morning: { label: 'Ca Sáng', timeRange: '08:30 - 14:30', startHour: 8.5, endHour: 14.5 },
  afternoon: { label: 'Ca Chiều', timeRange: '13:30 - 19:30', startHour: 13.5, endHour: 19.5 },
  full: { label: 'Cả Ngày', timeRange: '09:00 - 18:00', startHour: 9, endHour: 18 },
};

function serializeDate(val) {
  if (!val) return null;
  if (typeof val.toDate === 'function') return val.toDate().toISOString();
  if (val instanceof Date) return val.toISOString();
  if (typeof val === 'string') return val;
  return null;
}

/**
 * 1. Lấy danh sách nhân sự (Staff Members)
 */
async function listStaffMembers({ branchId, role, status }) {
  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  const staffSnap = await db.collection('staff').get();
  let staffList = staffSnap.docs.map(doc => {
    const d = doc.data();
    return {
      id: doc.id,
      staffId: doc.id,
      name: d.name || 'Nhân viên LUMI',
      role: d.role || 'specialist',
      phone: d.phone || '',
      email: d.email || '',
      branchId: d.branchId || 'central_hub',
      categories: Array.isArray(d.categories) ? d.categories : ['facial'],
      isActive: d.isActive !== false,
      status: d.status || (d.isActive !== false ? 'active' : 'inactive'),
      avatarUrl: d.avatarUrl || d.photoUrl || null,
      createdAt: serializeDate(d.createdAt),
    };
  });

  // Nếu trong collection staff còn ít hoặc trống, bổ sung từ users có role specialist/receptionist
  if (staffList.length < 5) {
    try {
      const userSnap = await db.collection('users')
        .where('role', 'in', ['specialist', 'receptionist', 'branch_manager'])
        .get();

      userSnap.docs.forEach(doc => {
        const u = doc.data();
        if (!staffList.some(s => s.id === doc.id || s.email === u.email)) {
          staffList.push({
            id: doc.id,
            staffId: doc.id,
            name: u.displayName || u.name || 'Nhân viên LUMI',
            role: u.role || 'specialist',
            phone: u.phone || '',
            email: u.email || '',
            branchId: u.assignedBranchId || 'central_hub',
            categories: ['facial', 'body'],
            isActive: u.status !== 'suspended',
            status: u.status === 'suspended' ? 'inactive' : 'active',
            avatarUrl: u.photoUrl || null,
            createdAt: serializeDate(u.createdAt),
          });
        }
      });
    } catch (_) {}
  }

  // Bộ lọc
  if (branchId && branchId !== 'all') {
    staffList = staffList.filter(s => s.branchId === branchId);
  }
  if (role && role !== 'all') {
    staffList = staffList.filter(s => s.role === role);
  }
  if (status && status !== 'all') {
    staffList = staffList.filter(s => s.status === status);
  }

  staffList.sort((a, b) => a.name.localeCompare(b.name, 'vi'));

  return {
    success: true,
    count: staffList.length,
    data: staffList,
  };
}

/**
 * 2. Thêm hoặc cập nhật hồ sơ nhân viên
 */
async function createOrUpdateStaffMember({ staffId, name, role = 'specialist', phone = '', email = '', branchId = 'central_hub', categories = ['facial'], isActive = true }) {
  if (!name || !name.trim()) {
    throw Object.assign(new Error('Tên nhân viên không được để trống.'), { statusCode: 400 });
  }

  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  const id = staffId || db.collection('staff').doc().id;
  const staffRef = db.collection('staff').doc(id);

  const payload = {
    name: name.trim(),
    role: ['specialist', 'receptionist', 'branch_manager'].includes(role) ? role : 'specialist',
    phone: phone.trim(),
    email: email.trim(),
    branchId: branchId || 'central_hub',
    categories: Array.isArray(categories) && categories.length > 0 ? categories : ['facial'],
    isActive: Boolean(isActive),
    status: isActive ? 'active' : 'inactive',
    updatedAt: FieldValue.serverTimestamp(),
  };

  const doc = await staffRef.get();
  if (!doc.exists) {
    payload.createdAt = FieldValue.serverTimestamp();
  }

  await staffRef.set(payload, { merge: true });

  return {
    success: true,
    message: doc.exists ? 'Đã cập nhật thông tin nhân viên.' : 'Đã thêm nhân viên mới thành công.',
    data: {
      id,
      staffId: id,
      ...payload,
      createdAt: new Date().toISOString(),
    },
  };
}

/**
 * 3. Bảng phân ca trực tuần / tháng (Staff Roster)
 */
async function getStaffRoster({ branchId, startDate, endDate, staffId }) {
  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  let query = db.collection('staff_shifts');

  if (branchId && branchId !== 'all') {
    query = query.where('branchId', '==', branchId);
  }

  if (staffId && staffId !== 'all') {
    query = query.where('staffId', '==', staffId);
  }

  const snap = await query.get();
  let shifts = snap.docs.map(doc => {
    const d = doc.data();
    return {
      id: doc.id,
      shiftId: doc.id,
      ...d,
      actualCheckIn: serializeDate(d.actualCheckIn),
      actualCheckOut: serializeDate(d.actualCheckOut),
      createdAt: serializeDate(d.createdAt),
      updatedAt: serializeDate(d.updatedAt),
    };
  });

  // Lọc theo khoảng ngày nếu có
  if (startDate) {
    shifts = shifts.filter(s => s.date >= startDate);
  }
  if (endDate) {
    shifts = shifts.filter(s => s.date <= endDate);
  }

  // Sắp xếp theo ngày tăng dần và loại ca
  shifts.sort((a, b) => {
    if (a.date !== b.date) return a.date.localeCompare(b.date);
    return (a.shiftType || '').localeCompare(b.shiftType || '');
  });

  return {
    success: true,
    count: shifts.length,
    data: shifts,
  };
}

/**
 * 4. Xếp ca làm việc mới (Tạo ca trực không trùng lặp)
 */
async function createStaffShift({ staffId, staffName, role = 'specialist', branchId = 'central_hub', date, shiftType = 'morning', notes = '', createdBy = 'admin' }) {
  if (!staffId || !date || !shiftType) {
    throw Object.assign(new Error('Vui lòng chọn nhân viên, ngày làm việc và loại ca trực.'), { statusCode: 400 });
  }

  if (!SHIFT_TYPES[shiftType]) {
    throw Object.assign(new Error(`Loại ca trực '${shiftType}' không hợp lệ (Chấp nhận: morning, afternoon, full).`), { statusCode: 400 });
  }

  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  // Kiểm tra xem nhân viên đã có ca trực trong ngày đó chưa
  const existingSnap = await db.collection('staff_shifts')
    .where('staffId', '==', staffId)
    .where('date', '==', date)
    .get();

  const conflicting = existingSnap.docs.find(d => {
    const data = d.data();
    return data.status !== 'leave_approved' && (data.shiftType === shiftType || data.shiftType === 'full' || shiftType === 'full');
  });

  if (conflicting) {
    throw Object.assign(new Error(`Nhân viên đã được xếp ca trực trong ngày ${date}. Không thể xếp trùng ca.`), { statusCode: 409 });
  }

  // Lấy tên nhân viên nếu chưa truyền
  let finalStaffName = staffName;
  if (!finalStaffName) {
    try {
      const sDoc = await db.collection('staff').doc(staffId).get();
      if (sDoc.exists) finalStaffName = sDoc.data().name;
    } catch (_) {}
  }

  const shiftRef = db.collection('staff_shifts').doc();
  const shiftPayload = {
    shiftId: shiftRef.id,
    staffId,
    staffName: finalStaffName || 'Nhân viên LUMI',
    role,
    branchId,
    date,
    shiftType,
    shiftTypeLabel: SHIFT_TYPES[shiftType].label,
    timeRange: SHIFT_TYPES[shiftType].timeRange,
    status: 'scheduled',
    notes: notes.trim(),
    actualCheckIn: null,
    actualCheckOut: null,
    leaveReason: null,
    createdBy,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };

  await shiftRef.set(shiftPayload);

  return {
    success: true,
    message: `Đã xếp ca trực ${SHIFT_TYPES[shiftType].label} ngày ${date} cho ${finalStaffName} thành công.`,
    data: {
      id: shiftRef.id,
      ...shiftPayload,
      createdAt: new Date().toISOString(),
    },
  };
}

/**
 * 5. Cập nhật / Đổi ca trực
 */
async function updateStaffShift({ shiftId, shiftType, date, notes, updatedBy = 'admin' }) {
  if (!shiftId) {
    throw Object.assign(new Error('Mã ca trực không được để trống.'), { statusCode: 400 });
  }

  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  const shiftRef = db.collection('staff_shifts').doc(shiftId);
  const snap = await shiftRef.get();
  if (!snap.exists) {
    throw Object.assign(new Error('Ca trực không tồn tại.'), { statusCode: 404 });
  }

  const updates = {
    updatedBy,
    updatedAt: FieldValue.serverTimestamp(),
  };

  if (shiftType && SHIFT_TYPES[shiftType]) {
    updates.shiftType = shiftType;
    updates.shiftTypeLabel = SHIFT_TYPES[shiftType].label;
    updates.timeRange = SHIFT_TYPES[shiftType].timeRange;
  }
  if (date) updates.date = date;
  if (notes !== undefined) updates.notes = notes.trim();

  await shiftRef.update(updates);

  return {
    success: true,
    message: 'Đã cập nhật ca trực thành công.',
    data: { shiftId, ...updates },
  };
}

/**
 * 6. Hủy ca trực
 */
async function deleteStaffShift({ shiftId }) {
  if (!shiftId) {
    throw Object.assign(new Error('Mã ca trực không được để trống.'), { statusCode: 400 });
  }

  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  const shiftRef = db.collection('staff_shifts').doc(shiftId);
  const snap = await shiftRef.get();
  if (!snap.exists) {
    throw Object.assign(new Error('Ca trực không tồn tại.'), { statusCode: 404 });
  }

  await shiftRef.delete();

  return {
    success: true,
    message: 'Đã xóa ca trực khỏi lịch làm việc.',
    data: { shiftId },
  };
}

/**
 * 7. Chấm công Vào ca (Check-in)
 */
async function checkInShift({ shiftId, staffId }) {
  if (!shiftId) {
    throw Object.assign(new Error('Mã ca trực không được để trống.'), { statusCode: 400 });
  }

  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  const shiftRef = db.collection('staff_shifts').doc(shiftId);
  const snap = await shiftRef.get();
  if (!snap.exists) {
    throw Object.assign(new Error('Ca trực không tồn tại.'), { statusCode: 404 });
  }

  const data = snap.data();
  if (data.status === 'checked_in') {
    throw Object.assign(new Error('Ca trực này đã được chấm công vào trước đó.'), { statusCode: 400 });
  }
  if (data.status === 'completed') {
    throw Object.assign(new Error('Ca trực này đã kết thúc.'), { statusCode: 400 });
  }

  const now = FieldValue.serverTimestamp();
  await shiftRef.update({
    status: 'checked_in',
    actualCheckIn: now,
    updatedAt: now,
  });

  return {
    success: true,
    message: `Đã chấm công vào ca thành công cho ${data.staffName}.`,
    data: {
      shiftId,
      status: 'checked_in',
      checkInTime: new Date().toISOString(),
    },
  };
}

/**
 * 8. Chấm công Kết ca (Check-out)
 */
async function checkOutShift({ shiftId, staffId }) {
  if (!shiftId) {
    throw Object.assign(new Error('Mã ca trực không được để trống.'), { statusCode: 400 });
  }

  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  const shiftRef = db.collection('staff_shifts').doc(shiftId);
  const snap = await shiftRef.get();
  if (!snap.exists) {
    throw Object.assign(new Error('Ca trực không tồn tại.'), { statusCode: 404 });
  }

  const data = snap.data();
  if (data.status === 'completed') {
    throw Object.assign(new Error('Ca trực này đã được hoàn tất trước đó.'), { statusCode: 400 });
  }

  const now = FieldValue.serverTimestamp();
  await shiftRef.update({
    status: 'completed',
    actualCheckOut: now,
    updatedAt: now,
  });

  return {
    success: true,
    message: `Đã hoàn tất ca trực cho ${data.staffName}.`,
    data: {
      shiftId,
      status: 'completed',
      checkOutTime: new Date().toISOString(),
    },
  };
}

/**
 * 9. Đăng ký xin nghỉ phép ca trực (Leave Request)
 */
async function requestShiftLeave({ shiftId, reason = '', staffId }) {
  if (!shiftId) {
    throw Object.assign(new Error('Mã ca trực không được để trống.'), { statusCode: 400 });
  }

  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  const shiftRef = db.collection('staff_shifts').doc(shiftId);
  const snap = await shiftRef.get();
  if (!snap.exists) {
    throw Object.assign(new Error('Ca trực không tồn tại.'), { statusCode: 404 });
  }

  const now = FieldValue.serverTimestamp();
  await shiftRef.update({
    status: 'leave_requested',
    leaveReason: reason.trim() || 'Lý do cá nhân',
    leaveRequestedAt: now,
    updatedAt: now,
  });

  return {
    success: true,
    message: 'Đã gửi yêu cầu xin nghỉ phép đến quản lý.',
    data: {
      shiftId,
      status: 'leave_requested',
      reason: reason.trim(),
    },
  };
}

/**
 * 10. Quản lý duyệt / từ chối đơn xin nghỉ phép (Leave Approval)
 */
async function approveShiftLeave({ shiftId, approved = true, note = '', reviewedBy = 'manager' }) {
  if (!shiftId) {
    throw Object.assign(new Error('Mã ca trực không được để trống.'), { statusCode: 400 });
  }

  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  const shiftRef = db.collection('staff_shifts').doc(shiftId);
  const snap = await shiftRef.get();
  if (!snap.exists) {
    throw Object.assign(new Error('Ca trực không tồn tại.'), { statusCode: 404 });
  }

  const newStatus = approved ? 'leave_approved' : 'scheduled';
  const now = FieldValue.serverTimestamp();

  await shiftRef.update({
    status: newStatus,
    leaveApprovedNote: note.trim(),
    leaveReviewedBy: reviewedBy,
    leaveReviewedAt: now,
    updatedAt: now,
  });

  return {
    success: true,
    message: approved ? 'Đã phê duyệt đơn xin nghỉ phép thành công.' : 'Đã từ chối đơn xin nghỉ phép, chuyển lại ca trực.',
    data: {
      shiftId,
      status: newStatus,
    },
  };
}

/**
 * 11. Thống kê KPI Quản trị Nhân sự & Ca kíp (HRM KPI Metrics)
 */
async function getHrmKpiMetrics({ branchId, date }) {
  if (!db.hasCredentials) {
    throw Object.assign(new Error('Chưa kết nối cơ sở dữ liệu.'), { statusCode: 503 });
  }

  const targetDate = date || new Date().toISOString().substring(0, 10);

  // 1. Tổng số nhân sự
  const staffSnap = await db.collection('staff').get();
  const totalStaff = staffSnap.size;

  // 2. Ca trực hôm nay
  let query = db.collection('staff_shifts').where('date', '==', targetDate);
  if (branchId && branchId !== 'all') {
    query = query.where('branchId', '==', branchId);
  }
  const todaySnap = await query.get();
  const todayShifts = todaySnap.docs.map(d => d.data());

  const onDutyToday = todayShifts.filter(s => ['scheduled', 'checked_in'].includes(s.status)).length;
  const completedToday = todayShifts.filter(s => s.status === 'completed').length;
  const onLeaveToday = todayShifts.filter(s => ['leave_approved', 'leave_requested'].includes(s.status)).length;

  // 3. Đơn xin nghỉ phép đang chờ duyệt toàn hệ thống
  const pendingLeavesSnap = await db.collection('staff_shifts')
    .where('status', '==', 'leave_requested')
    .get();
  const pendingLeaveCount = pendingLeavesSnap.size;

  return {
    success: true,
    data: {
      totalStaff,
      onDutyToday,
      completedToday,
      onLeaveToday,
      pendingLeaveCount,
      targetDate,
    },
  };
}

module.exports = {
  SHIFT_TYPES,
  listStaffMembers,
  createOrUpdateStaffMember,
  getStaffRoster,
  createStaffShift,
  updateStaffShift,
  deleteStaffShift,
  checkInShift,
  checkOutShift,
  requestShiftLeave,
  approveShiftLeave,
  getHrmKpiMetrics,
};
