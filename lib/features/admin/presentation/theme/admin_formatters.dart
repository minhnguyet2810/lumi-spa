import 'package:intl/intl.dart';

/// Bộ chuẩn hóa hiển thị Tiền tệ & Ngày giờ thuần Việt cho Cổng quản trị Spa
abstract final class AdminFormatters {
  static final NumberFormat _currencyFormat = NumberFormat('#,###', 'vi_VN');
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('HH:mm - dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  /// Định dạng tiền tệ chuẩn VNĐ: 150.000 đ
  static String formatCurrency(num amount) {
    if (amount == 0) return '0 đ';
    return '${_currencyFormat.format(amount)} đ';
  }

  /// Định dạng tiền tệ ngắn gọn cho KPI / Báo cáo: 1.5tr đ, 500k đ
  static String formatShortCurrency(num amount) {
    if (amount >= 1000000000) {
      final t = amount / 1000000000.0;
      return '${t.toStringAsFixed(1)} tỷ đ';
    }
    if (amount >= 1000000) {
      final tr = amount / 1000000.0;
      return '${tr == tr.roundToDouble() ? tr.toInt() : tr.toStringAsFixed(1)}tr đ';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).round()}k đ';
    }
    return '${amount.toInt()} đ';
  }

  /// Định dạng ngày: 20/11/2026
  static String formatDate(DateTime dt) {
    return _dateFormat.format(dt);
  }

  /// Định dạng ngày có thứ: Thứ Hai, 20/11/2026
  static String formatDateWithWeekday(DateTime dt) {
    const weekdays = [
      '',
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    final dayName = weekdays[dt.weekday];
    return '$dayName, ${_dateFormat.format(dt)}';
  }

  /// Định dạng ngày giờ: 14:30 - 20/11/2026
  static String formatDateTime(DateTime dt) {
    return _dateTimeFormat.format(dt);
  }

  /// Định dạng giờ: 14:30
  static String formatTime(DateTime dt) {
    return _timeFormat.format(dt);
  }
}

