import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class LumiOrderStore {
  /// Danh sách đơn hàng cục bộ - khởi tạo rỗng để người dùng chỉ thấy đơn thực tế
  static final List<Map<String, String>> orders = [];

  /// Định dạng số tiền chuẩn: phân cách hàng nghìn bằng dấu chấm, đầy đủ số 0 (VD: 350.000 đ)
  static String formatCurrency(dynamic value) {
    if (value == null) return '0 đ';
    if (value is num) {
      final digits = value.toInt().toString();
      final formatted = digits.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => '.',
      );
      return '$formatted đ';
    }
    final str = value.toString().trim();
    if (str.isEmpty) return '0 đ';
    // Nếu chuỗi đã có định dạng chuẩn số.000 đ thì giữ hoặc chuẩn hóa lại
    final digitsOnly = str.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return '0 đ';
    final n = int.tryParse(digitsOnly) ?? 0;
    final digits = n.toString();
    final formatted = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return '$formatted đ';
  }

  /// Định dạng ngày giờ chuẩn: HH:mm dd/MM/yyyy (VD: 16:30 04/11/2026)
  static String formatDateTime(dynamic raw) {
    if (raw == null) {
      final now = DateTime.now();
      return _formatDateTimeObject(now);
    }
    if (raw is Timestamp) {
      return _formatDateTimeObject(raw.toDate());
    }
    if (raw is DateTime) {
      return _formatDateTimeObject(raw);
    }
    if (raw is int) {
      return _formatDateTimeObject(DateTime.fromMillisecondsSinceEpoch(raw));
    }
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed == 'Hôm nay' || trimmed.isEmpty) {
        return _formatDateTimeObject(DateTime.now());
      }
      final parsed = DateTime.tryParse(trimmed);
      if (parsed != null) {
        return _formatDateTimeObject(parsed);
      }
      // Nếu đã có định dạng HH:mm dd/MM/yyyy thì trả về luôn
      if (RegExp(r'^\d{2}:\d{2}\s+\d{2}/\d{2}/\d{4}').hasMatch(trimmed)) {
        return trimmed;
      }
      return trimmed;
    }
    return _formatDateTimeObject(DateTime.now());
  }

  static String _formatDateTimeObject(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    final y = local.year.toString();
    return '$h:$m $d/$mo/$y';
  }

  /// Trích xuất ISO string chuẩn để phục vụ sắp xếp từ gần đến xa (mới nhất lên đầu)
  static String extractIsoDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate().toIso8601String();
    if (raw is DateTime) return raw.toIso8601String();
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw).toIso8601String();
    if (raw is String && raw.isNotEmpty && raw != 'Hôm nay') {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed.toIso8601String();
      return raw;
    }
    return DateTime.now().toIso8601String();
  }

  /// Sắp xếp danh sách đơn hàng từ gần đến xa (mới nhất lên trên cùng)
  static void sortOrders() {
    orders.sort((a, b) {
      final dateA = a['rawCreatedAt'] ?? a['date'] ?? '';
      final dateB = b['rawCreatedAt'] ?? b['date'] ?? '';
      return dateB.compareTo(dateA);
    });
  }

  static String mapStatus(String raw) {
    switch (raw.toLowerCase()) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
      case 'processing':
      case 'approved':
        return 'Đã xác nhận';
      case 'shipping':
      case 'delivering':
        return 'Đang giao';
      case 'completed':
        return 'Đã giao';
      case 'cancelled':
      case 'rejected':
        return 'Đã hủy';
      default:
        return raw;
    }
  }

  static void syncOrderFromFirestore(Map<String, dynamic> data, String id) {
    final orderId = data['id']?.toString() ?? data['orderId']?.toString() ?? id;
    final status = mapStatus(data['status']?.toString() ?? 'pending');
    final total = formatCurrency(data['formattedTotal'] ?? data['total']);
    final customerName = data['customerName']?.toString() ?? 'Khách hàng LUMI';
    final phone = data['phone']?.toString() ?? '';
    final address =
        data['shippingAddress']?.toString() ??
        data['address']?.toString() ??
        '';
    final note = data['note']?.toString() ?? '';
    final paymentMethod = data['paymentMethod']?.toString() ?? 'COD';
    final items = jsonEncode(data['items'] ?? []);

    final rawCreated = data['createdAt'] ?? data['createdAtMillis'] ?? data['date'];
    final formattedDate = formatDateTime(rawCreated);
    final rawIso = extractIsoDate(rawCreated);

    final existingIndex = orders.indexWhere((o) => o['id'] == orderId);
    final map = {
      'id': orderId,
      'date': formattedDate,
      'rawCreatedAt': rawIso,
      'total': total,
      'status': status,
      'customerName': customerName,
      'phone': phone,
      'address': address,
      'note': note,
      'paymentMethod': paymentMethod,
      'items': items,
    };

    if (existingIndex != -1) {
      orders[existingIndex] = map;
    } else {
      orders.add(map);
    }
    sortOrders();
  }

  static void addOrder({
    required String id,
    required String date,
    required String total,
    required String customerName,
    required String phone,
    required String address,
    required String note,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    String status = 'Chờ xác nhận',
    dynamic rawCreatedAt,
  }) {
    final existingIndex = orders.indexWhere((o) => o['id'] == id);
    final formattedDate = formatDateTime(rawCreatedAt ?? date);
    final rawIso = extractIsoDate(rawCreatedAt ?? DateTime.now());
    final formattedTotal = formatCurrency(total);

    final map = {
      'id': id,
      'date': formattedDate,
      'rawCreatedAt': rawIso,
      'total': formattedTotal,
      'status': status,
      'customerName': customerName,
      'phone': phone,
      'address': address,
      'note': note,
      'paymentMethod': paymentMethod,
      'items': jsonEncode(items),
    };

    if (existingIndex != -1) {
      orders[existingIndex] = map;
    } else {
      orders.add(map);
    }
    sortOrders();
  }

  static void cancelOrder(String orderId) {
    final index = orders.indexWhere((order) => order['id'] == orderId);

    if (index != -1) {
      orders[index]['status'] = 'Đã hủy';
    }
  }

  static void completeOrder(String orderId) {
    final index = orders.indexWhere((order) => order['id'] == orderId);

    if (index != -1) {
      orders[index]['status'] = 'Đã giao';
    }
  }
}
