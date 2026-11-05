const express = require('express');
const db = require('../firebase');
const { requireAuth } = require('../auth');
const { requireAdmin } = require('../admin_auth');
const { FieldValue } = require('firebase-admin/firestore');
const { key, millis, reviewKey, reviewTarget } = require('../services/experience_service');
const router = express.Router();
router.use(requireAuth);
router.use((req, res, next) => db.hasCredentials ? next() : res.status(503).json({ success: false, message: 'Chưa kết nối được dữ liệu LUMI.' }));
const validId = value => typeof value === 'string' && /^[A-Za-z0-9_-]{1,128}$/.test(value);
const validType = value => ['service', 'product'].includes(value);
const catalog = type => type === 'service' ? 'services' : 'products';
const favorites = uid => db.collection('experience_favorites').doc(uid).collection('items');
const send = (res, data) => res.json({ success: true, data });
const wrap = fn => async (req, res) => { try { await fn(req, res); } catch (error) {
  console.warn('Experience API:', error.message);
  res.status(error.status || 503).json({ success: false, message: error.status ? error.message : 'Chưa thực hiện được yêu cầu. Vui lòng thử lại.' });
} };
function fail(status, message) { throw Object.assign(new Error(message), { status }); }
router.get('/preferences', wrap(async (req, res) => {
  const doc = await db.collection('experience_preferences').doc(req.user.uid).get();
  send(res, { remindersEnabled: doc.exists && doc.data().remindersEnabled === true });
}));
router.put('/preferences', wrap(async (req, res) => {
  if (typeof req.body?.remindersEnabled !== 'boolean') fail(400, 'Lựa chọn không hợp lệ.');
  await db.collection('experience_preferences').doc(req.user.uid).set({ remindersEnabled: req.body.remindersEnabled, updatedAt: FieldValue.serverTimestamp() });
  send(res, { remindersEnabled: req.body.remindersEnabled });
}));
router.get('/favorites', wrap(async (req, res) => {
  const snap = await favorites(req.user.uid).get();
  const rows = await Promise.all(snap.docs.map(async doc => {
    const f = doc.data();
    const target = await db.collection(catalog(f.type)).doc(f.targetId).get();
    return { type: f.type, targetId: f.targetId, available: target.exists && target.data().isActive !== false,
      item: target.exists ? { ...target.data(), id: target.id } : null };
  }));
  send(res, rows);
}));
router.put('/favorites/:type/:id', wrap(async (req, res) => {
  const { type, id } = req.params;
  if (!validType(type) || !validId(id)) fail(400, 'Mục yêu thích không hợp lệ.');
  const target = await db.collection(catalog(type)).doc(id).get();
  if (!target.exists || target.data().isActive === false) fail(404, 'Mục này không còn khả dụng.');
  const ref = favorites(req.user.uid).doc(key(type, id));
  await db.runTransaction(async tx => {
    const existing = await tx.get(ref);
    const saved = await tx.get(favorites(req.user.uid));
    if (!existing.exists && saved.size >= 200) fail(409, 'Bạn đã lưu tối đa 200 mục.');
    tx.set(ref, { type, targetId: id, createdAt: FieldValue.serverTimestamp() });
  });
  send(res, { saved: true });
}));
router.delete('/favorites/:type/:id', wrap(async (req, res) => {
  if (!validType(req.params.type) || !validId(req.params.id)) fail(400, 'Mục không hợp lệ.');
  await favorites(req.user.uid).doc(key(req.params.type, req.params.id)).delete();
  send(res, { saved: false });
}));
router.get('/rebook/:id', wrap(async (req, res) => {
  if (!validId(req.params.id)) fail(400, 'Lịch hẹn không hợp lệ.');
  const doc = await db.collection('bookings').doc(req.params.id).get();
  if (!doc.exists || doc.data().userId !== req.user.uid) fail(404, 'Không tìm thấy lịch hẹn.');
  const target = await db.collection('services').doc(doc.data().serviceId).get();
  if (!target.exists || target.data().isActive === false) fail(409, 'Dịch vụ không còn khả dụng.');
  send(res, { ...target.data(), id: target.id });
}));
router.get('/history', wrap(async (req, res) => {
  const [bookings, orders, reviews] = await Promise.all([
    db.collection('bookings').where('userId', '==', req.user.uid).get(),
    db.collection('orders').where('userId', '==', req.user.uid).get(),
    db.collection('experience_reviews').where('userId', '==', req.user.uid).get(),
  ]);
  const reviewed = new Set(reviews.docs.map(doc => doc.id));
  const rows = [];
  for (const doc of bookings.docs) {
    const b = doc.data();
    rows.push({ sourceType: 'booking', sourceId: doc.id, type: 'service', targetId: b.serviceId,
      name: b.serviceName || 'Liệu trình LUMI', status: b.status,
      at: Number.isFinite(millis(b.startAt)) ? new Date(millis(b.startAt)).toISOString() : null,
      canReview: b.status === 'completed' && !reviewed.has(reviewKey(req.user.uid, 'booking', doc.id, b.serviceId)) });
  }
  for (const doc of orders.docs) {
    const o = doc.data();
    if (o.status !== 'completed') continue;
    for (const item of o.items || []) {
      if (!validId(item.productId)) continue;
      if (rows.some(row => row.sourceType === 'order' && row.sourceId === doc.id && row.targetId === item.productId)) continue;
      rows.push({ sourceType: 'order', sourceId: doc.id, type: 'product', targetId: item.productId,
        name: item.name || item.productName || 'Sản phẩm LUMI', status: o.status,
        at: Number.isFinite(millis(o.createdAt)) ? new Date(millis(o.createdAt)).toISOString() : null,
        canReview: !reviewed.has(reviewKey(req.user.uid, 'order', doc.id, item.productId)) });
    }
  }
  rows.sort((a,b) => (b.at || '').localeCompare(a.at || ''));
  send(res, rows);
}));
router.post('/reviews', wrap(async (req, res) => {
  const { sourceType, sourceId, targetId, rating, comment } = req.body || {};
  if (!['booking', 'order'].includes(sourceType) || !validId(sourceId) || !validId(targetId) ||
      !Number.isInteger(rating) || rating < 1 || rating > 5 || typeof comment !== 'string' || comment.trim().length > 1000) fail(400, 'Đánh giá cần từ 1–5 sao và tối đa 1.000 ký tự.');
  const reviewRef = db.collection('experience_reviews').doc(reviewKey(req.user.uid, sourceType, sourceId, targetId));
  await db.runTransaction(async tx => {
    const source = await tx.get(db.collection(sourceType === 'booking' ? 'bookings' : 'orders').doc(sourceId));
    const previous = await tx.get(reviewRef);
    if (!source.exists || source.data().userId !== req.user.uid) fail(404, 'Không tìm thấy giao dịch.');
    if (!reviewTarget(source.data(), sourceType, targetId)) fail(403, 'Chỉ đánh giá dịch vụ hoặc sản phẩm đã hoàn tất.');
    if (previous.exists) fail(409, 'Bạn đã đánh giá mục này trong giao dịch này.');
    tx.create(reviewRef, { userId: req.user.uid, sourceType, sourceId, targetId,
      type: sourceType === 'booking' ? 'service' : 'product', rating, comment: comment.trim(), createdAt: FieldValue.serverTimestamp() });
  });
  res.status(201).json({ success: true, data: { saved: true } });
}));
router.get('/reviews/:type/:id', wrap(async (req, res) => {
  const { type, id } = req.params;
  if (!validType(type) || !validId(id)) fail(400, 'Mục không hợp lệ.');
  // One equality index; type filtering and sorting do not need a composite index.
  const snap = await db.collection('experience_reviews').where('targetId', '==', id).get();
  const rows = snap.docs.map(doc => doc.data()).filter(r => r.type === type);
  const average = rows.length ? rows.reduce((s,r) => s+r.rating,0) / rows.length : null;
  rows.sort((a,b) => millis(b.createdAt)-millis(a.createdAt));
  send(res, { count: rows.length, average, reviews: rows.slice(0,50).map(r => ({ rating: r.rating, comment: r.comment,
    createdAt: Number.isFinite(millis(r.createdAt)) ? new Date(millis(r.createdAt)).toISOString() : null, author: 'Khách hàng LUMI' })) });
}));
router.get('/dashboard', requireAdmin, wrap(async (req, res) => {
  const [bookings, orders, users] = await Promise.all(['bookings','orders','users'].map(name => db.collection(name).get()));
  const today = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Ho_Chi_Minh', year:'numeric',month:'2-digit',day:'2-digit' }).format(new Date());
  const dateKey = value => Number.isFinite(millis(value)) ? new Intl.DateTimeFormat('en-CA', { timeZone:'Asia/Ho_Chi_Minh',year:'numeric',month:'2-digit',day:'2-digit' }).format(new Date(millis(value))) : '';
  const b = bookings.docs.map(d => ({ ...d.data(), id: d.id }));
  const o = orders.docs.map(d => d.data());
  const upcoming = b.filter(x => ['confirmed','approved'].includes(x.status) && millis(x.startAt) > Date.now()).sort((x,y) => millis(x.startAt)-millis(y.startAt)).slice(0,8);
  send(res, { today, bookingsToday: b.filter(x => dateKey(x.startAt) === today && !['cancelled','canceled','rejected'].includes(x.status)).length,
    pendingBookings: b.filter(x => x.status === 'pending').length, pendingOrders: o.filter(x => x.status === 'pending').length,
    completedOrders: o.filter(x => x.status === 'completed').length, customers: users.docs.filter(d => d.data().role !== 'admin').length,
    completedOrderValue: o.filter(x => x.status === 'completed').reduce((sum,x) => sum + (Number.isFinite(Number(x.total)) ? Number(x.total) : 0),0),
    upcoming: upcoming.map(x => ({ id:x.id, name:x.serviceName || 'Liệu trình LUMI', at:new Date(millis(x.startAt)).toISOString() })) });
}));
module.exports = router;
