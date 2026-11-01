const path = require('path');
const fs = require('fs');
const db = require('../firebase');

const serviceImages = {
  spa001: 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=900&auto=format&fit=crop',
  spa002: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=900&auto=format&fit=crop',
  spa003: 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?w=900&auto=format&fit=crop',
  spa004: 'https://images.unsplash.com/photo-1519823551278-64ac92734fb1?w=900&auto=format&fit=crop',
  spa005: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=900&auto=format&fit=crop',
  spa006: 'https://images.unsplash.com/photo-1512290903671-17adc81fcd90?w=900&auto=format&fit=crop',
  spa007: 'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?w=900&auto=format&fit=crop',
  spa008: 'https://images.unsplash.com/photo-1600334089648-b0d9d3028eb2?w=900&auto=format&fit=crop',
  spa009: 'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=900&auto=format&fit=crop',
  spa010: 'https://images.unsplash.com/photo-1519824145371-296894a0dc91?w=900&auto=format&fit=crop',
  spa011: 'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?w=900&auto=format&fit=crop',
  spa012: 'https://images.unsplash.com/photo-1519823551278-64ac92734fb1?w=900&auto=format&fit=crop',
  spa013: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=900&auto=format&fit=crop',
  spa014: 'https://images.unsplash.com/photo-1507652313519-d4e9174996dd?w=900&auto=format&fit=crop',
  spa015: 'https://images.unsplash.com/photo-1515377905703-c4788e51af15?w=900&auto=format&fit=crop',
  spa016: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=900&auto=format&fit=crop',
  spa017: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=900&auto=format&fit=crop',
  spa018: 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?w=900&auto=format&fit=crop',
  spa019: 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=900&auto=format&fit=crop',
  spa020: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=900&auto=format&fit=crop',
};

const extraProductImages = {
  prd001: 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?w=900&auto=format&fit=crop',
  prd002: 'https://images.unsplash.com/photo-1556229010-6c3f2c9ca5f8?w=900&auto=format&fit=crop',
};

async function updateAllImages() {
  console.log('--- 1. Cập nhật ảnh cho tất cả Products trên Firestore ---');
  const jsonPath = path.join(__dirname, '..', 'lumi_product_import', 'LUMI_Firestore_50_Products.json');
  const rawProducts = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));

  const productMap = {};
  for (const p of rawProducts) {
    productMap[p.id] = p.imageUrl || (p.imageUrls && p.imageUrls[0]);
  }
  Object.assign(productMap, extraProductImages);

  const productSnap = await db.collection('products').get();
  console.log(`Tìm thấy ${productSnap.size} sản phẩm trong collection products.`);

  const batchSize = 100;
  let batch = db.batch();
  let count = 0;
  let updatedProducts = 0;

  for (const doc of productSnap.docs) {
    const id = doc.id;
    const data = doc.data();
    const targetUrl = productMap[id] || productMap[id.toLowerCase()] || 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?w=900&auto=format&fit=crop';

    const currentUrl = data.imageUrl;
    const currentList = data.imageUrls;

    // Cập nhật nếu chưa có ảnh hoặc ảnh chưa phải URL hợp lệ
    const needsUpdate = !currentUrl || !currentUrl.startsWith('http') || !Array.isArray(currentList) || currentList.length === 0;

    if (needsUpdate || currentUrl !== targetUrl) {
      batch.update(doc.ref, {
        imageUrl: targetUrl,
        imageUrls: [targetUrl],
      });
      updatedProducts++;
      count++;
    }

    if (count >= batchSize) {
      await batch.commit();
      batch = db.batch();
      count = 0;
    }
  }

  if (count > 0) {
    await batch.commit();
  }
  console.log(`Đã cập nhật ảnh cho ${updatedProducts}/${productSnap.size} sản phẩm.`);

  console.log('\n--- 2. Cập nhật ảnh cho tất cả Services trên Firestore ---');
  const serviceSnap = await db.collection('services').get();
  console.log(`Tìm thấy ${serviceSnap.size} dịch vụ trong collection services.`);

  let sBatch = db.batch();
  let sCount = 0;
  let updatedServices = 0;

  for (const doc of serviceSnap.docs) {
    const id = doc.id;
    const data = doc.data();
    const targetUrl = serviceImages[id] || 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=900&auto=format&fit=crop';

    const currentUrl = data.imageUrl;
    const currentList = data.imageUrls;

    const needsUpdate = !currentUrl || !currentUrl.startsWith('http') || !Array.isArray(currentList) || currentList.length === 0;

    if (needsUpdate || currentUrl !== targetUrl) {
      sBatch.update(doc.ref, {
        imageUrl: targetUrl,
        imageUrls: [targetUrl],
      });
      updatedServices++;
      sCount++;
    }

    if (sCount >= batchSize) {
      await sBatch.commit();
      sBatch = db.batch();
      sCount = 0;
    }
  }

  if (sCount > 0) {
    await sBatch.commit();
  }
  console.log(`Đã cập nhật ảnh cho ${updatedServices}/${serviceSnap.size} dịch vụ spa.`);
  console.log('\n=== HOÀN TẤT CẬP NHẬT ĐẦY ĐỦ ẢNH SẢN PHẨM & DỊCH VỤ ===');
}

updateAllImages().catch(err => {
  console.error('Lỗi cập nhật ảnh:', err);
  process.exit(1);
});

