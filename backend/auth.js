const { getAuth } = require('firebase-admin/auth');

// Never decode an unverified JWT as an authentication fallback.
async function requireAuth(req, res, next) {
  const match = /^Bearer (\S+)$/i.exec(req.headers.authorization || '');
  if (!match) return res.status(401).json({ success: false, message: 'Vui lòng đăng nhập.' });
  try {
    const decoded = await getAuth().verifyIdToken(match[1], true);
    if (!decoded.uid) throw new Error('MISSING_UID');
    req.user = decoded;
    return next();
  } catch (_) {
    return res.status(401).json({ success: false, message: 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn.' });
  }
}
module.exports = { requireAuth };
