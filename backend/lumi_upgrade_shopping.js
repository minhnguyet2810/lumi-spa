const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp({
  credential: applicationDefault(),
  projectId: 'lumi-spa'
});

const db = getFirestore();
const apply = process.argv.includes('--apply');

async function main() {
  const snapshot = await db.collection('products').get();
  const products = snapshot.docs.filter(
    doc => /^lumi-\d{3}$/.test(doc.id)
  );

  console.log(`Found ${products.length} LUMI products`);

  if (products.length !== 50) {
    throw new Error('Expected 50 products. No changes made.');
  }

  let count = 0;

  for (const doc of products) {
    const data = doc.data();

    if (typeof data.price !== 'number' || data.price <= 0) {
      throw new Error(`Invalid price: ${doc.id}`);
    }
  }

  for (const doc of products) {
    const data = doc.data();

    const defaults = {
      originalPrice: data.price,
      salePrice: data.price,
      discountPercent: 0,
      promotionActive: false,
      promotionStartAt: null,
      promotionEndAt: null,
      descriptionLong: '',
      usageInstructions: '',
      suitableFor: ''
    };

    const missing = {};

    for (const [key, value] of Object.entries(defaults)) {
      if (!(key in data)) {
        missing[key] = value;
      }
    }

    if (Object.keys(missing).length > 0) {
      console.log(`${apply ? 'UPDATE' : 'DRY RUN'} ${doc.id}`);

      if (apply) {
        await db.runTransaction(async transaction => {
          const fresh = await transaction.get(doc.ref);
          if (!fresh.exists) throw new Error(`Missing: ${doc.id}`);
          const latest = fresh.data();
          const safe = Object.fromEntries(
            Object.entries(missing).filter(([key]) => !(key in latest))
          );
          if (Object.keys(safe).length) {
            transaction.update(doc.ref, safe);
          }
        });
      }

      count++;
    }
  }

  console.log(`DONE: ${count} products ${apply ? 'processed' : 'would be updated'}`);
}

main().catch(err => {
  console.error(err.message);
  process.exitCode = 1;
});
