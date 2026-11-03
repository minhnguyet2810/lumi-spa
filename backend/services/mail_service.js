const nodemailer = require('nodemailer');
require('dotenv').config();

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER || 'lumispa.project@gmail.com',
    pass: process.env.GMAIL_PASS || 'gsacetnpmwpdprtq',
  },
});

function formatVND(amount) {
  if (amount == null) return '0 đ';
  return Number(amount).toLocaleString('vi-VN') + ' đ';
}

function formatDate(val) {
  if (!val) return '';
  const d = new Date(val);
  if (isNaN(d.getTime())) return val;
  const hours = String(d.getHours()).padStart(2, '0');
  const minutes = String(d.getMinutes()).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const year = d.getFullYear();
  return `${hours}:${minutes} · ${day}/${month}/${year}`;
}

const BASE_TEMPLATE = (title, subtitle, contentHtml) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title}</title>
  <style>
    body {
      margin: 0;
      padding: 0;
      background-color: #FAF7F4;
      font-family: 'DM Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      color: #392F37;
      line-height: 1.6;
    }
    .wrapper {
      max-width: 600px;
      margin: 30px auto;
      background: #FFFFFF;
      border-radius: 18px;
      overflow: hidden;
      box-shadow: 0 10px 30px rgba(80, 59, 66, 0.08);
      border: 1px solid #F2E7E9;
    }
    .header {
      background: linear-gradient(135deg, #503B42 0%, #392F37 100%);
      padding: 36px 30px 30px;
      text-align: center;
      color: #FAF7F4;
    }
    .brand-title {
      font-family: 'Cormorant Garamond', Georgia, serif;
      font-size: 32px;
      letter-spacing: 4px;
      font-weight: 700;
      margin: 0 0 6px 0;
      text-transform: uppercase;
    }
    .brand-sub {
      font-size: 11px;
      letter-spacing: 2px;
      text-transform: uppercase;
      color: #D9AAB3;
      margin: 0;
    }
    .content {
      padding: 32px 30px;
    }
    .card-heading {
      font-family: 'Cormorant Garamond', Georgia, serif;
      font-size: 24px;
      font-weight: 700;
      color: #503B42;
      margin: 0 0 10px;
      text-align: center;
    }
    .card-desc {
      font-size: 14px;
      color: #765F67;
      text-align: center;
      margin: 0 0 24px;
    }
    .badge {
      display: inline-block;
      padding: 5px 14px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
      letter-spacing: 0.5px;
    }
    .badge-pending {
      background: #FEF3C7;
      color: #92400E;
    }
    .badge-confirmed {
      background: #DCFCE7;
      color: #166534;
    }
    .info-box {
      background: #FAF7F4;
      border-radius: 12px;
      padding: 20px;
      margin-bottom: 24px;
      border: 1px solid #F0E4E6;
    }
    .info-row {
      display: flex;
      justify-content: space-between;
      padding: 8px 0;
      border-bottom: 1px dashed #E5D5D8;
      font-size: 13.5px;
    }
    .info-row:last-child {
      border-bottom: none;
    }
    .info-label {
      color: #765F67;
    }
    .info-val {
      font-weight: 600;
      color: #503B42;
      text-align: right;
    }
    .table-container {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 20px;
    }
    .table-container th {
      background: #FAF7F4;
      color: #503B42;
      font-weight: 600;
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      padding: 10px 12px;
      text-align: left;
      border-bottom: 1px solid #E5D5D8;
    }
    .table-container td {
      padding: 12px;
      font-size: 13px;
      border-bottom: 1px solid #F0E4E6;
    }
    .footer {
      background: #FAF7F4;
      padding: 24px 30px;
      text-align: center;
      font-size: 12px;
      color: #8C767E;
      border-top: 1px solid #F0E4E6;
    }
    .footer p {
      margin: 4px 0;
    }
    .btn {
      display: inline-block;
      background: #B77C88;
      color: #FFFFFF !important;
      text-decoration: none;
      padding: 12px 28px;
      border-radius: 25px;
      font-size: 13px;
      font-weight: 600;
      letter-spacing: 0.5px;
      margin-top: 10px;
    }
  </style>
</head>
<body>
  <div class="wrapper">
    <div class="header">
      <h1 class="brand-title">LUMI SPA</h1>
      <p class="brand-sub">Wellness & Luxury Care</p>
    </div>
    <div class="content">
      <h2 class="card-heading">${title}</h2>
      <p class="card-desc">${subtitle}</p>
      ${contentHtml}
    </div>
    <div class="footer">
      <p><strong>LUMI SPA & WELLNESS CENTER</strong></p>
      <p>Địa chỉ: 128 Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh</p>
      <p>Hotline đặt hẹn: <strong>1900 6868</strong> · Email: lumispa.project@gmail.com</p>
      <p style="margin-top: 12px; font-size: 11px; color: #A69299;">Email này được gửi tự động từ hệ thống LUMI SPA.</p>
    </div>
  </div>
</body>
</html>
`;

/**
 * Gửi email khi khách đặt lịch thành công (trạng thái Pending)
 */
async function sendBookingCreatedEmail({
  to,
  customerName,
  customerPhone,
  bookingId,
  serviceName,
  startAt,
  durationMinutes,
  price,
}) {
  const recipient = to || process.env.GMAIL_USER;
  const content = `
    <div style="text-align: center; margin-bottom: 20px;">
      <span class="badge badge-pending">CHỜ XÁC NHẬN</span>
    </div>
    <div class="info-box">
      <div class="info-row">
        <span class="info-label">Mã lịch hẹn:</span>
        <span class="info-val">#${bookingId}</span>
      </div>
      <div class="info-row">
        <span class="info-label">Khách hàng:</span>
        <span class="info-val">${customerName || 'Quý khách'} (${customerPhone || ''})</span>
      </div>
      <div class="info-row">
        <span class="info-label">Dịch vụ:</span>
        <span class="info-val">${serviceName}</span>
      </div>
      <div class="info-row">
        <span class="info-label">Thời gian hẹn:</span>
        <span class="info-val">${formatDate(startAt)}</span>
      </div>
      <div class="info-row">
        <span class="info-label">Thời lượng liệu trình:</span>
        <span class="info-val">${durationMinutes} phút</span>
      </div>
      <div class="info-row">
        <span class="info-label">Chi phí dự kiến:</span>
        <span class="info-val" style="color: #B77C88;">${formatVND(price)}</span>
      </div>
    </div>
    <p style="font-size: 13.5px; color: #503B42; text-align: center;">
      Yêu cầu đặt lịch của quý khách đã được ghi nhận trên hệ thống.<br/>
      Lễ tân LUMI SPA sẽ liên hệ xác nhận và chuẩn bị phòng tốt nhất cho quý khách.
    </p>
  `;

  const html = BASE_TEMPLATE(
    'Yêu Cầu Đặt Lịch Hẹn Mới',
    'Cảm ơn bạn đã lựa chọn khoảng lặng chăm sóc bản thân tại LUMI SPA',
    content
  );

  try {
    const info = await transporter.sendMail({
      from: `"LUMI SPA & WELLNESS" <${process.env.GMAIL_USER}>`,
      to: recipient,
      subject: `🌸 [LUMI SPA] Tiếp nhận yêu cầu đặt lịch hẹn #${bookingId}`,
      html,
    });
    console.log(`[MailService] Sent booking created email to ${recipient}: ${info.messageId}`);
    return { success: true, messageId: info.messageId };
  } catch (err) {
    console.error('[MailService] Failed to send booking created email:', err.message);
    return { success: false, error: err.message };
  }
}

/**
 * Gửi email khi Admin / Lễ tân duyệt xác nhận lịch hẹn (Confirmed)
 */
async function sendBookingConfirmedEmail({
  to,
  customerName,
  customerPhone,
  bookingId,
  serviceName,
  startAt,
  durationMinutes,
  price,
  staffName,
  roomName,
}) {
  const recipient = to || process.env.GMAIL_USER;
  const content = `
    <div style="text-align: center; margin-bottom: 20px;">
      <span class="badge badge-confirmed">ĐÃ XÁC NHẬN</span>
    </div>
    <div class="info-box">
      <div class="info-row">
        <span class="info-label">Mã lịch hẹn:</span>
        <span class="info-val">#${bookingId}</span>
      </div>
      <div class="info-row">
        <span class="info-label">Khách hàng:</span>
        <span class="info-val">${customerName || 'Quý khách'} (${customerPhone || ''})</span>
      </div>
      <div class="info-row">
        <span class="info-label">Dịch vụ:</span>
        <span class="info-val">${serviceName}</span>
      </div>
      <div class="info-row">
        <span class="info-label">Thời gian hẹn:</span>
        <span class="info-val" style="color: #166534;">${formatDate(startAt)}</span>
      </div>
      <div class="info-row">
        <span class="info-label">Thời lượng liệu trình:</span>
        <span class="info-val">${durationMinutes} phút</span>
      </div>
      ${staffName ? `
      <div class="info-row">
        <span class="info-label">Chuyên viên phụ trách:</span>
        <span class="info-val">${staffName}</span>
      </div>` : ''}
      ${roomName ? `
      <div class="info-row">
        <span class="info-label">Phòng trị liệu:</span>
        <span class="info-val">${roomName}</span>
      </div>` : ''}
      <div class="info-row">
        <span class="info-label">Chi phí liệu trình:</span>
        <span class="info-val" style="color: #B77C88;">${formatVND(price)}</span>
      </div>
    </div>
    <div style="background: #FDF4F5; border-left: 3px solid #B77C88; padding: 12px 16px; border-radius: 8px; margin-bottom: 20px; font-size: 13px; color: #503B42;">
      📌 <strong>Lưu ý nhỏ:</strong> Quý khách vui lòng đến trước giờ hẹn 10 phút để được thưởng thức trà thảo mộc chào mừng và lắng nghe chuyên viên tư vấn da tốt nhất.
    </div>
  `;

  const html = BASE_TEMPLATE(
    'Lịch Hẹn Đã Được Xác Nhận',
    'Phòng chăm sóc và chuyên viên đã sẵn sàng đón tiếp bạn',
    content
  );

  try {
    const info = await transporter.sendMail({
      from: `"LUMI SPA & WELLNESS" <${process.env.GMAIL_USER}>`,
      to: recipient,
      subject: `✨ [LUMI SPA] Xác nhận thành công lịch hẹn #${bookingId}`,
      html,
    });
    console.log(`[MailService] Sent booking confirmed email to ${recipient}: ${info.messageId}`);
    return { success: true, messageId: info.messageId };
  } catch (err) {
    console.error('[MailService] Failed to send booking confirmed email:', err.message);
    return { success: false, error: err.message };
  }
}

/**
 * Gửi email khi đặt hàng mỹ phẩm / sản phẩm thành công
 */
async function sendOrderSuccessEmail({
  to,
  customerName,
  orderId,
  items,
  subtotal,
  shippingFee,
  total,
  shippingAddress,
  phone,
  paymentMethod,
}) {
  const recipient = to || process.env.GMAIL_USER;

  const itemsRows = (items || []).map(item => `
    <tr>
      <td style="font-weight: 600; color: #503B42;">${item.productName || item.productId}</td>
      <td style="text-align: center;">${item.quantity}</td>
      <td style="text-align: right;">${formatVND(item.unitPrice)}</td>
      <td style="text-align: right; font-weight: 600; color: #503B42;">${formatVND(item.subtotal)}</td>
    </tr>
  `).join('');

  const content = `
    <div style="text-align: center; margin-bottom: 20px;">
      <span class="badge badge-confirmed">ĐẶT HÀNG THÀNH CÔNG</span>
    </div>
    <div class="info-box">
      <div class="info-row">
        <span class="info-label">Mã đơn hàng:</span>
        <span class="info-val">#${orderId}</span>
      </div>
      <div class="info-row">
        <span class="info-label">Người nhận:</span>
        <span class="info-val">${customerName || 'Quý khách'} (${phone})</span>
      </div>
      <div class="info-row">
        <span class="info-label">Địa chỉ giao hàng:</span>
        <span class="info-val">${shippingAddress}</span>
      </div>
      <div class="info-row">
        <span class="info-label">Phương thức thanh toán:</span>
        <span class="info-val">${paymentMethod || 'COD (Thanh toán khi nhận hàng)'}</span>
      </div>
    </div>

    <table class="table-container">
      <thead>
        <tr>
          <th>Sản phẩm</th>
          <th style="text-align: center;">SL</th>
          <th style="text-align: right;">Đơn giá</th>
          <th style="text-align: right;">Thành tiền</th>
        </tr>
      </thead>
      <tbody>
        ${itemsRows}
      </tbody>
    </table>

    <div class="info-box">
      <div class="info-row">
        <span class="info-label">Tạm tính:</span>
        <span class="info-val">${formatVND(subtotal)}</span>
      </div>
      <div class="info-row">
        <span class="info-label">Phí vận chuyển:</span>
        <span class="info-val">${shippingFee ? formatVND(shippingFee) : 'Miễn phí'}</span>
      </div>
      <div class="info-row" style="font-size: 16px; margin-top: 8px;">
        <span class="info-label" style="font-weight: 700; color: #503B42;">Tổng thanh toán:</span>
        <span class="info-val" style="color: #B77C88; font-size: 18px;">${formatVND(total)}</span>
      </div>
    </div>

    <p style="font-size: 13.5px; color: #503B42; text-align: center;">
      Đơn hàng của bạn sẽ được nhân viên đóng gói và chuyển phát nhanh trong 1 - 2 ngày làm việc.
    </p>
  `;

  const html = BASE_TEMPLATE(
    'Xác Nhận Đơn Hàng Thành Công',
    'Cảm ơn bạn đã tin tưởng mua sắm mỹ phẩm cao cấp tại LUMI SPA',
    content
  );

  try {
    const info = await transporter.sendMail({
      from: `"LUMI SPA & WELLNESS" <${process.env.GMAIL_USER}>`,
      to: recipient,
      subject: `🛍️ [LUMI SPA] Xác nhận đơn hàng #${orderId} đặt thành công`,
      html,
    });
    console.log(`[MailService] Sent order success email to ${recipient}: ${info.messageId}`);
    return { success: true, messageId: info.messageId };
  } catch (err) {
    console.error('[MailService] Failed to send order success email:', err.message);
    return { success: false, error: err.message };
  }
}


/**
 * Gửi email khi Admin duyệt / cập nhật trạng thái đơn hàng (Confirmed / Shipping / Completed / Cancelled)
 */
async function sendOrderStatusUpdatedEmail({
  to,
  customerName,
  orderId,
  status,
  reason,
  items = [],
  total = 0,
  shippingAddress = '',
  phone = '',
  paymentMethod = 'COD',
}) {
  const recipient = to || process.env.GMAIL_USER;

  let badgeHtml = '';
  let headingTitle = '';
  let subTitle = '';
  let descNote = '';

  switch (status) {
    case 'confirmed':
    case 'processing':
      badgeHtml = '<span class="badge" style="background: #E6F4EA; color: #137333; font-weight: 700;">ĐÃ DUYỆT · ĐANG CHUẨN BỊ HÀNG</span>';
      headingTitle = 'Đơn Hàng Đã Được Duyệt Thành Công';
      subTitle = 'Nhân viên LUMI đang chuẩn bị và đóng gói sản phẩm cho bạn';
      descNote = 'Đơn hàng của bạn đã được quản trị viên duyệt thành công. Chúng tôi đang kiểm tra đóng gói cẩn thận và sẽ bàn giao cho đơn vị vận chuyển sớm nhất.';
      break;
    case 'shipping':
    case 'delivering':
      badgeHtml = '<span class="badge" style="background: #E8F0FE; color: #1A73E8; font-weight: 700;">ĐANG VẬN CHUYỂN GIAO HÀNG</span>';
      headingTitle = 'Đơn Hàng Đang Được Giao Đến Bạn';
      subTitle = 'Kiện hàng đã được bàn giao cho đối tác vận chuyển';
      descNote = 'Kiện hàng mỹ phẩm LUMI đang trên đường vận chuyển đến địa chỉ của bạn. Vui lòng chú ý điện thoại để nhận hàng.';
      break;
    case 'completed':
      badgeHtml = '<span class="badge badge-confirmed">GIAO HÀNG THÀNH CÔNG</span>';
      headingTitle = 'Giao Hàng Thành Công · Cảm Ơn Bạn!';
      subTitle = 'Chúc bạn có những trải nghiệm chăm sóc da tuyệt vời';
      descNote = 'Đơn hàng đã được giao thành công. Chúc bạn luôn rạng rỡ và hạnh phúc cùng các sản phẩm chăm sóc da cao cấp của LUMI SPA!';
      break;
    case 'cancelled':
    case 'rejected':
      badgeHtml = '<span class="badge badge-rejected">ĐƠN HÀNG ĐÃ HỦY</span>';
      headingTitle = 'Thông Báo Hủy Đơn Hàng';
      subTitle = 'Đơn hàng không thể tiếp tục xử lý';
      descNote = reason ? ('Lý do hủy đơn: ' + reason) : 'Đơn hàng đã bị hủy theo yêu cầu hoặc do sự cố kỹ thuật. Chúng tôi rất tiếc vì sự bất tiện này.';
      break;
    default:
      badgeHtml = '<span class="badge badge-pending">' + (status || '').toUpperCase() + '</span>';
      headingTitle = 'Cập Nhật Trạng Thái Đơn Hàng';
      subTitle = 'Đơn hàng #' + orderId + ' đã chuyển sang trạng thái mới';
      descNote = 'Trạng thái hiện tại: ' + status;
  }

  const itemsRows = Array.isArray(items) && items.length > 0
    ? items.map(it => {
        const name = it.name || it.productName || 'Sản phẩm LUMI';
        const qty = it.quantity || 1;
        const price = formatVND(it.price || it.unitPrice || 0);
        return '<tr>' +
          '<td style="padding: 10px 12px; border-bottom: 1px solid #F4E8EA;">' + name + '</td>' +
          '<td style="padding: 10px 12px; border-bottom: 1px solid #F4E8EA; text-align: center;">' + qty + '</td>' +
          '<td style="padding: 10px 12px; border-bottom: 1px solid #F4E8EA; text-align: right;">' + price + '</td>' +
        '</tr>';
      }).join('')
    : '<tr><td colspan="3" style="padding: 10px 12px; text-align: center; color: #78676B;">Chi tiết sản phẩm xem trong ứng dụng</td></tr>';

  const content = `
    <div style="text-align: center; margin-bottom: 20px;">
      ${badgeHtml}
    </div>
    <div class="info-box">
      <div class="info-row">
        <span class="info-label">Mã đơn hàng:</span>
        <span class="info-val">#${orderId}</span>
      </div>
      <div class="info-row">
        <span class="info-label">Người nhận:</span>
        <span class="info-val">${customerName || 'Quý khách'} (${phone || ''})</span>
      </div>
      ${shippingAddress ? `
      <div class="info-row">
        <span class="info-label">Địa chỉ giao hàng:</span>
        <span class="info-val">${shippingAddress}</span>
      </div>` : ''}
      <div class="info-row">
        <span class="info-label">Phương thức thanh toán:</span>
        <span class="info-val">${paymentMethod || 'Thanh toán khi nhận hàng (COD)'}</span>
      </div>
      <div class="info-row" style="font-size: 16px; margin-top: 8px;">
        <span class="info-label" style="font-weight: 700; color: #503B42;">Tổng tiền thanh toán:</span>
        <span class="info-val" style="color: #B77C88; font-size: 18px; font-weight: 700;">${formatVND(total)}</span>
      </div>
    </div>

    ${Array.isArray(items) && items.length > 0 ? `
    <table class="table-container" style="width: 100%; border-collapse: collapse; margin-bottom: 20px;">
      <thead>
        <tr style="background: #FDF4F5;">
          <th style="padding: 10px 12px; text-align: left; font-size: 12px; color: #503B42;">Sản phẩm</th>
          <th style="padding: 10px 12px; text-align: center; font-size: 12px; color: #503B42;">SL</th>
          <th style="padding: 10px 12px; text-align: right; font-size: 12px; color: #503B42;">Đơn giá</th>
        </tr>
      </thead>
      <tbody>
        ${itemsRows}
      </tbody>
    </table>` : ''}

    <div style="background: #FDF4F5; border-left: 3px solid #B77C88; padding: 14px 18px; border-radius: 8px; margin-bottom: 20px; font-size: 13.5px; color: #503B42; line-height: 1.6;">
      💬 ${descNote}
    </div>

    <p style="font-size: 13px; color: #78676B; text-align: center;">
      Cần hỗ trợ đơn hàng? Liên hệ hotline CSKH LUMI SPA hoặc phản hồi trực tiếp email này.
    </p>
  `;

  const html = BASE_TEMPLATE(
    headingTitle,
    subTitle,
    content
  );

  try {
    const info = await transporter.sendMail({
      from: `"LUMI SPA & WELLNESS" <${process.env.GMAIL_USER}>`,
      to: recipient,
      subject: `🛍️ [LUMI SPA] Cập nhật đơn hàng #${orderId}: ${headingTitle}`,
      html,
    });
    console.log(`[MailService] Sent order status update email to ${recipient}: ${info.messageId}`);
    return { success: true, messageId: info.messageId };
  } catch (err) {
    console.error('[MailService] Failed to send order status email:', err.message);
    return { success: false, error: err.message };
  }
}

module.exports = {
  sendBookingCreatedEmail,
  sendBookingConfirmedEmail,
  sendOrderSuccessEmail,
  sendOrderStatusUpdatedEmail,
};

