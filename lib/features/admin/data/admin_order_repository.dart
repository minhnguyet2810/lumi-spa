import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/network/api_config.dart';
import '../../../../core/network/lumi_api_client.dart';
import 'models/admin_order_item.dart';

class AdminOrderRepository {
  AdminOrderRepository._();
  static final AdminOrderRepository instance = AdminOrderRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Vui lòng đăng nhập quản trị.');
    }
    final result = await user.getIdTokenResult();
    if (result.claims?['admin'] != true || result.token == null) {
      throw StateError('Bạn không có quyền quản trị.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${result.token}',
    };
  }

  CollectionReference<Map<String, dynamic>> get _ordersCol =>
      _firestore.collection('orders');

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
    return _ordersCol.where('status', isEqualTo: 'pending').snapshots().map((
      snapshot,
    ) {
      final list = snapshot.docs.map(AdminOrderItem.fromFirestore).toList();
      list.sort((a, b) {
        final dateA = a.createdAt ?? DateTime(0);
        final dateB = b.createdAt ?? DateTime(0);
        return dateB.compareTo(dateA);
      });
      return list;
    });
  }

  /// 2.1 Tải danh sách đơn hàng từ Backend API (Fallback khi Firestore client bị chặn quyền)
  Future<List<AdminOrderItem>> fetchOrdersFromApi({
    String? status,
    String? query,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/admin-orders',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final res = await http
          .get(uri, headers: await _authHeaders())
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (data['success'] == true && data['data'] is List) {
          final list = (data['data'] as List)
              .map(
                (item) => AdminOrderItem.fromMap(
                  Map<String, dynamic>.from(item),
                  item['id']?.toString() ?? '',
                ),
              )
              .toList();
          return list;
        }
      }
    } catch (e) {
      debugPrint(
        '⚠️ [AdminOrderRepository] Không thể tải đơn hàng từ Backend API: $e',
      );
    }
    return [];
  }

  Future<void> updateOrderStatus({
    required AdminOrderItem order,
    required String newStatus,
    String? reason,
  }) async {
    await LumiApiClient.instance.post(
      '/api/admin-orders/${Uri.encodeComponent(order.id)}/status',
      body: {'status': newStatus, 'reason': reason ?? ''},
    );
  }
}
