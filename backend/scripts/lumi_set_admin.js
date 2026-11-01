// Trusted local operation; never expose this script as an HTTP route.
require('dotenv').config();
require('../firebase');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

async function main() {
  const [action, email] = process.argv.slice(2);
  if (!['grant', 'revoke', 'check'].includes(action) || !email || !email.includes('@')) {
    throw new Error('Dùng: node scripts/lumi_set_admin.js grant|revoke|check email@domain.com');
  }
  const auth = getAuth();
  const user = await auth.getUserByEmail(email);
  if (user.disabled) throw new Error('Tài khoản đang bị khóa.');
  if (action === 'check') {
    console.log(`${user.email}: ${user.customClaims?.admin === true ? 'admin' : 'customer'}`);
    return;
  }
  const claims = { ...(user.customClaims || {}) };
  if (action === 'grant') claims.admin = true;
  else delete claims.admin;
  await auth.setCustomUserClaims(user.uid, claims);
  if (action === 'revoke') await auth.revokeRefreshTokens(user.uid);
  // Informational only. Backend and Rules trust the signed claim, never this field.
  await getFirestore().collection('users').doc(user.uid).set({
    role: action === 'grant' ? 'admin' : 'customer',
    roleUpdatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  console.log(`Đã ${action === 'grant' ? 'cấp' : 'thu hồi'} quyền admin cho ${user.email}. Đăng xuất rồi đăng nhập lại để cập nhật phiên.`);
}
main().then(() => process.exit(0)).catch(error => { console.error(error.message); process.exit(1); });
