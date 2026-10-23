const { getAuth } = require('firebase-admin/auth');

async function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const match = /^Bearer (.+)$/i.exec(header);

  if (!match) {
    return res.status(401).json({
      success: false,
      message: 'Vui lòng đăng nhập.',
    });
  }

  try {
    const decoded = await getAuth().verifyIdToken(match[1], true);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn.',
    });
  }
}

module.exports = { requireAuth };
