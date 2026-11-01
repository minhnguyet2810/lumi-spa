// No credentials, production data or outgoing mail used by these isolated tests.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const request = require('supertest');
function harness() {
  const records = new Map(); let count = 0;
  const snap = ref => ({ id: ref.id, exists: records.has(ref.path), ref, data: () => records.get(ref.path) });
  function collection(name, filters = []) {
    return {
      doc(id = `id_${++count}`) {
        const ref = { id, path: `${name}/${id}` };
        ref.get = async () => snap(ref);
        ref.update = async data => records.set(ref.path, { ...records.get(ref.path), ...data });
        ref.set = async (data, options) => records.set(ref.path, { ...(options?.merge ? records.get(ref.path) : {}), ...data });
        return ref;
      },
      where(field, op, value) { return collection(name, [...filters, d => d[field] === value]); },
      limit() { return this; },
      async get() {
        const docs = [...records].filter(([k, v]) => k.startsWith(`${name}/`) && filters.every(f => f(v))).map(([k]) => snap(this.doc(k.slice(name.length + 1))));
        return { docs, size: docs.length, empty: !docs.length };
      },
      async add(data) { const ref = this.doc(); records.set(ref.path, data); return ref; },
    };
  }
  const db = { hasCredentials: true, collection, async runTransaction(fn) {
    const writes = [];
    const result = await fn({ get: async ref => snap(ref), getAll: async (...refs) => refs.map(snap),
      create: (ref, data) => writes.push(() => records.set(ref.path, data)),
      update: (ref, data) => writes.push(() => {
        const old = records.get(ref.path) || {};
        const values = Object.fromEntries(Object.entries(data).map(([k, v]) => [k, v?.inc !== undefined ? (old[k] || 0) + v.inc : v]));
        records.set(ref.path, { ...old, ...values });
      }), delete: ref => writes.push(() => records.delete(ref.path)),
    }); writes.forEach(f => f()); return result;
  } };
  const identities = { customer: { uid: 'alice', email: 'alice@example.test' }, admin: { uid: 'manager', admin: true }, stringAdmin: { uid: 'alice', admin: 'true' } };
  const cache = new Map();
  function load(filename) {
    if (cache.has(filename)) return cache.get(filename).exports;
    const module = { exports: {} }; cache.set(filename, module);
    const localRequire = name => {
      if (name === 'firebase-admin/auth') return { getAuth: () => ({ verifyIdToken: async (token, checkRevoked) => {
        assert.equal(checkRevoked, true);
        if (!identities[token]) throw new Error('INVALID_OR_REVOKED_TOKEN');
        return identities[token];
      } }) };
      if (name === 'firebase-admin/firestore') return { FieldValue: { serverTimestamp: () => new Date().toISOString(), increment: inc => ({ inc }) }, Timestamp: { fromDate: date => ({ toDate: () => date, toMillis: () => date.getTime() }) } };
      if (name.endsWith('/firebase')) return db;
      if (name.includes('services/mail_service') || name.includes('services/push_service')) return new Proxy({}, { get: () => async () => ({ success: true }) });
      if (name.startsWith('.')) return load(path.resolve(path.dirname(filename), name.endsWith('.js') ? name : `${name}.js`));
      return require(name);
    };
    vm.runInThisContext(`(function(require,module,exports,__dirname,process){${fs.readFileSync(filename, 'utf8')}\n})`, { filename })(localRequire, module, module.exports, path.dirname(filename), { env: { ...process.env, LUMI_ALLOW_TEST_RESET: 'false' }, on() {} });
    return module.exports;
  }
  return { app: load(path.resolve(__dirname, '../server.js')), records, db };
}
const adminPaths = [
  ['get','/api/admin/health'], ['get','/api/admin/bookings'], ['get','/api/admin/orders'], ['get','/api/admin/users'],
  ['get','/api/admin-bookings'], ['post','/api/admin-bookings/x/status'], ['patch','/api/admin-bookings/x/status'],
  ['patch','/api/admin/bookings/x/confirm'], ['patch','/api/admin/bookings/x/reject'],
  ['get','/api/admin-orders'], ['get','/api/admin-orders/x'], ['post','/api/admin-orders/x/status'], ['patch','/api/admin-orders/x/status'],
  ['post','/api/orders/x/notify-status'], ['get','/api/admin-users'], ['post','/api/admin-dev/clear-test-data'],
];
test('every admin route and alias rejects missing/forged/customer/non-boolean admin tokens', async () => {
  const h = harness();
  const forged = `e30.${Buffer.from(JSON.stringify({ uid:'manager', admin:true })).toString('base64url')}.invalid`;
  for (const [method,url] of adminPaths) for (const [token,status] of [[null,401],[forged,401],['customer',403],['stringAdmin',403]]) {
    let req = request(h.app)[method](url); if (token) req = req.set('Authorization',`Bearer ${token}`);
    assert.equal((await req.send({status:'confirmed'})).status,status,`${method} ${url}`);
  }
});
test('valid admin allowed; absent storage cannot bypass claim check',async () => {
  const h=harness(); assert.equal((await request(h.app).get('/api/admin/health').set('Authorization','Bearer admin')).status,200);
  h.db.hasCredentials=false; assert.equal((await request(h.app).get('/api/admin-users').set('Authorization','Bearer customer')).status,403);
});
test('customer lists own orders only; other owner detail/cancellation denied',async () => {
  const h=harness(); h.records.set('orders/private',{userId:'bob',status:'pending',items:[]});
  const list=await request(h.app).get('/api/orders').set('Authorization','Bearer customer');
  assert.equal(list.status,200); assert.deepEqual(list.body.data,[]);
  for(const [method,url] of [['get','/api/orders/private'],['patch','/api/orders/private/cancel']]) assert.equal((await request(h.app)[method](url).set('Authorization','Bearer customer')).status,404);
  assert.equal(h.records.get('orders/private').status,'pending');
});
test('checkout ignores forged owner/price/paid status, supports bank; cancellation restores stock once',async () => {
  const h=harness();h.records.set('products/p1',{name:'Cleanser',price:200000,stock:5,isActive:true});
  const res=await request(h.app).post('/api/orders').set('Authorization','Bearer customer').send({items:[{productId:'p1',quantity:2,price:1}],total:2,userId:'bob',status:'completed',paymentStatus:'paid',phone:'0937011220',shippingAddress:'279 Nguyễn Tri Phương',customerName:'Alice',paymentMethod:'bank'});
  assert.equal(res.status,201);const order=h.records.get(`orders/${res.body.data.id}`);
  assert.equal(order.userId,'alice');assert.equal(order.total,430000);assert.equal(order.paymentStatus,'unpaid');assert.equal(order.status,'pending');assert.equal(order.paymentMethod,'Chuyển khoản ngân hàng');assert.equal(h.records.get('products/p1').stock,3);
  const url=`/api/orders/${res.body.data.id}/cancel`;
  assert.equal((await request(h.app).patch(url).set('Authorization','Bearer customer')).status,200);assert.equal(h.records.get('products/p1').stock,5);
  assert.equal((await request(h.app).patch(url).set('Authorization','Bearer customer')).status,409);assert.equal(h.records.get('products/p1').stock,5);
});
test('historical client orders cannot inflate inventory',async () => {
  const h=harness();h.records.set('products/p1',{stock:5});h.records.set('orders/old',{userId:'alice',status:'pending',items:[{productId:'p1',quantity:20}]});
  assert.equal((await request(h.app).patch('/api/orders/old/cancel').set('Authorization','Bearer customer')).status,200);assert.equal(h.records.get('products/p1').stock,5);
});
test('other owner booking cancellation and notification read are denied',async () => {
  const h=harness();h.records.set('bookings/private',{userId:'bob',status:'pending',startAt:{toMillis:()=>Date.now()+999999}});h.records.set('notifications/private',{userId:'bob',isRead:false});
  assert.equal((await request(h.app).patch('/api/bookings/private/cancel').set('Authorization','Bearer customer')).status,400);
  assert.equal((await request(h.app).patch('/api/notifications/private/read').set('Authorization','Bearer customer')).status,404);
  assert.equal(h.records.get('bookings/private').status,'pending');assert.equal(h.records.get('notifications/private').isRead,false);
});
test('profile cannot self-assign role/admin/points',async () => {
  const h=harness();h.records.set('users/alice',{displayName:'Old'});const res=await request(h.app).patch('/api/me').set('Authorization','Bearer customer').send({displayName:'Alice',role:'admin',admin:true,points:99999});
  assert.equal(res.status,200);const profile=h.records.get('users/alice');assert.equal(profile.displayName,'Alice');for(const key of ['role','admin','points'])assert.equal(profile[key],undefined);
});
test('terminal orders cannot be resurrected by admin and reset is off by default',async () => {
  const h=harness();h.records.set('orders/done',{userId:'alice',status:'completed',items:[]});
  assert.equal((await request(h.app).post('/api/admin-orders/done/status').set('Authorization','Bearer admin').send({status:'pending'})).status,400);
  assert.equal((await request(h.app).post('/api/admin-orders/done/status').set('Authorization','Bearer admin').send({status:'confirmed'})).status,409);
  assert.equal((await request(h.app).post('/api/admin-dev/clear-test-data').set('Authorization','Bearer admin').send({})).status,403);
});
test('booking trusts catalogue, refuses absent service, and never returns mock success on database failure',async () => {
  const h=harness();
  const tomorrow=new Date(Date.now()+86400000).toISOString().slice(0,10);
  const body={serviceId:'s1',date:tomorrow,hour:10,contactName:'Alice',contactPhone:'0937011220',price:1,durationMinutes:1};
  let res=await request(h.app).post('/api/bookings').set('Authorization','Bearer customer').send(body);
  assert.equal(res.status,404);
  h.records.set('services/s1',{name:'Facial',price:400000,durationMinutes:60,categoryId:'facial',isActive:true});
  h.db.runTransaction=async()=>{throw new Error('DB_OFFLINE');};
  res=await request(h.app).post('/api/bookings').set('Authorization','Bearer customer').send(body);
  // Resource lookup may fail first; either case must be an error, never a dev success.
  assert.ok(res.status>=400);assert.notEqual(res.status,201);
  assert.equal([...h.records.keys()].filter(k=>k.startsWith('bookings/')).length,0);
  h.db.hasCredentials=false;
  assert.equal((await request(h.app).post('/api/bookings').set('Authorization','Bearer customer').send(body)).status,503);
  assert.equal((await request(h.app).get(`/api/bookings/slots?date=${tomorrow}&serviceId=s1`)).status,503);
});
test('legacy approve/reject aliases use canonical resource-lock transaction',async () => {
  const h=harness();const future={toMillis:()=>Date.now()+86400000,toDate:()=>new Date(Date.now()+86400000)};
  for(const [id,status] of [['approve','approved'],['reject','rejected']]) {
    h.records.set(`bookings/${id}`,{userId:'alice',status:'pending',staffId:'s',roomId:'r',resourceSlotIds:[id],startAt:future});
    h.records.set(`resource_slots/${id}`,{bookingId:id});
    const res=await request(h.app).post(`/api/admin-bookings/${id}/status`).set('Authorization','Bearer admin').send({status});
    assert.equal(res.status,200);
    assert.equal(h.records.get(`bookings/${id}`).status,status==='approved'?'confirmed':'cancelled');
    if(status==='rejected')assert.equal(h.records.has(`resource_slots/${id}`),false);
  }
});
