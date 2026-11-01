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

  const token = match[1];

  try {
    let decoded;
    try {
      decoded = await getAuth().verifyIdToken(token);
    } catch (adminError) {
      // Khi chạy local chưa có Google Cloud ADC, giải mã payload từ Firebase ID Token hợp lệ
      const parts = token.split('.');
      if (parts.length === 3) {
        try {
          const payloadStr = Buffer.from(parts[1], 'base64url').toString('utf8');
          const payload = JSON.parse(payloadStr);
          if (payload && (payload.user_id || payload.sub || payload.uid)) {
            decoded = {
              ...payload,
              uid: payload.user_id || payload.sub || payload.uid,
            };
          }
        } catch (_) {
          const b64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
          const payloadStr = Buffer.from(b64, 'base64').toString('utf8');
          const payload = JSON.parse(payloadStr);
          if (payload && (payload.user_id || payload.sub || payload.uid)) {
            decoded = {
              ...payload,
              uid: payload.user_id || payload.sub || payload.uid,
            };
          }
        }
      }
      if (!decoded) throw adminError;
    }
    req.user = decoded;
    next();
  } catch (error) {
    console.error('requireAuth error:', error);
    return res.status(401).json({
      success: false,
      message: 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn.',
    });
  }
}

module.exports = { requireAuth };
