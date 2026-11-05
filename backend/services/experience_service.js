const crypto = require('node:crypto');
const { Timestamp, FieldValue } = require('firebase-admin/firestore');
const key = (...parts) => crypto.createHash('sha256').update(JSON.stringify(parts)).digest('hex');
const millis = value => value?.toMillis?.() ?? value?.toDate?.().getTime() ?? new Date(value).getTime();
const active = data => ['confirmed', 'approved'].includes(data.status);
const reviewKey = (uid, sourceType, sourceId, targetId) => key(uid, sourceType, sourceId, targetId);
function reviewTarget(data, kind, targetId) {
  if (data.status !== 'completed') return false;
  return kind === 'booking' ? data.serviceId === targetId :
    Array.isArray(data.items) && data.items.some(item => item.productId === targetId);
}
async function runReminders(db, push, now = new Date()) {
  if (!db.hasCredentials) throw new Error('Storage unavailable');
  const end = new Date(now.getTime() + 60 * 60 * 1000);
  const snapshot = await db.collection('bookings')
    .where('startAt', '>', Timestamp.fromDate(now))
    .where('startAt', '<=', Timestamp.fromDate(end)).get();
  let created = 0;
  for (const candidate of snapshot.docs) {
    const result = await db.runTransaction(async tx => {
      const booking = await tx.get(candidate.ref);
      if (!booking.exists) return null;
      const data = booking.data();
      const start = millis(data.startAt);
      if (!active(data) || !data.userId || !Number.isFinite(start) || start <= now.getTime() || start > end.getTime()) return null;
      const pref = await tx.get(db.collection('experience_preferences').doc(data.userId));
      if (!pref.exists || pref.data().remindersEnabled !== true) return null;
      const id = 'reminder_' + key(candidate.id, start);
      const notification = db.collection('notifications').doc(id);
      const receipt = db.collection('experience_reminder_receipts').doc(id);
      const existing = await tx.get(receipt);
      if (existing.exists) return null;
      const time = new Intl.DateTimeFormat('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh', hour: '2-digit', minute: '2-digit', day: '2-digit', month: '2-digit' }).format(new Date(start));
      const message = { userId: data.userId, title: 'LUMI nhắc lịch hẹn',
        body: `${data.serviceName || 'Liệu trình của bạn'} lúc ${time}. Hẹn gặp bạn tại LUMI!`,
        type: 'appointment', bookingId: candidate.id, status: data.status, isRead: false,
        createdAt: FieldValue.serverTimestamp() };
      tx.create(receipt, { bookingId: candidate.id, startAt: data.startAt, createdAt: FieldValue.serverTimestamp() });
      tx.create(notification, message);
      return message;
    });
    if (result) {
      created++;
      // Inbox is durable and deduplicated. Push is best-effort and never retried by this worker.
      try { await push({ userId: result.userId, title: result.title, body: result.body,
        data: { type: 'appointment', bookingId: result.bookingId, status: result.status } }); }
      catch (error) { console.warn('Reminder push failed:', error.message); }
    }
  }
  return { created };
}
module.exports = { key, millis, reviewKey, reviewTarget, runReminders };
