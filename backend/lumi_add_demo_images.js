const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp({
  credential: applicationDefault(),
  projectId: 'lumi-spa'
});

const db = getFirestore();
const apply = process.argv.includes('--apply');

const products = [
  ['lumi-001', 'Micellar Cleansing Water'],
  ['lumi-002', 'Pure Cleansing Oil'],
  ['lumi-003', 'Gentle Foam Cleanser'],
  ['lumi-004', 'Salicylic Gel Cleanser'],
  ['lumi-005', 'Enzyme Powder Wash'],
  ['lumi-006', 'Soothing Floral Toner'],
  ['lumi-007', 'Clarifying Pore Toner'],
  ['lumi-008', 'Microbiome Essence Toner'],
  ['lumi-009', 'Mineral Thermal Mist'],
  ['lumi-010', 'Micro-Peel Exfoliating Gel']
];

async function main() {
  const plans = [];

  for (const [id, name] of products) {
    const ref = db.collection('products').doc(id);
    const snap = await ref.get();

    if (!snap.exists) {
      throw new Error(`Missing product: ${id}`);
    }

    const imageUrl =
      'https://placehold.co/600x800/F8E9E7/805D60.png?text=' +
      encodeURIComponent('LUMI SPA\n' + name);

    plans.push({ ref, id, imageUrl });
  }

  for (const p of plans) {
    console.log(`${apply ? 'UPDATE' : 'DRY RUN'} ${p.id}`);

    if (apply) {
      await db.runTransaction(async tx => {
        const snap = await tx.get(p.ref);
        const images = snap.data().imageUrls;

        if (!Array.isArray(images) || images.length === 0) {
          tx.update(p.ref, {
            imageUrls: [p.imageUrl]
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
