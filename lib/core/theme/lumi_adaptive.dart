import 'package:flutter/material.dart';

import '../settings/app_preferences.dart';

/// Shared presentation helpers. Never writes catalog, orders, bookings or auth data.
abstract final class LumiAdaptive {
  static void depend(BuildContext context) {
    Theme.of(context);
    Localizations.localeOf(context);
  }

  static Widget watch(BuildContext context, Widget Function() builder) {
    depend(context);
    return builder();
  }

  static bool get isDark => switch (AppPreferences.instance.themeMode) {
    ThemeMode.dark => true,
    ThemeMode.light => false,
    ThemeMode.system =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark,
  };

  static Color color(Color original, {bool surface = false}) {
    final originalArgb = original.toARGB32();
    final brand = switch (originalArgb & 0xFFFFFF) {
      0xB77489 || 0x6C4656 => 0xA5553E,
      0xD39AA9 => 0xF5BEA5,
      0xFBF4F5 => 0xFFF8EF,
      0xF0EBE6 => 0xE1EFF5,
      0xF0F5F2 => 0xEAF3F7,
      _ => originalArgb & 0xFFFFFF,
    };
    original = Color((originalArgb & 0xFF000000) | brand);
    if (!isDark) {
      return original;
    }
    final argb = original.toARGB32();
    final alpha = (argb >> 24) & 255;
    final rgb = argb & 0xFFFFFF;
    if (alpha == 0) {
      return original;
    }
    int? replacement;
    if (surface) {
      replacement = switch (rgb) {
        0xFFFFFF || 0xFFFDFA => 0x343D44,
        0xFFF8EF || 0xFAF7F4 || 0xFBF4F5 || 0xFFF9F5 => 0x262D32,
        0xEAF3F7 || 0xE8F2F6 || 0xE4EFF2 || 0xE1EFF5 => 0x344E5B,
        0xFBE7DC || 0xF8D5C2 || 0xF5BEA5 || 0xFBE4D6 || 0xFFE0D6 => 0x624B40,
        0xA9CEDD => 0x3B5A69,
        0xEADFD5 || 0xEFE4E6 || 0xE5DCDA || 0xDDD3C8 => 0x62717B,
        0x403735 || 0x302825 => 0x66584F,
        _ => null,
      };
      if (replacement == null && original.computeLuminance() > 0.72) {
        replacement = 0x3D484D;
      }
    } else {
      replacement = switch (rgb) {
        0x403735 || 0x302825 || 0x000000 || 0x3B3030 => 0xF5EFE8,
        0x756863 || 0x6F625D || 0x5F5550 || 0x8F8F8F || 0x666666 => 0xD1C9C0,
        0xA5553E || 0x557C90 => 0xF5BEA5,
        0xEADFD5 || 0xEFE4E6 || 0xE5DCDA => 0x687782,
        _ => null,
      };
      if (replacement == null &&
          rgb != 0xFFFFFF &&
          original.computeLuminance() < 0.12) {
        replacement = 0xE8DAD0;
      }
    }
    return replacement == null ? original : Color((alpha << 24) | replacement);
  }

  static T style<T>(T original) {
    if (original is! TextStyle || original.color == null) {
      return original;
    }
    return original.copyWith(color: color(original.color!)) as T;
  }

  static String? optionalText(String? original) =>
      original == null ? null : text(original);

  static const Map<String, String> _english = {
    "Trang chủ": "Home",
    "Cửa hàng": "Shop",
    "Lịch hẹn": "Appointments",
    "Tôi": "Account",
    "Tài khoản": "Account",
    "Cài đặt": "Settings",
    "Chỉnh sửa hồ sơ": "Edit profile",
    "Thông tin cá nhân": "Personal information",
    "Cập nhật họ tên và số điện thoại của bạn.":
        "Update your name and phone number.",
    "Cập nhật họ tên và số điện thoại": "Update your name and phone number",
    "Họ và tên": "Full name",
    "Họ và tên *": "Full name *",
    "Nhập họ và tên": "Enter your full name",
    "Nhập số điện thoại": "Enter your phone number",
    "Số điện thoại": "Phone number",
    "Lưu thay đổi": "Save changes",
    "Thử lại": "Try again",
    "THỬ LẠI": "TRY AGAIN",
    "Đóng": "Close",
    "ĐÓNG": "CLOSE",
    "Quay lại": "Back",
    "Tiếp tục": "Continue",
    "Tải lại": "Reload",
    "Làm mới": "Refresh",
    "Đăng nhập": "Sign in",
    "đăng nhập": "sign in",
    "ĐĂNG NHẬP": "SIGN IN",
    "ĐĂNG NHẬP NGAY": "SIGN IN NOW",
    "ĐĂNG NHẬP LẠI": "SIGN IN AGAIN",
    "Đã có lỗi xảy ra. Vui lòng thử lại.":
        "Something went wrong. Please try again.",
    "Không thể kết nối mạng. Hãy thử lại.":
        "Could not connect. Please try again.",
    "Vui lòng kiểm tra kết nối và thử lại.":
        "Please check your connection and try again.",
    "Vui lòng thử lại sau.": "Please try again later.",
    "Không tải được hồ sơ": "Could not load your profile",
    "Không tải được hồ sơ · Thử lại": "Could not load profile · Retry",
    "Vui lòng nhập họ và tên.": "Please enter your full name.",
    "Tên không quá 100 ký tự.": "Your name cannot exceed 100 characters.",
    "Số điện thoại phải có 8–20 ký tự hợp lệ.":
        "Enter a valid phone number with 8–20 characters.",
    "Đăng xuất": "Sign out",
    "Đang đăng xuất…": "Signing out…",
    "Đã đăng xuất khỏi LUMI.": "You have signed out of LUMI.",
    "Không thể đăng xuất. Vui lòng thử lại.":
        "Could not sign out. Please try again.",
    "Đăng nhập / Đăng ký": "Sign in / Register",
    "Bạn chưa đăng nhập": "You are not signed in",
    "Yêu cầu đăng nhập": "Sign-in required",
    "Chào bạn": "Hello",
    "Chào bạn.": "Hello.",
    "Chào mừng bạn đến với LUMI SPA.": "Welcome to LUMI SPA.",
    "Chăm sóc theo cách của bạn.": "Self-care, your way.",
    "Danh mục": "Categories",
    "Xem tất cả": "View all",
    "Chăm da": "Skincare",
    "Da mặt": "Facial care",
    "Mỹ phẩm": "Beauty products",
    "Đặt lịch": "Book a treatment",
    "Đặt lịch ngay": "Book now",
    "Đặt lịch chăm sóc": "Make time for yourself",
    "Dịch vụ tại LUMI": "Care at LUMI",
    "Chọn liệu trình và thời gian phù hợp.":
        "Choose a treatment and a time that suits you.",
    "Góc chăm sóc da": "Skincare Journal",
    "Khám phá góc chăm sóc": "Explore the Journal",
    "Dành một chút thời gian để hiểu làn da của bạn.":
        "Take a little time to understand your skin.",
    "Tìm dịch vụ, mỹ phẩm": "Search treatments and products",
    "Tìm kiếm": "Search",
    "Tìm dịch vụ, liệu trình...": "Search treatments...",
    "Tìm sản phẩm chăm sóc da...": "Search skincare products...",
    "Tìm bài viết": "Search articles",
    "Nhập tên dịch vụ hoặc mỹ phẩm...": "Enter a treatment or product name...",
    "Xóa tìm kiếm": "Clear search",
    "Mở menu": "Open menu",
    "Đóng menu": "Close menu",
    "Thông báo": "Notifications",
    "Thông báo từ LUMI SPA": "Notifications from LUMI SPA",
    "Chưa có thông báo nào": "No notifications yet",
    "Thông báo chưa đọc sẽ xuất hiện tại đây.":
        "Unread notifications will appear here.",
    "Bạn đã xem hết thông báo": "You are all caught up",
    "Chưa đọc": "Unread",
    "Tất cả": "All",
    "Đánh dấu đã đọc": "Mark as read",
    "Không tải được thông báo": "Could not load notifications",
    "Lịch hẹn, ưu đãi và cập nhật mới từ LUMI sẽ được gửi đến bạn tại đây.":
        "Your appointments, offers and updates from LUMI will appear here.",
    "Cập nhật dành cho bạn": "Updates for you",
    "Vừa xong": "Just now",
    "Tin tức & chăm sóc da": "News & skincare",
    "Đặc quyền thành viên": "Member benefits",
    "Khám phá quyền lợi dành cho bạn.": "Discover your membership benefits.",
    "Xem quyền lợi": "View benefits",
    "Thẻ thành viên": "Membership",
    "Thẻ thành viên LUMI": "LUMI membership",
    "Thẻ thành viên của bạn": "Your membership card",
    "Thành viên LUMI": "LUMI member",
    "Tích lũy của bạn": "Your points",
    "điểm tích lũy": "reward points",
    "Quyền lợi": "Benefits",
    "Quyền lợi thực tế tùy thuộc vào hạng và chính sách hiện hành của LUMI.":
        "Benefits depend on your tier and current LUMI policies.",
    "Ưu đãi dịch vụ làm đẹp": "Beauty service benefits",
    "Ưu tiên cập nhật lịch hẹn": "Appointment updates",
    "Quà tặng trong các dịp đặc biệt": "Gifts on special occasions",
    "Thông tin hạng chưa khả dụng": "Tier information is unavailable",
    "Chưa có thông tin điểm tích lũy.":
        "Points information is not available yet.",
    "Điểm sẽ được cập nhật sau giao dịch đủ điều kiện.":
        "Points will be updated after eligible transactions.",
    "Bạn đang ở hạng thành viên mặc định.":
        "You are on the default membership tier.",
    "Không tải được dữ liệu thành viên": "Could not load membership details",
    "Hỗ trợ và liên hệ": "Help and contact",
    "Tùy chọn tài khoản": "Account preferences",
    "Lịch sử liệu trình": "Treatment history",
    "Xem các lịch hẹn của bạn": "View your appointments",
    "Đơn hàng của tôi": "My orders",
    "Quản lý và theo dõi đơn mua sản phẩm":
        "Manage and track your product orders",
    "Bạn chưa đăng ký dịch vụ nào": "You have not booked any services yet",
    "Tổng hợp các liệu trình và trạng thái đăng ký của bạn.":
        "Your treatments and registration status in one place.",
    "Các liệu trình bạn đăng ký tại LUMI sẽ xuất hiện ở đây.":
        "The treatments you book at LUMI will appear here.",
    "Chưa tải được lịch sử": "Could not load your history",
    "Đăng nhập từ trang tài khoản để xem lịch sử của bạn.":
        "Sign in from your account to view your history.",
    "Bạn cần hỗ trợ?": "How can we help?",
    "Tìm thông tin liên hệ và hướng dẫn sử dụng LUMI.":
        "Find contact details and guidance on using LUMI.",
    "Liên hệ LUMI": "Contact LUMI",
    "Liên hệ": "Contact",
    "Thông tin liên hệ": "Contact information",
    "Thông tin liên hệ chưa được cập nhật.":
        "Contact information has not been updated yet.",
    "Chưa tải được thông tin liên hệ.": "Could not load contact information.",
    "Điện thoại": "Phone",
    "Địa chỉ": "Address",
    "Giờ hoạt động": "Opening hours",
    "Đã sao chép": "Copied",
    "Câu hỏi thường gặp": "Frequently asked questions",
    "Đăng ký liệu trình ở đâu?": "Where can I book a treatment?",
    "Mở tab Spa, chọn dịch vụ và thực hiện các bước đặt lịch.":
        "Open Spa, choose a service and follow the booking steps.",
    "Xem lịch đã đăng ký ở đâu?": "Where can I view my bookings?",
    "Mở tab Lịch hẹn để xem trạng thái đăng ký của bạn.":
        "Open Appointments to check your booking status.",
    "Xem đơn hàng ở đâu?": "Where can I view my orders?",
    "Vào Tôi → Đơn hàng của tôi để theo dõi đơn mua sản phẩm.":
        "Go to Account → My orders to track your purchases.",
    "Chỉnh sửa thông tin cá nhân thế nào?": "How can I edit my profile?",
    "Vào Tôi → Chỉnh sửa hồ sơ để cập nhật tên và số điện thoại.":
        "Go to Account → Edit profile to update your name and phone number.",
    "Bài viết": "Articles",
    "Về LUMI": "About LUMI",
    "Đọc bài viết": "Read article",
    "Đọc bài viết  ↗": "Read article  ↗",
    "Chưa tải được bài viết": "Could not load articles",
    "Tài khoản chưa có quyền đọc nội dung này.":
        "This content is currently unavailable. Please try again later.",
    "Chưa có bài viết.": "No articles yet.",
    "Không tìm thấy bài viết phù hợp.": "No matching articles found.",
    "Một chút cảm hứng mỗi ngày": "A little inspiration every day",
    "Những thước phim chăm sóc và thư giãn từ LUMI.":
        "Moments of care and relaxation from LUMI.",
    "LUMI chưa đăng video. Bạn có thể khám phá các bài viết ở tab Bài viết.":
        "No videos have been published yet. Explore the Articles tab instead.",
    "Chưa tải được video.": "Could not load videos.",
    "Không tải được video. Vui lòng kiểm tra kết nối hoặc thử lại sau.":
        "Could not load the video. Check your connection or try again later.",
    "Không phát được video này.": "Could not play this video.",
    "Video không khả dụng. Vui lòng thử lại sau.":
        "This video is unavailable. Please try again later.",
    "Phát video": "Play video",
    "Tạm dừng": "Pause",
    "Bật âm thanh": "Unmute",
    "Tắt âm thanh": "Mute",
    "CÂU CHUYỆN LUMI": "OUR STORY",
    "LUMI chưa cập nhật nội dung giới thiệu.":
        "Our story will be available soon.",
    "Chưa tải được giới thiệu LUMI.": "Could not load our story.",
    "Cảm ơn bạn đã để LUMI trở thành một phần trong hành trình chăm sóc bản thân.":
        "Thank you for making LUMI part of your self-care journey.",
    "Sắp tới": "Upcoming",
    "Lịch sử": "History",
    "Đã hủy": "Cancelled",
    "Đã hoàn tất": "Completed",
    "Đã xác nhận": "Confirmed",
    "Đã duyệt": "Approved",
    "Chờ xác nhận": "Awaiting confirmation",
    "Chờ duyệt": "Pending approval",
    "Không được duyệt": "Not approved",
    "Không đến": "No-show",
    "Chưa có lịch hẹn sắp tới": "No upcoming appointments",
    "Chưa có lịch sử dịch vụ": "No treatment history yet",
    "Chưa có lịch hẹn nào bị hủy": "No cancelled appointments",
    "Không thể tải lịch hẹn": "Could not load appointments",
    "LUMI chưa tải được lịch hẹn. Bạn vui lòng thử lại sau nhé.":
        "LUMI could not load your appointments. Please try again later.",
    "Đã xảy ra sự cố kết nối với hệ thống Firestore.":
        "LUMI could not load your appointments. Please try again later.",
    "Đăng nhập để xem lịch hẹn": "Sign in to view appointments",
    "Đăng nhập để theo dõi và quản lý những buổi chăm sóc của riêng bạn tại LUMI.":
        "Sign in to keep track of your care sessions at LUMI.",
    "Các buổi chăm sóc sau khi hoàn thành hoặc qua ngày hẹn sẽ lưu trữ tại đây.":
        "Completed and past appointments will appear here.",
    "Danh sách các lịch đã hủy sẽ hiển thị tại khu vực này.":
        "Your cancelled appointments will appear here.",
    "Khám phá liệu trình": "Explore treatments",
    "Khám phá những liệu trình phù hợp với nhu cầu của bạn.":
        "Explore treatments that suit your needs.",
    "LỊCH HẸN": "APPOINTMENTS",
    "Hủy lịch": "Cancel booking",
    "Hủy lịch hẹn?": "Cancel this appointment?",
    "HỦY LỊCH HẸN NÀY": "CANCEL THIS APPOINTMENT",
    "XÁC NHẬN HỦY": "CONFIRM CANCELLATION",
    "Đã hủy lịch hẹn thành công.": "Your appointment has been cancelled.",
    "Chi tiết lịch hẹn": "Appointment details",
    "Mã lịch hẹn:": "Booking ID:",
    "Dịch vụ:": "Service:",
    "Thời gian:": "Time:",
    "Thời lượng:": "Duration:",
    "Người đặt:": "Booked by:",
    "Số điện thoại:": "Phone:",
    "Khách hàng:": "Customer:",
    "Giá dịch vụ:": "Service price:",
    "LUMI · Đặt lịch": "LUMI · Booking",
    "Đặt lịch dịch vụ": "Book a service",
    "Đặt lịch thành công": "Booking received",
    "LUMI đã nhận lịch hẹn của bạn. Chúng tôi sẽ liên hệ xác nhận trong ít phút. Bạn có thể theo dõi trạng thái tại mục Lịch hẹn.": "LUMI has received your booking. We will contact you shortly to confirm. You can track its status in Appointments.",
    "Lịch hẹn của bạn đã được ghi nhận trên Firestore. Spa sẽ liên hệ xác nhận trong ít phút.": "LUMI has received your booking. We will contact you shortly to confirm.",
    "ĐANG CHỜ LUMI XÁC NHẬN": "AWAITING LUMI CONFIRMATION",
    "TRẠNG THÁI: CHỜ XÁC NHẬN (PENDING)": "AWAITING LUMI CONFIRMATION",
    "HOÀN TẤT & VỀ TRANG CHỦ": "DONE & BACK TO HOME",
    "XÁC NHẬN LỊCH HẸN": "CONFIRM BOOKING",
    "LIỆU TRÌNH ĐÃ CHỌN": "SELECTED TREATMENT",
    "Chọn ngày dành cho bạn": "Choose your day",
    "Chọn ngày đặt lịch": "Choose a booking date",
    "Chọn khung giờ": "Choose a time",
    "Còn trống": "Available",
    "Hết chỗ / Đã qua": "Full / Unavailable",
    "Trùng lịch": "Time conflict",
    "Thời gian không khả dụng": "Time unavailable",
    "Dịch vụ chưa có mã hợp lệ.": "This service is currently unavailable.",
    "Vui lòng nhập họ và tên của bạn.": "Please enter your full name.",
    "Vui lòng nhập số điện thoại hợp lệ (8 - 20 số).":
        "Please enter a valid phone number (8–20 digits).",
    "Quý khách vui lòng đăng nhập để hoàn tất đặt lịch.":
        "Please sign in to complete your booking.",
    "Quý khách vui lòng đăng nhập để lưu và quản lý lịch hẹn tại LUMI SPA.":
        "Please sign in to save and manage your LUMI bookings.",
    "Vui lòng giữ điện thoại để nhận cuộc gọi xác nhận.":
        "Please keep your phone available for our confirmation call.",
    "Chọn dịch vụ": "Choose a service",
    "Chọn dịch vụ để đặt lịch.": "Choose a service to book.",
    "Dịch vụ": "Services",
    "Dịch vụ LUMI": "LUMI services",
    "Chi tiết dịch vụ": "Service details",
    "Các liệu trình tại LUMI": "Treatments at LUMI",
    "Liệu trình spa": "Spa treatments",
    "Liệu trình nổi bật": "Featured treatments",
    "Liệu trình LUMI": "LUMI treatments",
    "Liệu trình chăm sóc": "Care treatments",
    "Chưa có liệu trình nào.": "No treatments yet.",
    "Chưa tải được liệu trình.": "Could not load treatments.",
    "Đang tải liệu trình...": "Loading treatments...",
    "Chưa có dịch vụ được đăng tải": "No services published yet",
    "Không thể tải dịch vụ": "Could not load services",
    "Chưa thể kết nối danh sách dịch vụ": "Could not load the service catalog",
    "Không tìm thấy liệu trình phù hợp": "No matching treatments found",
    "Hãy thử từ khóa hoặc danh mục khác.": "Try another keyword or category.",
    "Thử từ khóa hoặc danh mục khác.": "Try another keyword or category.",
    "Giá dịch vụ": "Service price",
    "Thời lượng": "Duration",
    "Thư giãn": "Relaxation",
    "Cơ thể": "Body care",
    "Thẩm mỹ": "Beauty care",
    "Khác": "Other",
    "Về liệu trình này": "About this treatment",
    "Lợi ích nổi bật": "Key benefits",
    "Quy trình trải nghiệm": "Treatment steps",
    "Lưu ý quan trọng": "Important information",
    "Phù hợp với ai?": "Who is it for?",
    "Cần tư vấn liệu trình?": "Need help choosing a treatment?",
    "Liên hệ tư vấn": "Contact us",
    "Đặt lịch tư vấn": "Book a consultation",
    "LUMI sẽ giúp bạn lựa chọn trải nghiệm phù hợp.":
        "LUMI can help you choose a suitable experience.",
    "Giỏ hàng": "Cart",
    "Giỏ hàng của bạn": "Your cart",
    "Giỏ hàng đang trống": "Your cart is empty",
    "Giỏ hàng đang trống.": "Your cart is empty.",
    "Giỏ hàng đang được tải.": "Loading your cart.",
    "Giỏ hàng hiện chỉ lưu trong phiên sử dụng.":
        "Your cart is saved for this session only.",
    "Bộ sưu tập LUMI": "The LUMI collection",
    "Bộ sưu tập đang được chuẩn bị": "Our collection is being prepared",
    "Mỹ phẩm LUMI": "LUMI beauty products",
    "Mỹ phẩm tại LUMI": "Beauty products at LUMI",
    "Sản phẩm LUMI": "LUMI products",
    "Chưa có mỹ phẩm nào.": "No products yet.",
    "Chưa tải được mỹ phẩm.": "Could not load products.",
    "Đang tải mỹ phẩm...": "Loading products...",
    "Chưa thể kết nối cửa hàng": "Could not load the shop",
    "Các sản phẩm và giá chính thức sẽ xuất hiện khi LUMI cập nhật dữ liệu.": "Products and current prices will appear when LUMI updates the catalog.",
    "Không tìm thấy sản phẩm": "No products found",
    "Chi tiết sản phẩm": "Product details",
    "Giới thiệu sản phẩm": "About this product",
    "Thành phần": "Ingredients",
    "Hướng dẫn sử dụng": "How to use",
    "Thông tin sản phẩm chưa được cập nhật.":
        "Product information is not available yet.",
    "Thông tin đang được cập nhật.": "Information is being updated.",
    "Bộ lọc & Sắp xếp": "Filter & sort",
    "Thu gọn bộ lọc": "Hide filters",
    "Sắp xếp": "Sort by",
    "Khoảng giá": "Price range",
    "Dòng sản phẩm chính": "Product category",
    "Tất cả dòng sản phẩm": "All product categories",
    "Tất cả dung tích / quy cách": "All sizes and formats",
    "Dung tích / Quy cách (tự động theo sản phẩm)":
        "Size / Format (based on product)",
    "Chưa rõ dung tích": "Size unavailable",
    "Phổ biến nhất": "Most popular",
    "Giá tăng dần (Thấp đến cao)": "Price: low to high",
    "Giá giảm dần (Cao đến thấp)": "Price: high to low",
    "Đặt lại": "Reset",
    "Làm sạch & Cân bằng": "Cleanse & balance",
    "Tinh chất đặc trị & Tế bào gốc": "Serums & targeted care",
    "Dưỡng ẩm & Khóa dưỡng": "Moisturize & protect",
    "Chống nắng & Bảo vệ quang học": "Sun protection",
    "Mặt nạ chăm sóc chuyên sâu": "Treatment masks",
    "Chăm sóc cơ thể & Dưỡng sinh": "Body care & wellbeing",
    "Thêm vào giỏ hàng": "Add to cart",
    "Đã thêm vào giỏ hàng": "Added to cart",
    "Xóa sản phẩm?": "Remove this product?",
    "Bạn có chắc muốn xóa sản phẩm này khỏi giỏ hàng không?":
        "Are you sure you want to remove this product from your cart?",
    "Xóa": "Remove",
    "Hủy": "Cancel",
    "Không": "No",
    "Miễn phí": "Free",
    "Tạm tính": "Subtotal",
    "Tổng tiền": "Total",
    "Tổng cộng": "Total",
    "Tổng thanh toán": "Total payment",
    "Tiếp tục thanh toán": "Continue to checkout",
    "Tiếp tục mua sắm": "Continue shopping",
    "TIẾP TỤC MUA SẮM": "CONTINUE SHOPPING",
    "Thanh toán": "Checkout",
    "Thanh toán đơn hàng": "Checkout",
    "Thông tin nhận hàng": "Delivery details",
    "Người nhận": "Recipient",
    "Nhập tên người nhận": "Enter the recipient's name",
    "Địa chỉ giao hàng": "Delivery address",
    "Số nhà, đường, phường/xã...": "House number, street, ward...",
    "Ghi chú": "Notes",
    "Ghi chú đơn hàng": "Order notes",
    "Ví dụ: giao giờ hành chính": "For example: deliver during office hours",
    "Phương thức thanh toán": "Payment method",
    "Thanh toán khi nhận hàng": "Cash on delivery",
    "Thanh toán khi nhận hàng (COD)": "Cash on delivery (COD)",
    "COD - trả tiền mặt khi nhận sản phẩm":
        "COD - pay when you receive your order",
    "Chuyển khoản ngân hàng": "Bank transfer",
    "Chuyển khoản trước khi nhận hàng": "Pay by transfer before delivery",
    "Thông tin chuyển khoản": "Bank transfer details",
    "Ngân hàng": "Bank",
    "Chủ tài khoản": "Account holder",
    "Số tài khoản": "Account number",
    "Số tiền": "Amount",
    "Nội dung": "Reference",
    "Phí giao hàng": "Delivery fee",
    "Tóm tắt đơn hàng": "Order summary",
    "Sản phẩm trong đơn": "Order items",
    "Sản phẩm đã chọn": "Selected products",
    "Họ và tên quá ngắn": "Please enter a longer name",
    "Số điện thoại phải gồm 10 số và bắt đầu bằng 0":
        "Enter a 10-digit phone number starting with 0",
    "Địa chỉ giao hàng quá ngắn": "Please enter a complete delivery address",
    "Vui lòng nhập họ và tên": "Please enter your full name",
    "Vui lòng nhập số điện thoại": "Please enter your phone number",
    "Vui lòng nhập địa chỉ giao hàng": "Please enter your delivery address",
    "Không thể tạo đơn hàng. Vui lòng thử lại.":
        "Could not place your order. Please try again.",
    "Không thể lưu tiến trình. Vui lòng thử lại.":
        "Could not save your progress. Please try again.",
    "Đặt hàng thành công": "Order received",
    "Cảm ơn bạn đã mua sắm tại LUMI.": "Thank you for shopping with LUMI.",
    "Cảm ơn bạn đã\nmua sắm tại LUMI": "Thank you for\nshopping with LUMI",
    "XEM ĐƠN HÀNG": "VIEW ORDER",
    "Về trang chủ": "Back to home",
    "Chi tiết đơn hàng": "Order details",
    "Mã đơn hàng": "Order ID",
    "Ngày đặt": "Order date",
    "Trạng thái": "Status",
    "Đang giao": "On the way",
    "Đã giao": "Delivered",
    "Trạng thái đang cập nhật": "Status is being updated",
    "HỦY ĐƠN HÀNG": "CANCEL ORDER",
    "Hủy đơn": "Cancel order",
    "Hủy đơn hàng?": "Cancel this order?",
    "Bạn có chắc chắn muốn hủy đơn hàng này không?":
        "Are you sure you want to cancel this order?",
    "Không thể hủy đơn hàng. Vui lòng thử lại.":
        "Could not cancel the order. Please try again.",
    "Đơn hàng đã được hủy": "Order cancelled",
    "Đơn hàng này đã được hủy.": "This order has been cancelled.",
    "Các đơn hàng của bạn sẽ xuất hiện ở đây.": "Your orders will appear here.",
    "Bạn chưa có đơn hàng nào": "No orders yet",
    "Theo dõi lịch sử mua sắm và trạng thái các đơn hàng của bạn tại LUMI.":
        "Track your purchase history and order status at LUMI.",
    "Khám phá LUMI": "Explore LUMI",
    "Tiếp tục khám phá mà không đăng nhập": "Continue without signing in",
    "TIẾP TỤC KHÁM PHÁ": "CONTINUE EXPLORING",
    "ĐÃ CÓ TÀI KHOẢN? ĐĂNG NHẬP": "ALREADY HAVE AN ACCOUNT? SIGN IN",
    "Một chút\nbình yên.": "A moment\nof calm.",
    "Khoảnh khắc\ndành cho bạn.": "A moment\njust for you.",
    "Một khoảng lặng\nchỉ dành cho bạn.": "A quiet moment\njust for you.",
    "Đẹp từ những\nđiều dịu dàng.": "Beauty in\nthe little things.",
    "Chăm sóc da mỗi ngày": "Everyday skincare",
    "Một khoảng lặng cho riêng mình": "A quiet moment for yourself",
    "Một hành trình chăm sóc sắc đẹp dành riêng cho bạn.":
        "A personal journey of beauty and self-care.",
    "Hôm nay, dành thời gian\nchăm sóc mình nhé.":
        "Make time today\nto take care of yourself.",
    "Vui lòng nhập email và mật khẩu.": "Please enter your email and password.",
    "Địa chỉ email không hợp lệ.": "Please enter a valid email address.",
    "Email hoặc mật khẩu không chính xác.":
        "Your email or password is incorrect.",
    "Email này đã được đăng ký.": "This email is already registered.",
    "Mật khẩu phải có ít nhất 6 ký tự.":
        "Your password must have at least 6 characters.",
    "Mật khẩu quá yếu. Hãy dùng ít nhất 6 ký tự.":
        "Your password is too weak. Use at least 6 characters.",
    "Bạn đã thử quá nhiều lần. Vui lòng thử lại sau.":
        "Too many attempts. Please try again later.",
    "Nhập email trước khi đặt lại mật khẩu.":
        "Enter your email before resetting your password.",
    "Nếu email hợp lệ, bạn sẽ nhận được hướng dẫn đặt lại mật khẩu.":
        "If the email is valid, you will receive password reset instructions.",
    "Đang cập nhật": "Updating",
    "Đang cập nhật...": "Updating...",
    "Chưa cập nhật": "Not provided",
    "Chưa cập nhật số điện thoại": "Phone number not provided",
    "Chưa có thời gian": "Time not available",
    "Chưa xác định": "Not specified",
    "Chưa tải được banner.": "Could not load banners.",
    "Xem chi tiết": "View details",
    "Chi tiết": "Details",
    "Liên hệ với LUMI": "Contact LUMI",
    "Khám phá danh mục": "Explore categories",
    "Khám phá những liệu trình chăm sóc dành riêng cho bạn.":
        "Explore treatments selected for you.",
    "Chưa tìm thấy kết quả phù hợp.\nThử từ khóa khác nhé!":
        "No matching results.\nTry another keyword.",
    "Xem dịch vụ →": "View services →",
    "Xem mỹ phẩm →": "View products →",
    "Tạo tài khoản": "Create account",
    "Mật khẩu": "Password",
    "Quên mật khẩu?": "Forgot password?",
    "Đăng ký": "Register",
    "ĐĂNG KÝ": "REGISTER",
    "Xác nhận mật khẩu": "Confirm password",
    "Email của bạn": "Your email",
    "Đã có tài khoản?": "Already have an account?",
    "Chưa có tài khoản?": "Don't have an account?",
    "XEM": "VIEW",
    "Tiếp tục với Google": "Continue with Google",
    "Số điện thoại liên hệ *": "Contact phone number *",
    "ĐANG XỬ LÝ...": "PROCESSING...",
    "GIỮ LỊCH": "RESERVE",
    "Hãy khám phá các sản phẩm chăm sóc da của LUMI.":
        "Explore skincare products from LUMI.",
    "Chưa lưu được lựa chọn. Vui lòng thử lại.":
        "Could not save your preference. Please try again.",
    "Sáng": "Light",
    "Tối": "Dark",
    "Theo hệ thống": "System default",
    "Ngôn ngữ": "Language",
    "Giao diện": "Appearance",
    "Khi spa cập nhật dịch vụ lên hệ thống, danh sách sẽ xuất hiện tại đây.":
        "Services will appear here when LUMI updates the catalog.",
    "Dành thời gian cho sự thư thái và cân bằng.":
        "Make time for relaxation and balance.",
    "Dành thời gian nghỉ ngơi cũng là một phần của hành trình chăm sóc bản thân.":
        "Rest is part of taking care of yourself.",
    "Một làn da đẹp bắt đầu từ sự dịu dàng.":
        "Beautiful skin begins with gentle care.",
    "Sự tinh tế kết hợp cùng công nghệ chăm sóc da.":
        "Thoughtful care meets skincare technology.",
    "Từng trải nghiệm được chăm chút tỉ mỉ.":
        "Every experience, thoughtfully considered.",
    "Chọn ngôn ngữ và giao diện phù hợp với bạn.":
        "Choose your preferred language and appearance.",
    "LUMI theo cách của bạn": "Make LUMI yours",
    "Lựa chọn được lưu trên thiết bị này.":
        "Your preferences are saved on this device.",
    "Tự đổi theo cài đặt thiết bị": "Follow your device appearance",
    "Tìm dịch vụ": "Search services",
    "Hãy kiểm tra máy chủ LUMI API và thử lại.":
        "LUMI could not connect. Please try again later.",
    "Kiểm tra máy chủ LUMI API rồi thử lại.":
        "LUMI could not connect. Please try again later.",
    "Chăm sóc da": "Skincare",
    "Liệu trình": "Treatments",
    "Quản lý thông tin cá nhân của bạn.": "Manage your personal information.",
    "Bạn đã đăng nhập. Chức năng xem và quản lý lịch hẹn sẽ được bổ sung sau.":
        "You are signed in. Appointment management will be available soon.",
    "Đơn hàng của bạn đã được ghi nhận. LUMI sẽ liên hệ để xác nhận đơn hàng sớm nhất.":
        "LUMI has received your order and will contact you shortly to confirm.",
    "Đơn hàng đã được xác nhận và đang được chuẩn bị để giao đến bạn.":
        "Your order is confirmed and being prepared for delivery.",
    "Đơn hàng đang trên đường giao đến bạn. Vui lòng giữ điện thoại để nhận cuộc gọi từ nhân viên giao hàng.": "Your order is on the way. Please keep your phone available for the courier.",
    "Đơn hàng đã được giao thành công. Cảm ơn bạn đã mua sắm tại LUMI.":
        "Your order has been delivered. Thank you for shopping with LUMI.",
    "Đơn hàng sẽ được giao đến địa chỉ bạn đã cung cấp. LUMI sẽ liên hệ với bạn để xác nhận đơn hàng trong thời gian sớm nhất.": "Your order will be delivered to the address you provided. LUMI will contact you shortly to confirm.",
    "Đơn hàng sẽ được lưu vào hệ thống sau khi bạn hoàn tất đặt hàng.":
        "Your order will be saved after you complete checkout.",
    "Sau khi chuyển khoản, vui lòng giữ lại ảnh chụp giao dịch để đối chiếu khi cần.": "After transferring payment, keep a screenshot of the transaction for reference.",
    "Bạn có thể xem dịch vụ mà không cần đăng nhập. Khi đặt lịch, LUMI sẽ yêu cầu đăng nhập để tiếp tục.": "You can browse services without signing in. Please sign in when you are ready to book.",
    "LUMI BEAUTY · Một chút chăm sóc, một chút yêu thương dành cho chính mình.":
        "LUMI BEAUTY · A little care, a little love for yourself.",
    "LUMI JOURNAL · BÀI VIẾT MẪU": "LUMI JOURNAL · SAMPLE ARTICLE",
    "Bài viết mẫu cho dự án LUMI SPA · Nội dung mang tính tham khảo.":
        "Sample article for the LUMI SPA project · For general information.",
    "Một chút thời gian cho bản thân": "A little time for yourself",
    "Khám phá những liệu trình chăm sóc và thư giãn tại LUMI SPA.":
        "Explore care and relaxation treatments at LUMI SPA.",
    "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.":
        "Your session has expired. Please sign in again.",
    "Tài khoản đã được tạo, nhưng hồ sơ chưa cập nhật hoàn tất. Bạn vui lòng đăng nhập lại để tiếp tục.": "Your account was created, but your profile is not complete yet. Please sign in again to continue.",
  };
  static String text(String original) {
    if (!AppPreferences.instance.isEnglish) {
      return const <String, String>{
            'YOUR LUMI MOMENT': 'KHOẢNH KHẮC CỦA BẠN',
            'Create Account': 'Tạo tài khoản',
            'Welcome Back': 'Chào mừng trở lại',
            'Your name': 'Họ và tên',
            'Email address': 'Địa chỉ email',
            'Password': 'Mật khẩu',
            'Stay signed in': 'Duy trì đăng nhập',
            'Forgot Password?': 'Quên mật khẩu?',
            'Sign Up': 'Đăng ký',
            'Log In': 'Đăng nhập',
            'Already have an account?': 'Đã có tài khoản?',
            "Don't have an account?": 'Chưa có tài khoản?',
          }[original] ??
          original;
    }
    final exact = _english[original];
    if (exact != null) {
      return exact;
    }
    final compact = original.replaceAll(RegExp(r'\s+'), ' ').trim();
    final normalized = _english[compact];
    if (normalized != null) {
      return normalized;
    }
    for (final entry in _patterns) {
      final match = entry.$1.firstMatch(original);
      if (match != null) {
        return entry.$2(match);
      }
    }
    return original;
  }

  static final List<(RegExp, String Function(Match))> _patterns = [
    (
      RegExp(r'^Chào (.+)$'),
      (m) => m[1] == 'bạn' || m[1] == 'bạn.' ? 'Hello there' : 'Hello ${m[1]}',
    ),
    (
      RegExp(r'^Đăng nhập để (.+)\. Bạn vẫn có thể (.+)$'),
      (m) => 'Sign in to continue. You can still explore LUMI services and products without an account.',
    ),
    (
      RegExp(r'^Thời lượng: (.+?)\s*·\s*Giá: (.+)$'),
      (m) => 'Duration: ${m[1]} · Price: ${m[2]}',
    ),
    (
      RegExp(r'^LUMI EDITORIAL\s*·\s*(\d+) PHÚT ĐỌC$'),
      (m) => 'LUMI EDITORIAL · ${m[1]} MIN READ',
    ),
    (RegExp(r'^(.+)\s*·\s*(\d+) PHÚT$'), (m) => '${m[1]} · ${m[2]} MIN'),
    (
      RegExp(r'^(.+)\s*·\s*(\d+) phút đọc$'),
      (m) => '${m[1]} · ${m[2]} min read',
    ),
    (
      RegExp(
        r'^Quý khách có chắc chắn muốn hủy lịch hẹn liệu trình (.+)$',
        dotAll: true,
      ),
      (m) => 'Are you sure you want to cancel this appointment?',
    ),

    (RegExp(r'^(\d+) phút$'), (m) => '${m[1]} min'),
    (RegExp(r'^(\d+) phút(.*)$'), (m) => '${m[1]} min${m[2]}'),
    (RegExp(r'^(\d+) sản phẩm$'), (m) => '${m[1]} products'),
    (RegExp(r'^(\d+) dịch vụ$'), (m) => '${m[1]} services'),
    (RegExp(r'^(\d+) lượt đăng ký$'), (m) => '${m[1]} bookings'),
    (
      RegExp(r'^(\d+) thông báo chưa đọc$'),
      (m) => '${m[1]} unread notifications',
    ),
    (RegExp(r'^(\d+) ngày trước$'), (m) => '${m[1]} days ago'),
    (RegExp(r'^(\d+) giờ trước$'), (m) => '${m[1]} hours ago'),
    (RegExp(r'^(\d+) phút trước$'), (m) => '${m[1]} minutes ago'),
    (RegExp(r'^Số lượng: (.+)$'), (m) => 'Quantity: ${m[1]}'),
    (RegExp(r'^Đơn giá: (.+)$'), (m) => 'Unit price: ${m[1]}'),
    (RegExp(r'^Hạng (.+)$'), (m) => 'Tier ${m[1]}'),
    (RegExp(r'^Dành cho hạng (.+)$'), (m) => 'For ${m[1]} members'),
    (RegExp(r'^Điểm tích lũy: (.+)$'), (m) => 'Reward points: ${m[1]}'),
    (RegExp(r'^Sao chép (.+)$'), (m) => 'Copy ${m[1]}'),
    (RegExp(r'^Đang lọc \((.+)\)$'), (m) => 'Filters (${m[1]})'),
    (RegExp(r'^ĐẶT HÀNG · (.+)$'), (m) => 'PLACE ORDER · ${m[1]}'),
    (RegExp(r'^(.+) · (\d+) phút đọc$'), (m) => '${m[1]} · ${m[2]} min read'),
    (
      RegExp(r'^Chưa có đơn hàng ở trạng thái "(.+)"$'),
      (m) => 'No orders with status "${text(m[1]!)}"',
    ),
  ];
}
