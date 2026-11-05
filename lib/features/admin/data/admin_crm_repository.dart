import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/network/api_config.dart';
import 'models/customer_360_model.dart';

class AdminCrmRepository {
  AdminCrmRepository._();
  static final AdminCrmRepository instance = AdminCrmRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Vui lòng đăng nhập quản trị.');
    }
    final result = await user.getIdTokenResult();
    final token = result.token;
    if (token == null) {
      throw StateError('Phiên đăng nhập không hợp lệ.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  /// 1. Lắng nghe danh sách khách hàng trực tiếp từ Firestore theo thời gian thực
  Stream<List<CustomerListItem>> streamAllCustomers() {
    return _usersCol.snapshots().map((snapshot) {
      final list = snapshot.docs.map(CustomerListItem.fromFirestore).toList();
      list.sort((a, b) {
        return b.lifetimeSpent.compareTo(a.lifetimeSpent);
      });
      return list;
    });
  }

  /// 2. Tải danh sách khách hàng và thống kê KPI CRM từ Backend v2 API
  Future<({CustomerKpiStats stats, List<CustomerListItem> customers, int totalCount})>
      fetchCustomersWithMetrics({
    String? query,
    String? tier,
    String? status,
    String? sortBy,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (query != null && query.trim().isNotEmpty) {
        queryParams['q'] = query.trim();
      }
      if (tier != null && tier.isNotEmpty && tier != 'all') {
        queryParams['tier'] = tier;
      }
      if (status != null && status.isNotEmpty && status != 'all') {
        queryParams['status'] = status;
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sortBy'] = sortBy;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/v2/admin/customers')
          .replace(queryParameters: queryParams);

      final headers = await _authHeaders();
      final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded['success'] == true) {
          final stats = CustomerKpiStats.fromMap(decoded['stats'] as Map<String, dynamic>?);
          final rawList = decoded['data'] as List? ?? [];
          final customers = rawList
              .map((item) => CustomerListItem.fromMap(
                    Map<String, dynamic>.from(item),
                    item['id']?.toString() ?? '',
                  ))
              .toList();

          return (
            stats: stats,
            customers: customers,
            totalCount: (decoded['count'] as num?)?.toInt() ?? customers.length,
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ [AdminCrmRepository] fetchCustomersWithMetrics error: $e');
    }

    // Fallback: Đọc trực tiếp từ Firestore nếu API lỗi hoặc không kết nối được
    try {
      final snap = await _usersCol.limit(limit).get();
      final customers = snap.docs.map(CustomerListItem.fromFirestore).toList();
      final stats = CustomerKpiStats(
        totalCustomers: customers.length,
        activeCustomers: customers.where((c) => c.isActive).length,
        suspendedCustomers: customers.where((c) => c.isSuspended).length,
        vipCustomers: customers.where((c) => c.isVip).length,
        averageSpend: customers.isNotEmpty
            ? customers.map((c) => c.lifetimeSpent).reduce((a, b) => a + b) / customers.length
            : 0,
      );
      return (stats: stats, customers: customers, totalCount: customers.length);
    } catch (_) {
      return (stats: const CustomerKpiStats(), customers: <CustomerListItem>[], totalCount: 0);
    }
  }

  /// 3. Lấy hồ sơ khách hàng 360 độ toàn diện (Customer 360 View)
  Future<Customer360Profile> fetchCustomer360(String customerId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/v2/admin/customers/$customerId/360');
      final headers = await _authHeaders();
      final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded['success'] == true && decoded['data'] is Map) {
          return Customer360Profile.fromMap(Map<String, dynamic>.from(decoded['data']));
        }
      }
      throw StateError(res.body.isNotEmpty ? res.body : 'Không thể tải hồ sơ 360 của khách hàng.');
    } catch (e) {
      debugPrint('⚠️ [AdminCrmRepository] fetchCustomer360 error: $e. Thử đọc Firestore fallback...');
      // Fallback Firestore
      final doc = await _usersCol.doc(customerId).get();
      if (!doc.exists) {
        throw StateError('Không tìm thấy tài liệu khách hàng.');
      }
      final data = doc.data() ?? {};
      return Customer360Profile.fromMap({
        'customerId': customerId,
        'uid': customerId,
        ...data,
      });
    }
  }

  /// 4. Điều chỉnh Điểm thưởng & Hạng thành viên (Loyalty Adjustment)
  Future<Map<String, dynamic>> adjustLoyalty({
    required String customerId,
    int pointsDelta = 0,
    String? newTier,
    String reason = '',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v2/admin/customers/$customerId/loyalty-adjust');
    final headers = await _authHeaders();
    final body = jsonEncode({
      'pointsDelta': pointsDelta,
      if (newTier != null && newTier.isNotEmpty) 'newTier': newTier,
      'reason': reason,
    });

    final res = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 10));
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));

    if (res.statusCode == 200 && decoded['success'] == true) {
      return Map<String, dynamic>.from(decoded);
    } else {
      throw StateError(decoded['message']?.toString() ?? 'Không thể điều chỉnh điểm thành viên.');
    }
  }

  /// 5. Khóa hoặc Mở khóa tài khoản khách hàng (Customer Moderation)
  Future<Map<String, dynamic>> moderateCustomer({
    required String customerId,
    required String status,
    String reason = '',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v2/admin/customers/$customerId/moderation');
    final headers = await _authHeaders();
    final body = jsonEncode({
      'status': status,
      'reason': reason,
    });

    final res = await http.patch(uri, headers: headers, body: body).timeout(const Duration(seconds: 10));
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));

    if (res.statusCode == 200 && decoded['success'] == true) {
      return Map<String, dynamic>.from(decoded);
    } else {
      throw StateError(decoded['message']?.toString() ?? 'Không thể điều chỉnh trạng thái tài khoản.');
    }
  }

  /// 6. Cập nhật hồ sơ da liễu, hoạt chất dị ứng & chống chỉ định
  Future<Map<String, dynamic>> updateSkinProfile({
    required String customerId,
    required String skinType,
    List<String> concerns = const [],
    List<String> knownAllergies = const [],
    List<String> contraindications = const [],
    String currentRoutine = '',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v2/admin/customers/$customerId/skin-profile');
    final headers = await _authHeaders();
    final body = jsonEncode({
      'skinType': skinType,
      'concerns': concerns,
      'knownAllergies': knownAllergies,
      'contraindications': contraindications,
      'currentRoutine': currentRoutine,
    });

    final res = await http.patch(uri, headers: headers, body: body).timeout(const Duration(seconds: 10));
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));

    if (res.statusCode == 200 && decoded['success'] == true) {
      return Map<String, dynamic>.from(decoded);
    } else {
      throw StateError(decoded['message']?.toString() ?? 'Không thể cập nhật hồ sơ da liễu.');
    }
  }

  /// 7. Cập nhật thông tin cơ bản của khách hàng (Họ tên, SĐT, Email, Địa chỉ, Ghi chú)
  Future<Map<String, dynamic>> updateCustomerProfile({
    required String customerId,
    String? displayName,
    String? phone,
    String? email,
    String? address,
    String? notes,
    String? gender,
    String? birthday,
  }) async {
    final payload = <String, dynamic>{
      if (displayName != null) 'displayName': displayName.trim(),
      if (phone != null) 'phone': phone.trim(),
      if (email != null) 'email': email.trim(),
      if (address != null) 'address': address.trim(),
      if (notes != null) 'notes': notes.trim(),
      if (gender != null) 'gender': gender.trim(),
      if (birthday != null) 'birthday': birthday.trim(),
    };

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/v2/admin/customers/$customerId');
      final headers = await _authHeaders();
      final res = await http.patch(
        uri,
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode == 200 && decoded['success'] == true) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (e) {
      debugPrint('⚠️ [AdminCrmRepository] updateCustomerProfile API error: $e. Thử ghi Firestore fallback...');
    }

    // Fallback: Cập nhật trực tiếp Firestore
    try {
      final firestoreUpdates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (displayName != null) {
        firestoreUpdates['displayName'] = displayName.trim();
        firestoreUpdates['name'] = displayName.trim();
      }
      if (phone != null) {
        firestoreUpdates['phone'] = phone.trim();
        firestoreUpdates['phoneNumber'] = phone.trim();
      }
      if (email != null) firestoreUpdates['email'] = email.trim();
      if (address != null) {
        firestoreUpdates['address'] = address.trim();
        firestoreUpdates['shippingAddress'] = address.trim();
      }
      if (notes != null) {
        firestoreUpdates['adminNotes'] = notes.trim();
        firestoreUpdates['notes'] = notes.trim();
      }
      if (gender != null) firestoreUpdates['gender'] = gender.trim();
      if (birthday != null) firestoreUpdates['birthday'] = birthday.trim();

      await _usersCol.doc(customerId).set(firestoreUpdates, SetOptions(merge: true));
      return {
        'success': true,
        'message': 'Đã cập nhật thông tin khách hàng thành công.',
      };
    } catch (err) {
      throw StateError('Không thể cập nhật hồ sơ khách hàng: $err');
    }
  }
}

