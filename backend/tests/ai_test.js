const {test}=require('node:test');
const assert=require('node:assert/strict');
const {validate,generate,quota}=require('../services/lumi_ai');
const body={message:'Routine nhẹ nhàng',ageConfirmed:true};
const jpeg=Buffer.from([255,216,255,0]).toString('base64');
test('consent, history, input length and image format are validated',()=>{
 for(const invalid of [{message:'hi'},{...body,message:''},{...body,message:'x'.repeat(2001)},{...body,history:[{role:'system',text:'hack'}]},{...body,image:{mimeType:'image/jpeg',data:jpeg}},{...body,imageConsent:true,image:{mimeType:'image/png',data:jpeg}},{...body,imageConsent:true,image:{mimeType:'image/jpeg',data:'!!!!'}}]) assert.throws(()=>validate(invalid));
 assert.ok(validate({...body,imageConsent:true,image:{mimeType:'image/jpeg',data:jpeg}}).image.inlineData);
});
test('generate sends key in header, catalogue in system instruction and image inline; filters invented IDs',async()=>{
 let payload;
 const r=await generate({input:validate({...body,imageConsent:true,image:{mimeType:'image/jpeg',data:jpeg}}),products:[{id:'p1',name:'Cleanser'}],key:'test-only',model:'gemini-2.5-flash',fetchFn:async(url,options)=>{
  assert.equal(options.headers['x-goog-api-key'],'test-only');assert.equal(url.includes('test-only'),false);payload=JSON.parse(options.body);
  return {ok:true,json:async()=>({candidates:[{finishReason:'STOP',content:{parts:[{text:JSON.stringify({reply:'Bạn thường bóng vào lúc nào?',recommendedIds:['fake','p1','p1']})}]}}]})};
 }});
 assert.deepEqual(r.ids,['p1']);assert.ok(payload.systemInstruction.parts[0].text.includes('Never diagnose'));assert.equal(payload.contents[0].parts[1].inlineData.mimeType,'image/jpeg');
});
test('blocked, truncated, malformed and invalid responses fail instead of returning fake success',async()=>{
 for(const candidate of [{finishReason:'SAFETY'},{finishReason:'MAX_TOKENS',content:{parts:[{text:'{}'}]}},{finishReason:'STOP',content:{parts:[{text:'garbage'}]}},{finishReason:'STOP',content:{parts:[{text:'{"reply":"","recommendedIds":[]}'}]}}]) await assert.rejects(()=>generate({input:validate(body),products:[],key:'test',model:'m',fetchFn:async()=>({ok:true,json:async()=>({candidates:[candidate]})})}));
});
test('provider errors are sanitized and do not disclose credentials or raw errors',async()=>{
 for(const response of [{ok:false,status:429},{ok:false,status:403}]) await assert.rejects(()=>generate({input:validate(body),products:[],key:'secret',model:'m',fetchFn:async()=>response}),e=>!e.message.includes('secret')&&[429,503].includes(e.status));
 await assert.rejects(()=>generate({input:validate(body),products:[],key:'secret',model:'m',fetchFn:async()=>{throw Error('raw secret');}}),e=>!e.message.includes('secret'));
});
test('quota caps each account/hour and the shared daily budget',async()=>{
 const rows=new Map();const db={collection:()=>({doc:id=>({id})}),runTransaction:async fn=>{const writes=[];await fn({get:async ref=>({exists:rows.has(ref.id),data:()=>rows.get(ref.id)}),set:(ref,data)=>writes.push(()=>rows.set(ref.id,data))});writes.forEach(f=>f());}};
 for(let i=0;i<20;i++)await quota(db,'alice',10000000);
 await assert.rejects(()=>quota(db,'alice',10000000),e=>e.status===429);
 await quota(db,'bob',10000000);
 for(const [id,r] of rows) rows.set(id,{...r,count:300});
 await assert.rejects(()=>quota(db,'new',10000000),e=>e.status===429);
});
const vm=require('node:vm'),fs=require('node:fs'),path=require('node:path');
const request=require('supertest'),express=require('express');
function routerHarness(env={}){
 let calls=0;
 const module={exports:{}};
 const db={hasCredentials:true,collection:()=>({limit:()=>({get:async()=>({docs:[]})})})};
 vm.runInNewContext(fs.readFileSync(path.join(__dirname,'../routes/ai.js'),'utf8'),{module,exports:module.exports,process:{env},require:name=>{
  if(name==='../firebase')return db;
  if(name==='../auth')return {requireAuth:(req,res,next)=>{if(req.headers.authorization!=='Bearer alice')return res.status(401).json({success:false});req.user={uid:'alice'};next();}};
  if(name==='../services/lumi_ai')return {...require('../services/lumi_ai'),quota:async()=>{},generate:async()=>{calls++;return {reply:'Hello',ids:[]};}};
  return require(name);
 }});
 const app=express();app.use('/api/ai',module.exports);return {app,get calls(){return calls;}};
}
test('routes require auth, do not expose key and enforce image flag before any provider call',async()=>{
 const h=routerHarness({GEMINI_API_KEY:'private-test-key'});
 assert.equal((await request(h.app).get('/api/ai/status')).status,401);
 const status=await request(h.app).get('/api/ai/status').set('Authorization','Bearer alice');assert.equal(JSON.stringify(status.body).includes('private-test-key'),false);
 const blocked=await request(h.app).post('/api/ai/chat').set('Authorization','Bearer alice').send({...body,imageConsent:true,image:{mimeType:'image/jpeg',data:jpeg}});assert.equal(blocked.status,403);assert.equal(h.calls,0);
 const chat=await request(h.app).post('/api/ai/chat').set('Authorization','Bearer alice').send(body);assert.equal(chat.status,200);assert.equal(h.calls,1);
 const noKey=routerHarness();assert.equal((await request(noKey.app).post('/api/ai/chat').set('Authorization','Bearer alice').send(body)).status,503);
});
test('service recommendations are separately allowlisted and include no invented IDs',async()=>{
 const r=await generate({input:validate(body),products:[{id:'p1'}],services:[{id:'s1',name:'Relaxing massage'}],key:'test',model:'test',fetchFn:async()=>({ok:true,json:async()=>({candidates:[{finishReason:'STOP',content:{parts:[{text:JSON.stringify({reply:'Bạn có thể hỏi chuyên viên về liệu trình thư giãn.',recommendedIds:['s1','p1'],recommendedServiceIds:['fake','s1','s1']})}]}}]})})});
 assert.deepEqual(r.ids,['p1']);assert.deepEqual(r.serviceIds,['s1']);
});
test('photo route works when enabled and consented, keeps image out of returned JSON',async()=>{
 const h=routerHarness({GEMINI_API_KEY:'test',GEMINI_FACE_IMAGES_ENABLED:'true'});
 const result=await request(h.app).post('/api/ai/chat').set('Authorization','Bearer alice').send({...body,imageConsent:true,image:{mimeType:'image/jpeg',data:jpeg}});
 assert.equal(result.status,200);assert.equal(h.calls,1);assert.equal(JSON.stringify(result.body).includes(jpeg),false);
});
test('ping identifies the new backend without disclosing credentials; unknown routes return JSON',async()=>{
 const h=routerHarness({GEMINI_API_KEY:'must-not-be-exposed'});
 const ping=await request(h.app).get('/api/ai/ping');assert.equal(ping.status,200);assert.equal(ping.body.data.version,'home-camera-v3');assert.equal(JSON.stringify(ping.body).includes('must-not-be-exposed'),false);
 const unknown=await request(h.app).get('/api/ai/missing').set('Authorization','Bearer alice');assert.equal(unknown.status,404);assert.equal(unknown.body.success,false);
});
