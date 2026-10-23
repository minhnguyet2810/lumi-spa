const { requireAuth } = require('./auth');

function requireAdmin(req, res, next) {
  if (req.user?.admin !== true) {
    return res.status(403).json({
      success: false,
      message: 'Bạn không có quyền quản trị.',
    });
  }

  next();
}

module.exports = { requireAuth, requireAdmin };
