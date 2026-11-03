require('dotenv').config();
const db = require('../firebase');
const defaults = {
  "title": "Một chút dịu dàng, dành riêng cho bạn.",
  "titleEn": "A little care, just for you.",
  "intro": "LUMI SPA & WELLNESS là ứng dụng kết nối những trải nghiệm chăm sóc sắc đẹp và thư giãn trong một không gian gần gũi. Chúng tôi mong bạn có thể tìm hiểu, lựa chọn và sắp xếp thời gian cho bản thân một cách chủ động, nhẹ nhàng hơn mỗi ngày.",
  "introEn": "LUMI SPA & WELLNESS brings beauty and relaxation experiences together in an approachable app. Explore, choose and make time for yourself at a pace that suits your day.",
  "quote": "Chăm sóc bản thân bắt đầu từ việc dành cho mình một chút thời gian và sự quan tâm.",
  "quoteEn": "Self-care begins with a little time and attention for yourself.",
  "imageUrl": "",
  "sections": [
    {
      "title": "Một khoảng riêng cho bạn",
      "body": "Giữa công việc, học tập và những kế hoạch nối tiếp nhau, thời gian dành cho bản thân đôi khi bị đẩy xuống cuối danh sách. LUMI bắt đầu từ một mong muốn giản dị: giúp việc chăm sóc mình trở nên gần gũi hơn, từ những điều nhỏ bạn có thể lựa chọn mỗi ngày. Đó có thể là tìm hiểu thêm về làn da, dành thời gian cho một liệu trình phù hợp hoặc chậm lại để nghỉ ngơi."
    },
    {
      "title": "Hiểu mình trước khi lựa chọn",
      "body": "Mỗi người có thói quen, nhu cầu và nhịp sống riêng. Vì vậy, LUMI muốn tạo một nơi để bạn tìm hiểu thông tin trước khi quyết định: dịch vụ gồm những gì, sản phẩm được giới thiệu ra sao và lựa chọn nào phù hợp với kế hoạch của bạn. Việc chăm sóc bản thân có thể bắt đầu bằng sự quan sát và lắng nghe, thay vì vội vàng chạy theo mọi xu hướng mới."
    },
    {
      "title": "Chăm sóc theo nhịp sống của bạn",
      "body": "Trong ứng dụng, bạn có thể khám phá danh mục dịch vụ, xem thông tin liệu trình và thực hiện các bước đăng ký. Sau khi đặt lịch, bạn có thể theo dõi trạng thái trong mục Lịch hẹn. Những thông tin được sắp xếp trong cùng một không gian giúp bạn chủ động hơn khi lên kế hoạch, đồng thời dễ quay lại xem những dịch vụ mình đã quan tâm hoặc đăng ký."
    },
    {
      "title": "Khám phá sản phẩm có cân nhắc",
      "body": "LUMI cũng là nơi để bạn tìm hiểu danh mục mỹ phẩm, xem mô tả và giá đang được công bố, trước khi đưa ra quyết định mua sắm. Một sản phẩm phù hợp cần được cân nhắc cùng nhu cầu, cách sử dụng và những gì bạn đang có trong quy trình chăm sóc. Bạn có thể theo dõi đơn hàng ngay trong ứng dụng để không bỏ lỡ những cập nhật liên quan đến giao dịch của mình."
    },
    {
      "title": "Góc chăm sóc da — đọc, xem và tìm cảm hứng",
      "body": "LUMI Journal được dành cho những nội dung về chăm sóc da, thư giãn và đời sống thường ngày. Bạn có thể đọc bài viết theo chủ đề, tìm kiếm nội dung mình quan tâm hoặc khám phá các video ngắn khi LUMI đăng tải. Chúng tôi mong góc nhỏ này trở thành một điểm dừng dễ chịu: nơi bạn tìm được một ý tưởng hữu ích và thêm động lực để duy trì những thói quen chăm sóc bản thân."
    },
    {
      "title": "Những điều nhỏ tạo nên trải nghiệm",
      "body": "Tinh thần thiết kế của LUMI hướng đến sự ấm áp, nhẹ nhàng và dễ sử dụng. Từ việc xem dịch vụ đến quản lý tài khoản, chúng tôi mong các thao tác trở nên rõ ràng để bạn có thể tập trung vào điều mình cần. Những phản hồi và trải nghiệm thực tế sẽ là cơ sở để tiếp tục hoàn thiện ứng dụng, từng bước một."
    },
    {
      "title": "Luôn có một nơi để kết nối",
      "body": "Nếu cần tìm thông tin liên hệ hoặc hướng dẫn thao tác, bạn có thể mở mục Hỗ trợ và liên hệ trong phần Tài khoản. Thông tin liên hệ được LUMI cập nhật tại đó để bạn tiện tra cứu. Nội dung chăm sóc da trên ứng dụng mang tính tham khảo; với những vấn đề kéo dài hoặc cần đánh giá chuyên môn, bạn nên tìm sự hỗ trợ trực tiếp từ người có chuyên môn phù hợp."
    }
  ],
  "sectionsEn": [
    {
      "title": "A little space of your own",
      "body": "Between work, study and everyday plans, time for yourself can easily slip to the end of your list. LUMI starts with a simple idea: make self-care feel more approachable through small, considered choices. That might mean learning about your skin, exploring a treatment or simply making room to rest."
    },
    {
      "title": "Understand your needs first",
      "body": "Everyone has different habits, needs and routines. LUMI gives you space to read about services and products before making a decision. Taking care of yourself can begin with noticing what works for you, rather than feeling the need to follow every new trend."
    },
    {
      "title": "Care at your own pace",
      "body": "Explore the service catalog, review treatment information and follow the booking steps in the app. After registering, you can check your booking status in Appointments. Keeping these details together makes it easier to plan your time and revisit services you have registered for."
    },
    {
      "title": "Explore products thoughtfully",
      "body": "Browse product descriptions and published prices before deciding what to buy. Consider your needs, the usage information and the products already in your routine. Your order details and status are available in the app so you can follow updates to your purchase."
    },
    {
      "title": "Read, watch and find inspiration",
      "body": "LUMI Journal brings together published content about skincare, relaxation and everyday wellbeing. Search for topics you care about, read articles and discover short videos as they become available. We hope this corner offers a useful idea and a little motivation to maintain habits that suit you."
    },
    {
      "title": "Small details shape the experience",
      "body": "LUMI is designed around a warm, calm and approachable experience. Clear steps help you find service information and manage your account. Feedback and practical experience will guide continued improvements to the app, one step at a time."
    },
    {
      "title": "A place to connect",
      "body": "Open Help and contact from your account to find current contact details and guidance on using LUMI. Skincare content in the app is for general information. If a concern persists or needs professional assessment, seek appropriate advice from a qualified professional."
    }
  ]
};
(async () => {
  const ref = db.collection('app_config').doc('about_lumi');
  const imageRef = db.collection('articles').where('isPublished', '==', true).get();
  const articles = await imageRef;
  for (const doc of articles.docs) {
    const data = doc.data();
    const image = data.imageUrl || data.coverImageUrl;
    if (typeof image === 'string' && image.trim()) { defaults.imageUrl = image.trim(); break; }
  }
  await db.runTransaction(async transaction => {
    const current = await transaction.get(ref);
    if (!current.exists) { transaction.set(ref, defaults); return; }
    const existing = current.data();
    const missing = {};
    for (const [key, value] of Object.entries(defaults)) {
      if (!(key in existing)) { missing[key] = value; }
    }
    if (Object.keys(missing).length) { transaction.set(ref, missing, {merge: true}); }
  });
  console.log('Đã bổ sung app_config/about_lumi. Giữ nguyên các trường đã có.');
  process.exit(0);
})().catch(error => { console.error('Chưa tạo được giới thiệu:', error.message); process.exit(1); });
