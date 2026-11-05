// Isolated tests: no credentials, real FCM or production data.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const express = require('express');
const request = require('supertest');
function harness() {
  const records = new Map(); const pushes = [];
  const snap = ref => ({ id: ref.id, ref, exists: records.has(ref.path), data: () => records.get(ref.path) });
  function collection(name, filters = []) {
    const query = {
      doc(id) {
        const ref = { id, path: `${name}/${id}` };
        ref.get = async () => snap(ref);
        ref.set = async data => records.set(ref.path, data);
        ref.delete = async () => records.delete(ref.path);
        ref.collection = sub => collection(`${ref.path}/${sub}`);
        return ref;
      },
      where(field, op, value) { return collection(name,[...filters, d => op === '==' ? d[field] === value : op === '>' ? Number(d[field]) > Number(value) : Number(d[field]) <= Number(value)]); },
      async get() {
        const docs = [...records].filter(([k,v]) => k.slice(0,k.lastIndexOf('/')) === name && filters.every(f => f(v)))
          .map(([k]) => snap(query.doc(k.slice(name.length+1))));
        return { docs, size: docs.length, empty: docs.length === 0 };
      },
    }; return query;
  }
  let tail = Promise.resolve();
  const db = { hasCredentials: true, collection,
    runTransaction(fn) {
      const execute = async () => {
        const ops=[];
        const result = await fn({ get: async ref => ref.get(),
          create: (ref,data) => ops.push(() => { assert.equal(records.has(ref.path), false); records.set(ref.path,data); }),
          set: (ref,data) => ops.push(() => records.set(ref.path,data)),
        }); ops.forEach(op => op()); return result;
      };
      const result = tail.then(execute); tail = result.catch(() => {}); return result;
    },
  };
  const field = { FieldValue: { serverTimestamp: () => new Date() }, Timestamp: { fromDate: d => d } };
  function load(file, extra) {
    const module = { exports:{} };
    const req = name => {
      if (name === '../firebase') return db;
      if (name === 'firebase-admin/firestore') return field;
      if (name === '../auth') return { requireAuth: (req,res,next) => {
        const token = req.headers.authorization;
        if (!['Bearer alice','Bearer bob','Bearer admin','Bearer stringAdmin'].includes(token)) return res.status(401).json({success:false});
        req.user = { uid: token.slice(7), admin: token === 'Bearer admin' ? true : token === 'Bearer stringAdmin' ? 'true' : false }; next();
      } };
      if (name === '../admin_auth') return { requireAdmin: (req,res,next) => req.user.admin === true ? next() : res.status(403).json({success:false}) };
      if (name === '../services/experience_service') return extra;
      return require(name);
    };
    vm.runInNewContext(fs.readFileSync(file,'utf8'),{ module, exports:module.exports, require:req, console },{filename:file});return module.exports;
  }
  const service=load(path.join(__dirname,'../services/experience_service.js'));
  const router=load(path.join(__dirname,'../routes/experience.js'),service);
  const app=express();app.use(express.json());app.use(router);
  return { records,db,service,pushes,app, push: async message => pushes.push(message) };
}
const api=(h, method, url, body, token='alice') => request(h.app)[method](url).set('Authorization',`Bearer ${token}`).send(body);
test('all experience endpoints require a session; dashboard requires boolean admin', async () => {
  const h=harness();
  for (const [method,url] of [['get','/preferences'],['put','/preferences'],['get','/favorites'],['put','/favorites/product/p1'],['delete','/favorites/product/p1'],['get','/history'],['get','/rebook/b1'],['post','/reviews'],['get','/reviews/product/p1'],['get','/dashboard']]) {
    assert.equal((await request(h.app)[method](url).send({})).status,401);
  }
  for (const token of ['alice','stringAdmin']) assert.equal((await api(h,'get','/dashboard',null,token)).status,403);
});
test('favorites are owner scoped, idempotent and sourced from current catalogue',async () => {
  const h=harness();h.records.set('products/p1',{name:'Cleanser',price:200});
  assert.equal((await api(h,'put','/favorites/product/p1',{userId:'bob',price:1})).status,200);
  assert.equal((await api(h,'put','/favorites/product/p1',{})).status,200);
  const own=await api(h,'get','/favorites');assert.equal(own.body.data.length,1);assert.equal(own.body.data[0].item.price,200);
  assert.equal((await api(h,'get','/favorites',null,'bob')).body.data.length,0);
  await api(h,'delete','/favorites/product/p1',null,'bob');assert.equal((await api(h,'get','/favorites')).body.data.length,1);
  assert.equal((await api(h,'put','/favorites/user/p1',{})).status,400);
  h.records.delete('products/p1');assert.equal((await api(h,'get','/favorites')).body.data[0].available,false);
  assert.equal((await api(h,'delete','/favorites/product/p1')).status,200);
});
test('rebooking denies another owner and inactive service, returns fresh price without creating booking',async () => {
  const h=harness();h.records.set('bookings/b1',{userId:'alice',serviceId:'s1',price:1});h.records.set('services/s1',{price:900});
  assert.equal((await api(h,'get','/rebook/b1',null,'bob')).status,404);
  const r=await api(h,'get','/rebook/b1');assert.equal(r.body.data.price,900);assert.equal(r.body.data.id,'s1');
  assert.equal([...h.records.keys()].filter(k=>k.startsWith('bookings/')).length,1);
  h.records.set('services/s1',{isActive:false});assert.equal((await api(h,'get','/rebook/b1')).status,409);
});
test('reviews reject uncompleted, forged target and other owner; duplicates rejected atomically',async () => {
  const h=harness();h.records.set('bookings/b1',{userId:'alice',serviceId:'s1',status:'pending'});
  const body={sourceType:'booking',sourceId:'b1',targetId:'s1',rating:5,comment:'Great'};
  assert.equal((await api(h,'post','/reviews',body)).status,403);
  h.records.set('bookings/b1',{userId:'alice',serviceId:'s1',status:'completed'});
  assert.equal((await api(h,'post','/reviews',body,'bob')).status,404);
  assert.equal((await api(h,'post','/reviews',{...body,targetId:'s2'})).status,403);
  const results=await Promise.all([api(h,'post','/reviews',body),api(h,'post','/reviews',body)]);
  assert.deepEqual(results.map(r=>r.status).sort(),[201,409]);
  const list=await api(h,'get','/reviews/service/s1');assert.equal(list.body.data.average,5);
  assert.equal('userId' in list.body.data.reviews[0],false);assert.equal('sourceId' in list.body.data.reviews[0],false);
  assert.equal((await api(h,'get','/history')).body.data[0].canReview,false);
});
test('product reviews require a completed order containing that product; validate input',async () => {
  const h=harness();h.records.set('orders/o1',{userId:'alice',status:'completed',items:[{productId:'p1',name:'Cleanser'}]});
  const body={sourceType:'order',sourceId:'o1',targetId:'p1',rating:4,comment:'Nice'};
  for (const patch of [{rating:0},{rating:6},{rating:2.5},{rating:'5'},{comment:'x'.repeat(1001)}]) assert.equal((await api(h,'post','/reviews',{...body,...patch})).status,400);
  assert.equal((await api(h,'post','/reviews',{...body,targetId:'p2'})).status,403);
  assert.equal((await api(h,'post','/reviews',body)).status,201);
});
test('reminder opt-in is account scoped and validated',async () => {
  const h=harness();assert.equal((await api(h,'get','/preferences')).body.data.remindersEnabled,false);
  assert.equal((await api(h,'put','/preferences',{remindersEnabled:'true'})).status,400);
  await api(h,'put','/preferences',{remindersEnabled:true,userId:'bob'});
  assert.equal((await api(h,'get','/preferences',null,'bob')).body.data.remindersEnabled,false);
});
test('reminders only for opted-in confirmed future bookings; duplicate workers create one inbox event/push',async () => {
  const h=harness();const now=new Date('2026-11-05T02:00:00Z');
  h.records.set('experience_preferences/alice',{remindersEnabled:true});
  for(const [id,status,minutes,userId] of [['yes','confirmed',30,'alice'],['pending','pending',30,'alice'],['cancelled','cancelled',30,'alice'],['past','confirmed',-5,'alice'],['late','confirmed',90,'alice'],['off','confirmed',30,'bob']]) h.records.set('bookings/'+id,{userId,status,serviceName:'Spa',startAt:new Date(now.getTime()+minutes*60000)});
  await Promise.all([h.service.runReminders(h.db,h.push,now),h.service.runReminders(h.db,h.push,now)]);
  assert.equal(h.pushes.length,1);assert.equal(h.pushes[0].data.bookingId,'yes');
  assert.equal([...h.records.keys()].filter(k=>k.startsWith('notifications/')).length,1);
  await h.service.runReminders(h.db,h.push,now);assert.equal(h.pushes.length,1);
  for (const k of h.records.keys()) if (k.startsWith('notifications/')) h.records.delete(k);
  await h.service.runReminders(h.db,h.push,now);assert.equal(h.pushes.length,1);
  // Rescheduled confirmed appointment receives its own reminder.
  h.records.set('bookings/yes',{userId:'alice',status:'confirmed',startAt:new Date(now.getTime()+40*60000)});
  await h.service.runReminders(h.db,h.push,now);assert.equal(h.pushes.length,2);
});
test('push failure preserves inbox and does not duplicate it; storage failure fails closed',async () => {
  const h=harness(), now=new Date('2026-11-05T02:00:00Z');
  h.records.set('experience_preferences/alice',{remindersEnabled:true});h.records.set('bookings/b1',{userId:'alice',status:'confirmed',startAt:new Date(now.getTime()+60000)});
  await h.service.runReminders(h.db,async()=>{throw new Error('offline');},now);
  assert.equal([...h.records.keys()].filter(k=>k.startsWith('notifications/')).length,1);
  await h.service.runReminders(h.db,h.push,now);assert.equal(h.pushes.length,0);
  h.db.hasCredentials=false;assert.equal((await api(h,'get','/history')).status,503);
});
test('dashboard uses Vietnam day and completed order value only',async () => {
  const h=harness();h.records.set('orders/yes',{status:'completed',total:200});h.records.set('orders/no',{status:'cancelled',total:999});h.records.set('orders/wait',{status:'pending',total:800});
  const r=await api(h,'get','/dashboard',null,'admin');assert.equal(r.status,200);assert.equal(r.body.data.completedOrderValue,200);assert.equal(r.body.data.pendingOrders,1);assert.match(r.body.data.today,/^\d{4}-\d{2}-\d{2}$/);
});
test('favorites cap is enforced atomically; existing favorite can still be updated',async () => {
  const h=harness();
  h.records.set('products/p1',{name:'Cleanser'});
  for(let i=0;i<200;i++) h.records.set(`experience_favorites/alice/items/${h.service.key('product','p'+i)}`,{type:'product',targetId:'p'+i});
  assert.equal((await api(h,'put','/favorites/product/p1',{})).status,200);
  h.records.set('products/new',{name:'New'});
  assert.equal((await api(h,'put','/favorites/product/new',{})).status,409);
});
