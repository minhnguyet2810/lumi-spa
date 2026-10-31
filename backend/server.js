const mailService = require('./services/mail_service');
const pushService = require('./services/push_service');
process.on('unhandledRejection', (reason) => {
  console.warn('Unhandled Rejection caught:', reason && (reason.message || reason));
});
process.on('uncaughtException', (err) => {
  console.warn('Uncaught Exception caught:', err && (err.message || err));
});

require('dotenv').config();

const express = require('express');
const cors = require('cors');
const db = require('./firebase');
const adminRoutes = require('./routes/admin');
const notificationRoutes = require('./routes/notifications');
const membershipRoutes = require('./routes/membership');
const orderRoutes = require('./routes/orders');
const bookingRoutes = require('./routes/bookings');
const profileRoutes = require('./routes/profile');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.use('/api/admin', adminRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/membership', membershipRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/me', profileRoutes);

// Convert Firestore Timestamp into JSON-compatible values.
function serialize(value) {
  if (value == null) return value;

  if (typeof value.toDate === 'function') {
    return value.toDate().toISOString();
  }

  if (Array.isArray(value)) {
    return value.map(serialize);
  }

  if (typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value).map(([key, val]) => [
        key,
        serialize(val),
      ])
    );
  }

  return value;
}

const DEFAULT_SERVICES = [
  {
    id: 'spa001',
    name: 'Trị Liệu Trẻ Hóa Tế Bào Lumi',
    shortDescription: 'Liệu trình trẻ hóa chuyên sâu kết hợp serum tế bào gốc độc quyền.',
    fullDescription: 'Liệu trình trẻ hóa chuyên sâu kết hợp serum tế bào gốc độc quyền, giúp tái tạo cấu trúc da, cải thiện độ đàn hồi và làm mờ các nếp nhăn li ti.',
    durationMinutes: 90,
    price: 1800000,
    categoryId: 'facial',
    categoryName: 'Chăm sóc da mặt',
    imageUrl: 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=900&auto=format&fit=crop',
    isActive: true,
  },
  {
    id: 'spa002',
    name: 'Thư Giãn Đá Nóng & Tinh Dầu Hoàng Lan',
    shortDescription: 'Massage toàn thân với đá bazan núi lửa tự nhiên và tinh dầu ngọc lan tây.',
    fullDescription: 'Massage toàn thân với đá bazan núi lửa tự nhiên kết hợp tinh dầu ngọc lan tây, giải tỏa căng thẳng cơ bắp và lưu thông khí huyết tối ưu.',
    durationMinutes: 75,
    price: 1200000,
    categoryId: 'body',
    categoryName: 'Trị liệu toàn thân',
    imageUrl: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=900&auto=format&fit=crop',
    isActive: true,
  },
  {
    id: 'spa003',
    name: 'Cấp Ẩm Chuyên Sâu & Phục Hồi Làn Da',
    shortDescription: 'Cung cấp độ ẩm tức thì với phức hợp Hyaluronic Acid đa tầng.',
    fullDescription: 'Cung cấp độ ẩm tức thì cho da khô thiếu nước với phức hợp Hyaluronic Acid đa tầng, phục hồi màng bảo vệ tự nhiên của làn da căng bóng rạng rỡ.',
    durationMinutes: 60,
    price: 950000,
    categoryId: 'skincare',
    categoryName: 'Chăm sóc da mặt',
    imageUrl: 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?w=900&auto=format&fit=crop',
    isActive: true,
  },
  {
    id: 'spa004',
    name: 'Gội Đầu Dưỡng Sinh Hoàng Cung',
    shortDescription: 'Liệu pháp dưỡng sinh kết hợp bấm huyệt vùng đầu cổ vai gáy.',
    fullDescription: 'Liệu pháp gội đầu dưỡng sinh thảo mộc cổ truyền kết hợp bấm huyệt chuyên sâu vùng đầu, cổ, vai, gáy giúp ngủ ngon và sảng khoái tinh thần.',
    durationMinutes: 60,
    price: 450000,
    categoryId: 'hair',
    categoryName: 'Dưỡng sinh thư giãn',
    imageUrl: 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?w=900&auto=format&fit=crop',
    isActive: true,
  },
  {
    id: 'spa005',
    name: 'Thải Độc & Thanh Lọc Bằng Thảo Dược',
    shortDescription: 'Xông hơi và ủ thảo mộc thiên nhiên loại bỏ độc tố tích tụ.',
    fullDescription: 'Liệu trình xông hơi đá muối Himalaya kết hợp đắp ủ thảo mộc bí truyền giúp kích thích tuần hoàn máu và đào thải độc tố toàn diện.',
    durationMinutes: 90,
    price: 1500000,
    categoryId: 'body',
    categoryName: 'Trị liệu toàn thân',
    imageUrl: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=900&auto=format&fit=crop',
    isActive: true,
  },
];

// Read active documents from Firestore.
async function getCollection(collectionName) {
  if (!db.hasCredentials) {
    if (collectionName === 'services') return DEFAULT_SERVICES;
    return [];
  }

  const snapshot = await db.collection(collectionName).get();

  return snapshot.docs
    .map((doc) => ({
      id: doc.id,
      ...serialize(doc.data()),
    }))
    .filter((item) => item.isActive !== false);
}

// Handle errors consistently.
function handleError(res, error) {
  console.error('LUMI API error:', error);

  return res.status(500).json({
    success: false,
    message: 'Không thể tải dữ liệu. Vui lòng thử lại.',
  });
}

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'LUMI SPA API is running',
  });
});

// GET all spa services
app.get('/api/services', async (req, res) => {
  try {
    const services = await getCollection('services');

    res.json({
      success: true,
      count: services.length,
      data: services,
    });
  } catch (error) {
    handleError(res, error);
  }
});

// GET service detail
app.get('/api/services/:id', async (req, res) => {
  try {
    if (!db.hasCredentials) {
      const found = DEFAULT_SERVICES.find((s) => s.id === req.params.id);
      if (found) {
        return res.json({ success: true, data: found });
      }
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy dịch vụ.',
      });
    }

    const doc = await db
      .collection('services')
      .doc(req.params.id)
      .get();

    if (!doc.exists || doc.data().isActive === false) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy dịch vụ.',
      });
    }

    res.json({
      success: true,
      data: {
        id: doc.id,
        ...serialize(doc.data()),
      },
    });
  } catch (error) {
    handleError(res, error);
  }
});

// GET all shop products
app.get('/api/products', async (req, res) => {
  try {
    const products = await getCollection('products');

    res.json({
      success: true,
      count: products.length,
      data: products,
    });
  } catch (error) {
    handleError(res, error);
  }
});

// GET product detail
app.get('/api/products/:id', async (req, res) => {
  try {
    const doc = await db
      .collection('products')
      .doc(req.params.id)
      .get();

    if (!doc.exists || doc.data().isActive === false) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy sản phẩm.',
      });
    }

    res.json({
      success: true,
      data: {
        id: doc.id,
        ...serialize(doc.data()),
      },
    });
  } catch (error) {
    handleError(res, error);
  }
});

// GET categories
app.get('/api/categories', async (req, res) => {
  try {
    const categories = await getCollection('categories');

    res.json({
      success: true,
      count: categories.length,
      data: categories,
    });
  } catch (error) {
    handleError(res, error);
  }
});

// GET home banners
app.get('/api/banners', async (req, res) => {
  try {
    const banners = await getCollection('banners');

    res.json({
      success: true,
      count: banners.length,
      data: banners,
    });
  } catch (error) {
    handleError(res, error);
  }
});

// API homepage
app.get('/', (req, res) => {
  res.json({
    success: true,
    app: 'LUMI SPA',
    message: 'Welcome to LUMI SPA REST API',
    endpoints: [
      '/api/health',
      '/api/services',
      '/api/services/:id',
      '/api/products',
      '/api/products/:id',
      '/api/categories',
      '/api/banners',
    ],
  });
});


// POST /api/orders/:id/notify-status
// Endpoint xử lý cập nhật trạng thái đơn hàng, gửi Gmail xác nhận và bắn thông báo Push FCM
// ==========================================
// ADMIN BOOKING APIS (Duyệt & Quản lý Lịch hẹn Spa)
// ==========================================

// GET /api/admin-bookings
// Endpoint xem xét và quản lý toàn bộ lịch hẹn Spa (kèm lọc, tìm kiếm và thống kê)
app.get('/api/admin-bookings', async (req, res) => {
  try {
    const { status, q } = req.query;
    let bookings = [];

    if (db.hasCredentials) {
      const snap = await db.collection('bookings').get();
      bookings = snap.docs.map(doc => ({
        id: doc.id,
        ...serialize(doc.data()),
      }));
    } else {
      bookings = [...devBookings];
    }

    bookings.sort((a, b) => {
      const dateA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
      const dateB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
      return dateB - dateA;
    });

    const stats = {
      total: bookings.length,
      pending: bookings.filter(b => (b.status || '').toLowerCase() === 'pending').length,
      approved: bookings.filter(b => ['approved', 'confirmed'].includes((b.status || '').toLowerCase())).length,
      rejected: bookings.filter(b => ['rejected', 'cancelled'].includes((b.status || '').toLowerCase())).length,
    };

    if (status && status !== 'all') {
      const s = status.toLowerCase();
      if (s === 'approved') {
        bookings = bookings.filter(b => ['approved', 'confirmed'].includes((b.status || '').toLowerCase()));
      } else if (s === 'rejected') {
        bookings = bookings.filter(b => ['rejected', 'cancelled'].includes((b.status || '').toLowerCase()));
      } else {
        bookings = bookings.filter(b => (b.status || '').toLowerCase() === s);
      }
    }

    if (q && q.trim()) {
      const term = q.trim().toLowerCase();
      bookings = bookings.filter(b => {
        const idMatch = (b.id || '').toLowerCase().includes(term);
        const nameMatch = (b.contactName || '').toLowerCase().includes(term);
        const phoneMatch = (b.contactPhone || '').toLowerCase().includes(term);
        const serviceMatch = (b.serviceName || '').toLowerCase().includes(term);
        return idMatch || nameMatch || phoneMatch || serviceMatch;
      });
    }

    return res.json({
      success: true,
      count: bookings.length,
      stats,
      data: bookings,
    });
  } catch (err) {
    console.error('Error fetching admin bookings:', err);
    return res.status(500).json({ success: false, message: 'Không thể tải danh sách lịch hẹn.' });
  }
});

// POST / PATCH /api/admin-bookings/:id/status
// Cập nhật trạng thái duyệt/từ chối lịch hẹn, gửi Gmail và Push FCM
async function handleAdminBookingStatus(req, res) {
  try {
    const { id } = req.params;
    const { status, reason = '' } = req.body || {};

    if (!['approved', 'confirmed', 'rejected', 'cancelled'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Trạng thái không hợp lệ.' });
    }

    if (!db.hasCredentials) {
      const b = devBookings.find(item => item.id === id);
      if (b) {
        b.status = status;
        if (status === 'approved' || status === 'confirmed') {
          b.approvedAt = new Date().toISOString();
        } else {
          b.rejectedAt = new Date().toISOString();
          b.rejectReason = reason;
        }
      }
      return res.json({ success: true, message: 'Đã cập nhật trạng thái (dev store).' });
    }

    const docRef = db.collection('bookings').doc(id);
    const docSnap = await docRef.get();
    if (!docSnap.exists) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy lịch hẹn.' });
    }
    const booking = docSnap.data();

    const isApprove = ['approved', 'confirmed'].includes(status);
    const updateData = {
      status,
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (isApprove) {
      updateData.approvedAt = FieldValue.serverTimestamp();
      updateData.approvedBy = 'admin';
    } else {
      updateData.rejectedAt = FieldValue.serverTimestamp();
      updateData.rejectReason = reason;
    }

    await docRef.update(updateData);

    // Gửi thông báo In-App trong Firestore
    if (booking.userId) {
      try {
        await db.collection('notifications').add({
          userId: booking.userId,
          title: isApprove ? 'Lịch hẹn đã được duyệt ✨' : 'Lịch hẹn đã bị từ chối ⚠️',
          message: isApprove
            ? `Lịch hẹn "${booking.serviceName || 'Dịch vụ Spa'}" đã được lễ tân duyệt thành công!`
            : `Lịch hẹn "${booking.serviceName || 'Dịch vụ Spa'}" đã bị từ chối.${reason ? ' Lý do: ' + reason : ''}`,
          type: 'appointment',
          isRead: false,
          createdAt: FieldValue.serverTimestamp(),
        });
      } catch (notifErr) {
        console.warn('Booking notification error:', notifErr.message);
      }
    }

    // Gửi Gmail xác nhận
    const targetEmail = booking.contactEmail || booking.email;
    if (targetEmail && isApprove) {
      try {
        let startTimeStr = '';
        if (booking.startAt) {
          const d = booking.startAt.toDate ? booking.startAt.toDate() : new Date(booking.startAt);
          startTimeStr = d.toLocaleString('vi-VN');
        }
        await mailService.sendBookingConfirmedEmail({
          to: targetEmail,
          customerName: booking.contactName || 'Quý khách',
          customerPhone: booking.contactPhone || '',
          bookingId: id,
          serviceName: booking.serviceName || 'Dịch vụ Spa',
          startAt: startTimeStr,
          durationMinutes: booking.durationMinutes || 60,
          price: booking.price || 0,
        });
      } catch (mailErr) {
        console.warn('Booking mail error:', mailErr.message);
      }
    }

    // Gửi FCM Push notification
    if (booking.userId) {
      try {
        if (isApprove) {
          await pushService.sendBookingConfirmedPush({
            userId: booking.userId,
            bookingId: id,
            serviceName: booking.serviceName || 'Dịch vụ Spa',
            date: '',
            hour: '',
          });
        }
      } catch (pushErr) {
        console.warn('Booking push error:', pushErr.message);
      }
    }

    return res.json({
      success: true,
      message: isApprove ? 'Duyệt lịch hẹn thành công!' : 'Đã từ chối lịch hẹn.',
    });
  } catch (err) {
    console.error('Error updating admin booking:', err);
    return res.status(500).json({ success: false, message: 'Lỗi cập nhật lịch hẹn: ' + err.message });
  }
}

app.patch('/api/admin-bookings/:id/status', handleAdminBookingStatus);
app.post('/api/admin-bookings/:id/status', handleAdminBookingStatus);

// ==========================================
// ADMIN ORDER APIS (Duyệt & Quản lý Đơn hàng)
// ==========================================

// GET /api/admin-orders
// Endpoint xem xét và quản lý toàn bộ đơn hàng (kèm bộ lọc, tìm kiếm và thống kê)
app.get('/api/admin-orders', async (req, res) => {
  try {
    const { status, q } = req.query;
    let orders = [];

    if (db.hasCredentials) {
      const snap = await db.collection('orders').get();
      orders = snap.docs.map(doc => ({
        id: doc.id,
        ...serialize(doc.data()),
      }));
    }

    orders.sort((a, b) => {
      const dateA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
      const dateB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
      return dateB - dateA;
    });

    const stats = {
      total: orders.length,
      pending: orders.filter(o => (o.status || '').toLowerCase() === 'pending').length,
      confirmed: orders.filter(o => ['confirmed', 'processing'].includes((o.status || '').toLowerCase())).length,
      shipping: orders.filter(o => ['shipping', 'delivering'].includes((o.status || '').toLowerCase())).length,
      completed: orders.filter(o => (o.status || '').toLowerCase() === 'completed').length,
      cancelled: orders.filter(o => ['cancelled', 'rejected'].includes((o.status || '').toLowerCase())).length,
      totalRevenue: orders
        .filter(o => ['confirmed', 'shipping', 'completed'].includes((o.status || '').toLowerCase()))
        .reduce((sum, o) => sum + (Number(o.total) || 0), 0),
    };

    if (status && status !== 'all') {
      const s = status.toLowerCase();
      orders = orders.filter(o => (o.status || '').toLowerCase() === s);
    }

    if (q && q.trim()) {
      const term = q.trim().toLowerCase();
      orders = orders.filter(o => {
        const idMatch = (o.id || '').toLowerCase().includes(term);
        const nameMatch = (o.customerName || o.name || '').toLowerCase().includes(term);
        const phoneMatch = (o.phone || '').toLowerCase().includes(term);
        const emailMatch = (o.customerEmail || o.email || '').toLowerCase().includes(term);
        return idMatch || nameMatch || phoneMatch || emailMatch;
      });
    }

    return res.json({
      success: true,
      count: orders.length,
      stats,
      data: orders,
    });
  } catch (err) {
    console.error('Error fetching orders:', err);
    return res.status(500).json({ success: false, message: 'Không thể tải danh sách đơn hàng.' });
  }
});

// GET /api/admin-orders/:id
// Endpoint xem xét chi tiết 1 đơn hàng cụ thể
app.get('/api/admin-orders/:id', async (req, res) => {
  try {
    const { id } = req.params;
    if (!db.hasCredentials) {
      return res.status(404).json({ success: false, message: 'Chưa kết nối database.' });
    }
    const doc = await db.collection('orders').doc(id).get();
    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy đơn hàng.' });
    }
    return res.json({
      success: true,
      data: {
        id: doc.id,
        ...serialize(doc.data()),
      },
    });
  } catch (err) {
    console.error('Error fetching order detail:', err);
    return res.status(500).json({ success: false, message: 'Lỗi khi tải chi tiết đơn hàng.' });
  }
});

// POST /api/admin-orders/:id/status (hỗ trợ cả /api/orders/:id/notify-status)
async function handleAdminOrderStatus(req, res) {
  try {
    const { id } = req.params;
    const {
      status,
      reason = '',
      customerEmail,
      customerName,
      items,
      total,
      shippingAddress,
      phone,
      paymentMethod,
      userId,
    } = req.body || {};

    if (!status) {
      return res.status(400).json({ success: false, message: 'Thiếu trạng thái status.' });
    }

    let orderDocData = null;
    if (db.hasCredentials) {
      try {
        const orderRef = db.collection('orders').doc(id);
        const docSnap = await orderRef.get();
        if (docSnap.exists) {
          orderDocData = docSnap.data();
          await orderRef.update({
            status,
            cancelReason: reason || '',
            updatedAt: FieldValue.serverTimestamp(),
          });
        }
      } catch (dbErr) {
        console.warn('[OrdersAPI] Firestore update warning:', dbErr.message);
      }
    }

    const effectiveUserId = userId || orderDocData?.userId;
    const effectiveEmail = customerEmail || orderDocData?.customerEmail || orderDocData?.email;
    const effectiveName = customerName || orderDocData?.customerName;
    const effectivePhone = phone || orderDocData?.phone;
    const effectiveAddress = shippingAddress || orderDocData?.shippingAddress || orderDocData?.address;
    const effectiveTotal = total ?? orderDocData?.total ?? 0;
    const effectiveItems = items || orderDocData?.items || [];
    const effectivePayment = paymentMethod || orderDocData?.paymentMethod || 'COD';

    if (effectiveUserId && db.hasCredentials) {
      const statusLabels = {
        confirmed: 'đã được duyệt và đang chuẩn bị hàng ✨',
        shipping: 'đang trên đường vận chuyển đến bạn 🚚',
        completed: 'đã được giao thành công 🎉',
        cancelled: 'đã bị hủy' + (reason ? ': ' + reason : '') + ' ⚠️',
      };
      const text = statusLabels[status] || ('đã chuyển sang trạng thái "' + status + '"');

      try {
        await db.collection('notifications').add({
          userId: effectiveUserId,
          title: status === 'cancelled' ? 'Đơn hàng đã bị hủy ⚠️' : 'Cập nhật đơn hàng 🛍️',
          message: 'Đơn hàng #' + id + ' ' + text + '.',
          type: 'order',
          orderId: id,
          isRead: false,
          createdAt: FieldValue.serverTimestamp(),
        });
      } catch (notifErr) {
        console.warn('[OrdersAPI] Notification add error:', notifErr.message);
      }

      try {
        await pushService.sendOrderStatusUpdatedPush({
          userId: effectiveUserId,
          orderId: id,
          status,
          statusText: text,
        });
      } catch (pushErr) {
        console.warn('[OrdersAPI] Push notification error:', pushErr.message);
      }
    }

    let emailResult = null;
    try {
      emailResult = await mailService.sendOrderStatusUpdatedEmail({
        to: effectiveEmail,
        customerName: effectiveName,
        orderId: id,
        status,
        reason,
        items: effectiveItems,
        total: effectiveTotal,
        shippingAddress: effectiveAddress,
        phone: effectivePhone,
        paymentMethod: effectivePayment,
      });
    } catch (mailErr) {
      console.error('[OrdersAPI] Mail send error:', mailErr.message);
    }

    return res.json({
      success: true,
      message: 'Cập nhật trạng thái đơn hàng thành công, đã gửi email và thông báo!',
      emailSent: emailResult?.success ?? false,
    });
  } catch (error) {
    console.error('Order notify status error:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
}

app.post('/api/admin-orders/:id/status', handleAdminOrderStatus);
app.patch('/api/admin-orders/:id/status', handleAdminOrderStatus);
app.post('/api/orders/:id/notify-status', handleAdminOrderStatus);

// ==========================================
// ADMIN USER APIS (Qu?n l� Th�ng tin Ngu?i d�ng)
// ==========================================

// GET /api/admin-users
// L?y danh s�ch to�n b? ngu?i d�ng k�m th?ng k� s? l?ch h?n v� don h�ng
app.get('/api/admin-users', async (req, res) => {
  try {
    const { q, role } = req.query;
    let users = [];

    if (db.hasCredentials) {
      const snap = await db.collection('users').get();
      users = snap.docs.map(doc => ({
        id: doc.id,
        ...serialize(doc.data()),
      }));

      const [bookingsSnap, ordersSnap] = await Promise.all([
        db.collection('bookings').get(),
        db.collection('orders').get(),
      ]);

      const bookings = bookingsSnap.docs.map(d => ({ id: d.id, ...d.data() }));
      const orders = ordersSnap.docs.map(d => ({ id: d.id, ...d.data() }));

      users = users.map(user => {
        const uid = user.id || user.uid;
        const userBookings = bookings.filter(b => b.userId === uid);
        const userOrders = orders.filter(o => o.userId === uid);
        const totalSpent = userOrders
          .filter(o => !['cancelled', 'rejected'].includes((o.status || '').toLowerCase()))
          .reduce((sum, o) => sum + (Number(o.total) || 0), 0);

        return {
          ...user,
          bookingCount: userBookings.length,
          orderCount: userOrders.length,
          totalSpent,
        };
      });
    }

    users.sort((a, b) => {
      const dateA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
      const dateB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
      return dateB - dateA;
    });

    const stats = {
      totalUsers: users.length,
      activeUsers: users.filter(u => (u.bookingCount > 0 || u.orderCount > 0)).length,
      adminCount: users.filter(u => (u.role || '').toLowerCase() === 'admin').length,
      customerCount: users.filter(u => (u.role || '').toLowerCase() !== 'admin').length,
    };

    if (role && role !== 'all') {
      const r = role.toLowerCase();
      if (r === 'admin') {
        users = users.filter(u => (u.role || '').toLowerCase() === 'admin');
      } else if (r === 'user') {
        users = users.filter(u => (u.role || '').toLowerCase() !== 'admin');
      }
    }

    if (q && q.trim()) {
      const term = q.trim().toLowerCase();
      users = users.filter(u => {
        const nameMatch = (u.displayName || u.name || '').toLowerCase().includes(term);
        const emailMatch = (u.email || '').toLowerCase().includes(term);
        const phoneMatch = (u.phone || u.phoneNumber || '').toLowerCase().includes(term);
        const idMatch = (u.id || u.uid || '').toLowerCase().includes(term);
        return nameMatch || emailMatch || phoneMatch || idMatch;
      });
    }

    return res.json({
      success: true,
      count: users.length,
      stats,
      data: users,
    });
  } catch (err) {
    console.error('Error fetching admin users:', err);
    return res.status(500).json({ success: false, message: 'Kh�ng th? t?i danh s�ch ngu?i d�ng.' });
  }
});

// POST /api/admin-dev/clear-test-data
// D?n d?p don h�ng v� l?ch h?n th? nghi?m (reset test state)
app.post('/api/admin-dev/clear-test-data', async (req, res) => {
  try {
    const { target = 'all' } = req.body || {};
    let deletedOrders = 0;
    let deletedBookings = 0;

    if (db.hasCredentials) {
      if (target === 'all' || target === 'orders') {
        const ordersSnap = await db.collection('orders').get();
        for (const doc of ordersSnap.docs) {
          await doc.ref.delete();
          deletedOrders++;
        }
      }

      if (target === 'all' || target === 'bookings') {
        const bookingsSnap = await db.collection('bookings').get();
        for (const doc of bookingsSnap.docs) {
          await doc.ref.delete();
          deletedBookings++;
        }
      }
    }

    return res.json({
      success: true,
      message: `�� d?n d?p th�nh c�ng ${deletedOrders} don h�ng v� ${deletedBookings} l?ch h?n test!`,
      deletedOrders,
      deletedBookings,
    });
  } catch (err) {
    console.error('Error clearing test data:', err);
    return res.status(500).json({ success: false, message: 'L?i khi d?n d?p d? li?u test: ' + err.message });
  }
});


// Start server only when run directly.
if (require.main === module) {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`LUMI API running at http://localhost:${PORT}`);
  });
}

module.exports = app;
