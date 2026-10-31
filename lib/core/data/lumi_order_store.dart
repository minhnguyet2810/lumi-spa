import 'dart:convert';

class LumiOrderStore {
  static final List<Map<String, String>> orders = [
    {
      'id': 'LUMI-123456',
      'date': '29/10/2026',
      'total': '450.000 đ',
      'status': 'Chờ xác nhận',
      'customerName': 'Khách hàng LUMI',
      'phone': '',
      'address': '',
      'note': '',
      'paymentMethod': 'Thanh toán khi nhận hàng',
      'items': '[]',
    },
    {
      'id': 'LUMI-987654',
      'date': '20/10/2026',
      'total': '680.000 đ',
      'status': 'Đã giao',
      'customerName': 'Khách hàng LUMI',
      'phone': '',
      'address': '',
      'note': '',
      'paymentMethod': 'Thanh toán khi nhận hàng',
      'items': '[]',
    },
  ];

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
    orders.insert(0, {
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
    });
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