const db = require('../firebase');
const { getMessaging } = require('firebase-admin/messaging');

let messagingInstance = null;
function getMessagingSafe() {
  if (!messagingInstance) {
    try {
      messagingInstance = getMessaging();
    } catch (e) {
      console.warn('FCM Messaging initialization error:', e.message);
    }
  }
  return messagingInstance;
}

/**
 * Lấy danh sách FCM Device Tokens của user từ Firestore
 */
async function getUserTokens(userId) {
  if (!db.hasCredentials || !userId) {
    return [];
  }

  try {
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) return [];

    const data = userDoc.data() || {};
    const tokens = new Set();

    if (data.fcmToken && typeof data.fcmToken === 'string') {
      tokens.add(data.fcmToken.trim());
    }

    if (Array.isArray(data.fcmTokens)) {
      data.fcmTokens.forEach(t => {
        if (typeof t === 'string' && t.trim()) tokens.add(t.trim());
      });
    }

    return Array.from(tokens);
  } catch (err) {
    console.error(`[PushService] Lỗi khi lấy FCM tokens cho user ${userId}:`, err.message);
    return [];
  }
}

/**
 * Xóa token không còn hợp lệ khỏi Firestore
 */
async function removeInvalidToken(userId, token) {
  if (!db.hasCredentials || !userId || !token) return;
  try {
    const { FieldValue } = require('firebase-admin/firestore');
    await db.collection('users').doc(userId).update({
      fcmTokens: FieldValue.arrayRemove(token),
    });
  } catch (_) {}
}

/**
 * Gửi Push Notification tới tất cả thiết bị của một user
 */
async function sendPushToUser({ userId, title, body, data = {} }) {
  const messaging = getMessagingSafe();
  if (!messaging) {
    console.warn('[PushService] FCM Messaging chưa sẵn sàng (chưa có credentials).');
    return { success: false, reason: 'NO_MESSAGING' };
  }

  const tokens = await getUserTokens(userId);
  if (tokens.length === 0) {
    console.log(`[PushService] User ${userId} chưa có FCM device token.`);
    return { success: false, reason: 'NO_TOKENS' };
  }

  const payloadData = {};
  for (const [k, v] of Object.entries(data)) {
    payloadData[k] = String(v ?? '');
  }

  const messages = tokens.map(token => ({
    token,
    notification: {
      title,
      body,
    },
    data: {
      ...payloadData,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'lumi_notifications_channel',
        sound: 'default',
        defaultSound: true,
        defaultVibrateTimings: true,
        priority: 'max',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
        },
      },
    },
  }));

  try {
    const response = await messaging.sendEach(messages);
    console.log(`[PushService] Đã gửi FCM push tới user ${userId}: ${response.successCount}/${tokens.length} thành công.`);

    // Thu dọn token không còn tồn tại
    response.responses.forEach((res, idx) => {
      if (!res.success) {
        const errCode = res.error?.code;
        if (
          errCode === 'messaging/registration-token-not-registered' ||
          errCode === 'messaging/invalid-registration-token'
        ) {
          removeInvalidToken(userId, tokens[idx]);
        }
      }
    });

    return {
      success: response.successCount > 0,
      successCount: response.successCount,
      failureCount: response.failureCount,
    };
  } catch (error) {
    console.error(`[PushService] Lỗi khi gửi push tới user ${userId}:`, error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Push thông báo đặt lịch hẹn thành công (chờ xác nhận)
 */
async function sendBookingCreatedPush({ userId, bookingId, serviceName, date, hour }) {
  return sendPushToUser({
    userId,
    title: '🌸 Đã nhận yêu cầu đặt lịch hẹn!',
    body: `Liệu trình "${serviceName}" lúc ${hour}:00 ngày ${date} đang chờ lễ tân LUMI SPA xác nhận.`,
    data: {
      type: 'appointment',
      bookingId: bookingId || '',
      status: 'pending',
    },
  });
}

/**
 * Push thông báo admin đã duyệt lịch hẹn
 */
async function sendBookingConfirmedPush({ userId, bookingId, serviceName, date, hour, staffName, roomName }) {
  const details = [staffName ? `KTV: ${staffName}` : '', roomName ? `Phòng: ${roomName}` : '']
    .filter(Boolean)
    .join(' • ');

  const bodyText = details
    ? `Lịch hẹn "${serviceName}" lúc ${hour}:00 ngày ${date} đã được duyệt (${details}).`
    : `Lịch hẹn "${serviceName}" lúc ${hour}:00 ngày ${date} đã được duyệt thành công!`;

  return sendPushToUser({
    userId,
    title: '✨ Lịch hẹn đã được xác nhận!',
    body: bodyText,
    data: {
      type: 'appointment',
      bookingId: bookingId || '',
      status: 'confirmed',
    },
  });
}

/**
 * Push thông báo đặt mua hàng thành công
 */
async function sendOrderSuccessPush({ userId, orderId, itemCount, totalAmount }) {
  const formattedTotal = Number(totalAmount || 0).toLocaleString('vi-VN');
  return sendPushToUser({
    userId,
    title: '🛍️ Đặt hàng thành công!',
    body: `Đơn hàng #${(orderId || '').slice(-6).toUpperCase()} (${itemCount} sản phẩm - ${formattedTotal}đ) đã được tạo thành công.`,
    data: {
      type: 'order',
      orderId: orderId || '',
      status: 'pending',
    },
  });
}


/**
 * Push thông báo trạng thái đơn hàng thay đổi
 */
async function sendOrderStatusUpdatedPush({ userId, orderId, status, statusText }) {
  let title = '🛍️ Cập nhật đơn hàng!';
  let body = `Đơn hàng #${(orderId || '').slice(-6).toUpperCase()} ${statusText || 'đã được cập nhật.'}`;

  if (status === 'confirmed' || status === 'processing') {
    title = '📦 Đơn hàng đã được duyệt!';
    body = `Đơn hàng #${(orderId || '').slice(-6).toUpperCase()} đã được duyệt và đang chuẩn bị đóng gói.`;
  } else if (status === 'shipping' || status === 'delivering') {
    title = '🚚 Đơn hàng đang được giao!';
    body = `Đơn hàng #${(orderId || '').slice(-6).toUpperCase()} đang trên đường vận chuyển đến bạn.`;
  } else if (status === 'completed') {
    title = '🎉 Giao hàng thành công!';
    body = `Đơn hàng #${(orderId || '').slice(-6).toUpperCase()} đã được giao thành công. Cảm ơn bạn!`;
  } else if (status === 'cancelled' || status === 'rejected') {
    title = '⚠️ Đơn hàng đã bị hủy';
    body = `Đơn hàng #${(orderId || '').slice(-6).toUpperCase()} đã bị hủy. Nhấn để xem chi tiết.`;
  }

  return sendPushToUser({
    userId,
    title,
    body,
    data: {
      type: 'order',
      orderId: orderId || '',
      status: status || '',
    },
  });
}

module.exports = {
  getUserTokens,
  sendPushToUser,
  sendBookingCreatedPush,
  sendBookingConfirmedPush,
  sendOrderSuccessPush,
  sendOrderStatusUpdatedPush,
};

