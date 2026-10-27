const fs = require('fs');
const path = require('path');
const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp({
  credential: applicationDefault(),
  projectId: 'lumi-spa'
});

const db = getFirestore();
const apply = process.argv.includes('--apply');

const jsonPath = path.join(__dirname, 'lumi_product_import', 'LUMI_Firestore_50_Products.json');
const products = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));

async function main() {
  const plans = [];

  for (const product of products) {
    const id = product.id;
    const ref = db.collection('products').doc(id);
    const snap = await ref.get();

    if (!snap.exists) {
      console.log(`Skipping missing product in Firestore: ${id}`);
      continue;
    }

    const imageUrl = product.imageUrl || (product.imageUrls && product.imageUrls[0]);
    if (!imageUrl) continue;

    plans.push({ ref, id, imageUrl, imageUrls: [imageUrl] });
  }

  for (const p of plans) {
    console.log(`${apply ? 'UPDATE' : 'DRY RUN'} ${p.id} -> ${p.imageUrl}`);

    if (apply) {
      await db.runTransaction(async tx => {
        const snap = await tx.get(p.ref);
        const data = snap.data();
        const images = data.imageUrls;

        if (!Array.isArray(images) || images.length === 0 || !data.imageUrl) {
          tx.update(p.ref, {
            imageUrl: p.imageUrl,
            imageUrls: p.imageUrls
          });
        }
      });
    }
  }

  console.log(`DONE: ${plans.length} products processed`);
}

main().catch(error => {
  console.error(error.message);
  process.exitCode = 1;
});
