import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import 'models/admin_user_item.dart';

class AdminUserRepository {
  AdminUserRepository._();
  static final AdminUserRepository instance = AdminUserRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  /// 1. Lắng nghe real-time danh sách người dùng từ Firestore
  Stream<List<AdminUserItem>> streamAllUsers() {
    return _usersCol.snapshots().map((snapshot) {
      final list = snapshot.docs.map(AdminUserItem.fromFirestore).toList();
      list.sort((a, b) {
        final dateA = a.createdAt ?? DateTime(0);
        final dateB = b.createdAt ?? DateTime(0);
        return dateB.compareTo(dateA);
      });
      return list;
    });
  }

  /// 2. Tải danh sách người dùng qua Backend API (kèm thống kê lượt đặt & tổng chi tiêu)
  Future<List<AdminUserItem>> fetchUsersFromApi({String? query, String? role}) async {
    try {
      final queryParams = <String, String>{};
      if (query != null && query.isNotEmpty) queryParams['q'] = query;
      if (role != null && role.isNotEmpty) queryParams['role'] = role;

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin-users').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (data['success'] == true && data['data'] is List) {
          final list = (data['data'] as List)
              .map((item) => AdminUserItem.fromMap(
                    Map<String, dynamic>.from(item),
                    item['id']?.toString() ?? '',
                  ))
              .toList();
          return list;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [AdminUserRepository] Không thể tải người dùng từ API: $e');
    }
    return [];
  }

  /// 3. Dọn dẹp dữ liệu đơn hàng & lịch hẹn thử nghiệm (Reset Test Data)
  Future<Map<String, dynamic>> clearTestData({String target = 'all'}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin-dev/clear-test-data');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'target': target}),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (e) {
      debugPrint('⚠️ [AdminUserRepository] Lỗi dọn dẹp dữ liệu test: $e');
    }
    return {'success': false, 'message': 'Không thể kết nối Backend để dọn dẹp.'};
  }
}
