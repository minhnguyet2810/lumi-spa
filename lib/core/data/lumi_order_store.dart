import 'dart:convert';

class LumiOrderStore {
  static final List<Map<String, String>> orders = [
    {
      'id': 'LUMI-123456',
      'date': '29/10/2026',
      'total': '450.000 đ',
      'status': 'Chờ xác nhận',
      'customerName': 'Khách hàng LUMI',
      'phone': '0912345678',
      'address': 'Số 123 Đường Nguyễn Trãi, Quận 1, TP. HCM',
      'note': 'Giao trong giờ hành chính',
      'paymentMethod': 'Thanh toán khi nhận hàng',
      'items': '[]',
    },
    {
      'id': 'LUMI-987654',
      'date': '20/10/2026',
      'total': '680.000 đ',
      'status': 'Đã giao',
      'customerName': 'Khách hàng LUMI',
      'phone': '0987654321',
      'address': 'Số 45 Lê Lợi, Quận 1, TP. HCM',
      'note': '',
      'paymentMethod': 'Thanh toán khi nhận hàng',
      'items': '[]',
    },
  ];

  static String mapStatus(String raw) {
    switch (raw.toLowerCase()) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
      case 'processing':
        return 'Chờ xác nhận';
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
    final total = data['formattedTotal']?.toString() ?? '${data['total'] ?? 0} đ';
    final customerName = data['customerName']?.toString() ?? 'Khách hàng LUMI';
    final phone = data['phone']?.toString() ?? '';
    final address = data['shippingAddress']?.toString() ?? data['address']?.toString() ?? '';
    final note = data['note']?.toString() ?? '';
    final paymentMethod = data['paymentMethod']?.toString() ?? 'COD';
    final items = jsonEncode(data['items'] ?? []);

    final existingIndex = orders.indexWhere((o) => o['id'] == orderId);
    final map = {
      'id': orderId,
      'date': data['date']?.toString() ?? 'Hôm nay',
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
      orders.insert(0, map);
    }
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
  }) {
    final existingIndex = orders.indexWhere((o) => o['id'] == id);
    final map = {
      'id': id,
      'date': date,
      'total': total,
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
      orders.insert(0, map);
    }
  }

  static void cancelOrder(String orderId) {
    final index = orders.indexWhere(
      (order) => order['id'] == orderId,
    );

    if (index != -1) {
      orders[index]['status'] = 'Đã hủy';
    }
  }
}
