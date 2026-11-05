const express=require('express');
const db=require('../firebase');
const {requireAuth}=require('../auth');
const forbiddenService= /nặn|nan mun|extraction|peel|laser|tiêm|kim|needle|inject|lăn kim|vi kim|prp/i;
const {validate,quota,productData,generate,issue}=require('../services/lumi_ai');
const router=express.Router();
router.get('/ping',(req,res)=>res.json({success:true,data:{service:'lumi-ai',version:'home-camera-v3'}}));
router.use(requireAuth);
router.use(express.json({limit:'3mb'}));
router.get('/status',(req,res)=>res.json({success:true,data:{configured:Boolean(process.env.GEMINI_API_KEY?.trim()),imagesEnabled:process.env.GEMINI_FACE_IMAGES_ENABLED==='true'}}));
router.post('/chat',async(req,res)=>{
 try {
  const input=validate(req.body);
  const key=process.env.GEMINI_API_KEY?.trim();
  if(!key) throw issue(503,'LUMI AI chưa được cấu hình. Vui lòng quay lại sau.');
  if(input.image && process.env.GEMINI_FACE_IMAGES_ENABLED!=='true') throw issue(403,'Phân tích ảnh chưa được bật. Bạn vẫn có thể trò chuyện bằng văn bản.');
  if(!db.hasCredentials) throw issue(503,'Chưa tải được danh mục LUMI.');
  await quota(db,req.user.uid);
  const snap=await db.collection('products').limit(120).get();
  const available=snap.docs.filter(d=>d.data().isActive!==false && (d.data().stock==null || Number(d.data().stock)>0));
  const products=available.map(productData);
  const serviceSnap=await db.collection('services').limit(100).get();
  const services=serviceSnap.docs.filter(d=>d.data().isActive!==false && !forbiddenService.test(`${d.data().name||''} ${d.data().description||''}`)).map(productData);
  const result=await generate({input,products,services,key,model:process.env.GEMINI_MODEL||'gemini-2.5-flash'});
  const current=await Promise.all(result.ids.map(id=>db.collection('products').doc(id).get()));
  const recommendations=current.filter(d=>d.exists && d.data().isActive!==false && (d.data().stock==null || Number(d.data().stock)>0)).map(d=>({ ...productData(d),imageUrl: typeof d.data().imageUrl==='string'?d.data().imageUrl:null }));
  const currentServices=await Promise.all((result.serviceIds||[]).map(id=>db.collection('services').doc(id).get()));
  const serviceRecommendations=currentServices.filter(d=>d.exists && d.data().isActive!==false && !forbiddenService.test(`${d.data().name||''} ${d.data().description||''}`)).map(d=>({ ...productData(d),type:'service',durationMinutes:d.data().durationMinutes,categoryId:d.data().categoryId||null,imageUrl:typeof d.data().imageUrl==='string'?d.data().imageUrl:null }));
  res.json({success:true,data:{reply:result.reply,recommendations:[...recommendations.map(p=>({...p,type:'product'})),...serviceRecommendations]}});
 }catch(error){res.status(error.status||503).json({success:false,message:error.status?error.message:'LUMI AI tạm chưa sẵn sàng. Vui lòng thử lại.'});}
});
router.use((req,res)=>res.status(404).json({success:false,message:'Đường dẫn LUMI AI không tồn tại. Hãy cập nhật backend.'}));
router.use((error,req,res,next)=>res.status(error.type==='entity.too.large'?413:400).json({success:false,message:'Nội dung quá lớn hoặc không hợp lệ.'}));
module.exports=router;
