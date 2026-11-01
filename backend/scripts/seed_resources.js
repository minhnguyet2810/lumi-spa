const db = require('../firebase');

const staff = [
  { id: 'staff01', name: 'Linh', categories: ['facial'], isActive: true },
  { id: 'staff02', name: 'Hà', categories: ['facial'], isActive: true },
  { id: 'staff03', name: 'An', categories: ['relaxation', 'body'], isActive: true },
  { id: 'staff04', name: 'Mai', categories: ['relaxation', 'body'], isActive: true },
  { id: 'staff05', name: 'Vy', categories: ['beauty', 'body'], isActive: true },
];

const rooms = [
  { id: 'room01', name: 'Facial 1', categories: ['facial'], isActive: true },
  { id: 'room02', name: 'Facial 2', categories: ['facial'], isActive: true },
  { id: 'room03', name: 'Massage 1', categories: ['relaxation', 'body'], isActive: true },
  { id: 'room04', name: 'Massage 2', categories: ['relaxation', 'body'], isActive: true },
  { id: 'room05', name: 'Beauty Room', categories: ['beauty', 'body'], isActive: true },
];

async function seed(collection, records) {
  for (const { id, ...data } of records) {
    const ref = db.collection(collection).doc(id);
    const result = await db.runTransaction(async tx => {
      const doc = await tx.get(ref);
      if (doc.exists) return 'SKIPPED';
      tx.create(ref, data);
      return 'CREATED';
    });
    console.log(`${collection}/${id}: ${result}`);
  }
}

async function main() {
  const services = await db.collection('services').get();
  const categories = [...new Set(
    services.docs.map(d => d.data().categoryId).filter(Boolean)
  )];
  console.log('Actual service category IDs:', JSON.stringify(categories));

  const supported = new Set(staff.flatMap(x => x.categories));
  const unmatched = categories.filter(x => !supported.has(x));

  if (unmatched.length) {
    console.error('STOP: Unmapped categories:', unmatched.join(', '));
    console.error('No Staff or Rooms were created. Update category mapping first.');
    process.exitCode = 1;
    return;
  }

  await seed('staff', staff);
  await seed('rooms', rooms);
  console.log('Resource seed completed.');
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
