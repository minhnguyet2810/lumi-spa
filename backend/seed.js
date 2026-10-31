const db = require('./firebase');
const { FieldValue } = require('firebase-admin/firestore');
const data = {
  categories: {
    facial: { name: 'Chăm sóc da', type: 'service', sortOrder: 1, isActive: true },
    massage: { name: 'Massage & thư giãn', type: 'service', sortOrder: 2, isActive: true },
    skincare: { name: 'Dưỡng da LUMI', type: 'product', sortOrder: 1, isActive: true },
  },
  services: {
    spa001: { name: 'Chăm sóc da cơ bản', description: 'Làm sạch và dưỡng ẩm cho da.', categoryId: 'facial', price: 350000, durationMinutes: 60, imageUrls: [], benefits: ['Làm sạch', 'Dưỡng ẩm'], isActive: true },
    spa002: { name: 'Massage thư giãn', description: 'Liệu trình thư giãn cơ thể.', categoryId: 'massage', price: 550000, durationMinutes: 90, imageUrls: [], benefits: ['Thư giãn'], isActive: true },
    spa003: { name: 'Chăm sóc da chuyên sâu', description: 'Liệu trình chăm sóc da chuyên sâu.', categoryId: 'facial', price: 650000, durationMinutes: 75, imageUrls: [], benefits: ['Chăm sóc chuyên sâu'], isActive: true },
  },
  products: {
    prd001: { name: 'LUMI Hydrating Serum', slug: 'lumi-hydrating-serum', description: 'Serum dưỡng ẩm (dữ liệu demo).', categoryId: 'skincare', price: 420000, stock: 25, imageUrls: [], ingredients: [], isActive: true },
    prd002: { name: 'LUMI Gentle Cleanser', slug: 'lumi-gentle-cleanser', description: 'Sữa rửa mặt dịu nhẹ (dữ liệu demo).', categoryId: 'skincare', price: 290000, stock: 30, imageUrls: [], ingredients: [], isActive: true },
  },
  banners: {
    home001: { title: 'The art of self-care', imageUrl: '', targetType: 'services', targetId: 'spa001', sortOrder: 1, isActive: true },
  },
};

async function main() {
  const batch = db.batch();
  let count = 0;
  for (const [collection, docs] of Object.entries(data)) {
    for (const [id, value] of Object.entries(docs)) {
      const ref = db.collection(collection).doc(id);
      batch.set(ref, {
        ...value,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      count++;
    }
  }
  await batch.commit();
  console.log(`Success: seeded ${count} documents into Firestore.`);
}
main().catch(err => { console.error('Seed failed:', err.message); process.exitCode = 1; });
