// Safe, create-only Firestore import. Run from backend/ with firebase-admin installed.
// Requires GOOGLE_APPLICATION_CREDENTIALS pointing to a service-account JSON.
const fs = require('fs');
const path = require('path');
const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const apply = process.argv.includes('--apply');
const projectId = 'lumi-spa';
const products = JSON.parse(fs.readFileSync(path.join(__dirname, 'LUMI_Firestore_50_Products.json'), 'utf8'));
if (!Array.isArray(products) || products.length !== 50 || new Set(products.map(p => p.id)).size !== 50) {
  throw new Error('Expected 50 products with unique IDs.');
}
for (const p of products) {
  if (!/^lumi-\d{3}$/.test(p.id) || !p.name || !Number.isInteger(p.price) || p.price <= 0) {
    throw new Error(`Invalid product: ${JSON.stringify(p)}`);
  }
}
console.log(`Validated ${products.length} products for project ${projectId}.`);
if (!apply) {
  console.log('DRY RUN ONLY. No Firebase writes. To create missing docs, use --apply.');
  process.exit(0);
}
initializeApp({credential: applicationDefault(), projectId});
const db = getFirestore();
(async () => {
  const actualProject = 'lumi-spa';
  if (actualProject !== projectId) throw new Error(`Wrong Firebase project: ${actualProject}`);
  let created = 0, skipped = 0;
  for (const p of products) {
    const {id, ...fields} = p;
    try {
      await db.collection('products').doc(id).create(fields); // never overwrite
      created++;
      console.log(`CREATED ${id}: ${p.name}`);
    } catch (err) {
      if (err.code === 6 || err.code === 'already-exists') {
        skipped++;
        console.log(`SKIPPED existing ${id}`);
      } else throw err;
    }
  }
  console.log(`DONE: ${created} created, ${skipped} already existed. Other products untouched.`);
})().catch(e => {console.error('Import failed:', e.message); process.exitCode = 1;});
