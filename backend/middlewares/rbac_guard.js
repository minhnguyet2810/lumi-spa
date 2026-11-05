const { getAuth } = require('firebase-admin/auth');
const db = require('../firebase');

/**
 * Middleware: Xác thực Bearer Token từ Firebase Authentication
 * Bắt buộc kiểm tra token có bị thu hồi hay không (checkRevoked = true).
 */
async function authenticateToken(req, res, next) {
  const authHeader = req.headers.authorization || '';
  const match = /^Bearer (\S+)$/i.exec(authHeader);

  if (!match) {
    return res.status(401).json({
      success: false,
      message: 'Vui lòng đăng nhập với tài khoản hợp lệ.',
    });
  }

  try {
    const decodedToken = await getAuth().verifyIdToken(match[1], true);
    if (!decodedToken.uid) {
      throw new Error('MISSING_UID');
    }

    // Xác định role từ custom claims hoặc cờ admin hiện hữu
    let role = decodedToken.role;
    if (!role && decodedToken.admin === true) {
      role = 'super_admin';
    }

    // Nếu token chưa có role claim, tra cứu bổ sung từ collection `users`
    let assignedBranchId = decodedToken.assignedBranchId || null;
    if (!role && db.hasCredentials) {
      try {
        const uDoc = await db.collection('users').doc(decodedToken.uid).get();
        if (uDoc.exists) {
          const uData = uDoc.data();
          role = uData.role || (uData.isAdmin ? 'super_admin' : 'customer');
          assignedBranchId = uData.assignedBranchId || null;
        }
      } catch (_) {}
    }

    req.user = {
      ...decodedToken,
      role: role || 'customer',
      assignedBranchId,
    };

    return next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Phiên làm việc không hợp lệ hoặc đã hết hạn.',
      error: error.message,
    });
  }
}

/**
 * Middleware: Phân quyền theo vai trò (RBAC)
 * @param {Array<string>} allowedRoles Danh sách các role được cấp quyền
 */
function requireRoles(allowedRoles = []) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ success: false, message: 'Chưa xác thực danh tính.' });
    }

    const currentRole = req.user.role || 'customer';

    // Super Admin luôn có quyền truy cập toàn bộ tài nguyên
    if (currentRole === 'super_admin' || req.user.admin === true) {
      return next();
    }

    if (!allowedRoles.includes(currentRole)) {
      return res.status(403).json({
        success: false,
        message: `Tài khoản với vai trò '${currentRole}' không có quyền truy cập chức năng này.`,
      });
    }

    return next();
  };
}

/**
 * Middleware: Kiểm soát truy cập theo ngữ cảnh Chi nhánh (Branch Multi-Tenancy)
 * Super Admin: Truy cập xuyên chi nhánh
 * Branch Manager, Receptionist, Specialist: Bị giới hạn trong chi nhánh được phân công.
 */
function enforceBranchAccess(req, res, next) {
  if (!req.user) {
    return res.status(401).json({ success: false, message: 'Chưa xác thực danh tính.' });
  }

  const currentRole = req.user.role || 'customer';

  // Super Admin được quyền quản lý tất cả chi nhánh
  if (currentRole === 'super_admin' || req.user.admin === true) {
    req.branchContext = req.query.branchId || req.body.branchId || null;
    return next();
  }

  const assignedBranch = req.user.assignedBranchId;
  const requestedBranch = req.query.branchId || req.body.branchId || req.params.branchId;

  if (requestedBranch && requestedBranch !== 'all' && assignedBranch && requestedBranch !== assignedBranch) {
    return res.status(403).json({
      success: false,
      message: 'Bạn không có quyền thao tác trên tài nguyên của chi nhánh khác.',
    });
  }

  // Tự động gán branchContext của nhân sự
  req.branchContext = assignedBranch;
  return next();
}

module.exports = {
  authenticateToken,
  requireRoles,
  enforceBranchAccess,
};
