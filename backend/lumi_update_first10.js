// LUMI SPA first 10: additive content update, dry-run by default.
const fs = require('fs');
const path = require('path');
const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
initializeApp({ credential: applicationDefault(), projectId: 'lumi-spa' });
const db = getFirestore();
const apply = process.argv.includes('--apply');
const items = JSON.parse(fs.readFileSync(path.join(__dirname,'LUMI_First10_Details.json'),'utf8'));
(async () => {
 if(items.length !== 10 || new Set(items.map(p=>p.id)).size !== 10) throw Error('Expected 10 unique products');
 let updated=0, skipped=0;
 for (const p of items) {
  const ref=db.collection('products').doc(p.id);
  const snap=await ref.get();
  if(!snap.exists) throw Error(`Missing ${p.id}`);
  const d=snap.data();
  if(d.name!==p.name || d.price!==p.expectedPrice) throw Error(`Mismatch ${p.id}: STOP`);
  const patch={};
  for(const k of ['descriptionLong','usageInstructions','suitableFor']) {
   if(!d[k]) patch[k]=p[k];
  }
  if(!Object.keys(patch).length){skipped++;console.log('SKIP '+p.id);continue;}
  console.log(`${apply?'UPDATE':'WOULD UPDATE'} ${p.id}: ${Object.keys(patch).join(', ')}`);
  if(apply) await db.runTransaction(async t=>{
   const fresh=await t.get(ref);
   if(!fresh.exists || fresh.data().name!==p.name || fresh.data().price!==p.expectedPrice) throw Error('Changed: '+p.id);
   const safe=Object.fromEntries(Object.entries(patch).filter(([k])=>!fresh.data()[k]));
   if(Object.keys(safe).length) t.update(ref,safe);
  });
  updated++;
 }
 console.log(`DONE: ${updated} ${apply?'processed':'would update'}, ${skipped} skipped. Images and discounts unchanged.`);
})().catch(e=>{console.error('FAILED:',e.message);process.exitCode=1;});
