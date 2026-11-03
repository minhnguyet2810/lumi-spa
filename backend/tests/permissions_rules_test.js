// Local Firestore Emulator only. Never connects to the LUMI production project.
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, getDocs, collection, query, where, updateDoc, serverTimestamp } = require('firebase/firestore');
let env;
before(async () => {
  const host = process.env.FIRESTORE_EMULATOR_HOST || '';
  assert.match(host, /^(localhost|127\.0\.0\.1):[0-9]+$/, 'Use a local emulator only');
  const [hostname, port] = host.split(':');
  env = await initializeTestEnvironment({ projectId: 'demo-lumi-permissions', firestore: { host: hostname, port: Number(port), rules: fs.readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8') } });
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    for (const [name, data] of Object.entries({
      'orders/alice-order': { userId: 'alice', status: 'pending', total: 350000 },
      'orders/bob-order': { userId: 'bob', status: 'pending', total: 450000 },
      'bookings/alice-booking': { userId: 'alice', status: 'pending' },
      'bookings/bob-booking': { userId: 'bob', status: 'pending' },
      'notifications/alice-note': { userId: 'alice', isRead: false, message: 'LUMI đã nhận thông tin' },
      'notifications/bob-note': { userId: 'bob', isRead: false },
      'users/alice': { uid: 'alice', email: 'alice@example.test', displayName: 'Alice', role: 'customer' },
      'users/bob': { uid: 'bob', email: 'bob@example.test', displayName: 'Bob' },
      'memberships/alice': { points: 100 }, 'memberships/bob': { points: 200 },
      'products/p1': { price: 350000 }, 'services/s1': { price: 400000 },
      'app_config/support': { phone: '0937011220' }, 'app_config/about_lumi': { title: 'LUMI' }, 'app_config/private': { value: 'private' },
      'articles/published': { isPublished: true }, 'articles/draft': { isPublished: false },
      'resource_slots/private': { bookingId: 'alice-booking' },
    })) await setDoc(doc(db, name), data);
  });
});
after(async () => { if (env) await env.cleanup(); });
const alice = () => env.authenticatedContext('alice', { email: 'alice@example.test' }).firestore();
const admin = () => env.authenticatedContext('manager', { admin: true }).firestore();
test('guest sees catalogue, public content/config; no private records', async () => {
  const db = env.unauthenticatedContext().firestore();
  for (const name of ['products/p1','services/s1','app_config/support','app_config/about_lumi','articles/published']) await assertSucceeds(getDoc(doc(db,name)));
  for (const name of ['orders/alice-order','bookings/alice-booking','users/alice','memberships/alice','notifications/alice-note','articles/draft','app_config/private']) await assertFails(getDoc(doc(db,name)));
});
test('customer may read own records, never another customer or unrestricted list', async () => {
  const db = alice();
  for (const [name, ownId, otherId] of [['orders','alice-order','bob-order'],['bookings','alice-booking','bob-booking'],['notifications','alice-note','bob-note']]) {
    await assertSucceeds(getDoc(doc(db,name,ownId))); await assertFails(getDoc(doc(db,name,otherId)));
    await assertSucceeds(getDocs(query(collection(db,name),where('userId','==','alice')))); await assertFails(getDocs(collection(db,name)));
  }
  await assertSucceeds(getDoc(doc(db,'users/alice'))); await assertFails(getDoc(doc(db,'users/bob')));
  await assertSucceeds(getDoc(doc(db,'memberships/alice'))); await assertFails(getDoc(doc(db,'memberships/bob')));
});
test('customer cannot forge transaction, status, price, role or points', async () => {
  const db = alice();
  await assertFails(setDoc(doc(db,'orders/forged'), {userId:'alice',total:1,status:'completed'}));
  await assertFails(updateDoc(doc(db,'orders/alice-order'), {status:'completed',total:1}));
  await assertFails(setDoc(doc(db,'bookings/forged'), {userId:'alice',status:'confirmed'}));
  await assertFails(updateDoc(doc(db,'users/alice'), {role:'admin'}));
  await assertFails(updateDoc(doc(db,'users/alice'), {admin:true}));
  await assertFails(updateDoc(doc(db,'users/alice'), {points:999999}));
  await assertFails(updateDoc(doc(db,'memberships/alice'), {points:999999}));
  await assertFails(setDoc(doc(db,'users/alice/roles/admin'), {admin:true}));
  await assertFails(updateDoc(doc(db,'products/p1'), {price:1}));
});
test('safe own profile and FCM fields remain editable; wrong uid/email create denied', async () => {
  const db = alice();
  await assertSucceeds(updateDoc(doc(db,'users/alice'), {displayName:'Updated',phone:'0937011220',updatedAt:serverTimestamp()}));
  await assertSucceeds(updateDoc(doc(db,'users/alice'), {fcmToken:'device-token',fcmTokens:['device-token'],fcmUpdatedAt:serverTimestamp()}));
  const fresh = env.authenticatedContext('new', {email:'new@example.test'}).firestore();
  await assertFails(setDoc(doc(fresh,'users/new'), {uid:'somebody-else',email:'new@example.test'}));
  await assertFails(setDoc(doc(fresh,'users/new'), {uid:'new',email:'spoof@example.test'}));
  await assertFails(setDoc(doc(fresh,'users/new'), {uid:'new',role:'admin'}));
  await assertSucceeds(setDoc(doc(fresh,'users/new'), {uid:'new',email:'new@example.test',displayName:'New',createdAt:serverTimestamp()}));
});
test('customer can only mark own notification read; cannot forge message/recipient', async () => {
  const db = alice();
  await assertSucceeds(updateDoc(doc(db,'notifications/alice-note'), {isRead:true,readAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(db,'notifications/alice-note'), {message:'Fake'}));
  await assertFails(updateDoc(doc(db,'notifications/alice-note'), {userId:'bob'}));
  await assertFails(updateDoc(doc(db,'notifications/bob-note'), {isRead:true}));
  await assertFails(setDoc(doc(db,'notifications/fake'), {userId:'alice',isRead:false}));
});
test('published query works; draft and unknown paths stay private', async () => {
  const db = alice();
  await assertSucceeds(getDocs(query(collection(db,'articles'),where('isPublished','==',true))));
  await assertFails(getDocs(collection(db,'articles')));
  await assertFails(getDoc(doc(db,'resource_slots/private')));
  await assertFails(setDoc(doc(db,'unknown/path'),{value:true}));
});
test('admin claim reads all operational records; mutations still require backend transactions', async () => {
  const db = admin();
  for (const name of ['orders','bookings','users','notifications','articles']) await assertSucceeds(getDocs(collection(db,name)));
  await assertSucceeds(updateDoc(doc(db,'products/p1'),{price:350000}));
  await assertFails(updateDoc(doc(db,'orders/alice-order'),{status:'confirmed'}));
  await assertFails(updateDoc(doc(db,'bookings/alice-booking'),{status:'confirmed'}));
  const impostor = env.authenticatedContext('alice',{admin:'true'}).firestore();
  await assertFails(getDoc(doc(impostor,'users/bob')));
});
