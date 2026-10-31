import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import 'models/admin_order_item.dart';

class AdminOrderRepository {
  AdminOrderRepository._();
  static final AdminOrderRepository instance = AdminOrderRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersCol =>
      _firestore.collection('orders');

  CollectionReference<Map<String, dynamic>> get _notificationsCol =>
      _firestore.collection('notifications');

  /// 1. Lắng nghe real-time toàn bộ đơn hàng
  Stream<List<AdminOrderItem>> streamAllOrders() {
    return _ordersCol.snapshots().map((snapshot) {
      final list = snapshot.docs.map(AdminOrderItem.fromFirestore).toList();
      list.sort((a, b) {
        final dateA = a.createdAt ?? DateTime(0);
        final dateB = b.createdAt ?? DateTime(0);
        return dateB.compareTo(dateA);
      });
      return list;
    });
  }

  /// 2. Lắng nghe real-time các đơn chờ duyệt (pending)
  Stream<List<AdminOrderItem>> streamPendingOrders() {
    return _ordersCol
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map(AdminOrderItem.fromFirestore).toList();
      list.sort((a, b) {
        final dateA = a.createdAt ?? DateTime(0);
        final dateB = b.createdAt ?? DateTime(0);
        return dateB.compareTo(dateA);
      });
      return list;
    });
  }

  /// 3. Cập nhật trạng thái đơn hàng (Duyệt, Giao hàng, Hoàn thành, Hủy)
  /// Đồng thời:
  /// - Ghi trạng thái mới vào Firestore
  /// - Tạo thông báo In-App trong collection `notifications`
  /// - Gọi Backend API để gửi Gmail xác nhận & Bắn FCM Push Notification
  Future<void> updateOrderStatus({
    required AdminOrderItem order,
    required String newStatus,
    String? reason,
  }) async {
    try {
      final batch = _firestore.batch();
      final docRef = _ordersCol.doc(order.id);

      final updatePayload = <String, dynamic>{
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (reason != null && reason.trim().isNotEmpty) {
        updatePayload['cancelReason'] = reason.trim();
      }

      batch.update(docRef, updatePayload);

      // Ghi thông báo in-app cho khách
      if (order.userId.isNotEmpty) {
        final notifRef = _notificationsCol.doc();
        final statusLabels = {
          'confirmed': 'đã được duyệt và đang chuẩn bị hàng ✨',
          'shipping': 'đang trên đường vận chuyển đến bạn 🚚',
          'completed': 'đã được giao thành công 🎉',
          'cancelled': 'đã bị hủy${reason != null && reason.isNotEmpty ? ": $reason" : ""} ⚠️',
        };
        final statusDesc = statusLabels[newStatus] ?? 'đã chuyển sang trạng thái "$newStatus"';

        batch.set(notifRef, {
          'userId': order.userId,
          'title': newStatus == 'cancelled' ? 'Đơn hàng đã bị hủy ⚠️' : 'Cập nhật đơn hàng 🛍️',
          'message': 'Đơn hàng #${order.id} $statusDesc.',
          'type': 'order',
          'orderId': order.id,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('✅ [Admin] Đã cập nhật trạng thái đơn #${order.id} -> $newStatus');

      // Gọi Backend API để gửi Gmail & Bắn Push Notification FCM
      _notifyBackend(
        order: order,
        status: newStatus,
        reason: reason,
      );
    } catch (e) {
      debugPrint('❌ [Admin] Lỗi cập nhật đơn hàng: $e');
      rethrow;
    }
  }

  /// Gọi API backend để kích hoạt gửi Gmail và Push Notification
  Future<void> _notifyBackend({
    required AdminOrderItem order,
    required String status,
    String? reason,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/orders/${order.id}/notify-status');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'status': status,
              'reason': reason ?? '',
              'customerEmail': order.customerEmail,
              'customerName': order.customerName,
              'items': order.items,
              'total': order.total,
              'shippingAddress': order.shippingAddress,
              'phone': order.phone,
              'paymentMethod': order.paymentMethod,
              'userId': order.userId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('📧 [Admin] Đã kích hoạt gửi Gmail & Push cho đơn #${order.id}');
      } else {
        debugPrint('⚠️ [Admin] Backend notify status status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ [Admin] Không thể kết nối backend để gửi email (offline hoặc timeout): $e');
    }
  }
}
