
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

// Read active documents from Firestore.
async function getCollection(collectionName) {
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
