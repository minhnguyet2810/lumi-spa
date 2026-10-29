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

// Start server only when run directly.
if (require.main === module) {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`LUMI API running at http://localhost:${PORT}`);
  });
}

module.exports = app;
