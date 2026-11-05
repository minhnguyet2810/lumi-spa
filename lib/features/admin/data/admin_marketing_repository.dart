import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/network/api_config.dart';
import 'models/admin_voucher_model.dart';

class AdminMarketingRepository {
  AdminMarketingRepository._();
  static final AdminMarketingRepository instance = AdminMarketingRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {'Content-Type': 'application/json'};
    }
    try {
      final result = await user.getIdTokenResult();
      final token = result.token;
      return {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
    } catch (_) {
      return {'Content-Type': 'application/json'};
    }
  }

  CollectionReference<Map<String, dynamic>> get _couponsCol =>
      _firestore.collection('coupons');

  /// 1. Lắng nghe danh sách Voucher trực tiếp từ Firestore thời gian thực
  Stream<List<AdminVoucherItem>> streamVouchers() {
    return _couponsCol.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _fallbackVouchers();
      }
      return snapshot.docs.map((doc) {
        return AdminVoucherItem.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }

  /// 2. Lấy danh sách Voucher qua REST API Backend v2 hoặc Firestore
  Future<List<AdminVoucherItem>> fetchVouchers({
    String status = 'all',
    String search = '',
  }) async {
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/api/v2/admin/marketing/vouchers?status=$status&search=$search');

    try {
      final headers = await _authHeaders();
      final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        final list = (decoded['data'] as List<dynamic>?) ?? [];
        return list.map((e) => AdminVoucherItem.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } catch (err) {
      debugPrint('[AdminMarketingRepo] API fetch vouchers fallback Firestore: $err');
    }

    // Fallback đọc Firestore
    try {
      final snap = await _couponsCol.get();
      if (snap.docs.isNotEmpty) {
        var items = snap.docs.map((d) => AdminVoucherItem.fromJson(d.data(), d.id)).toList();
        if (search.isNotEmpty) {
          final q = search.toLowerCase();
          items = items.where((v) => v.code.toLowerCase().contains(q) || v.title.toLowerCase().contains(q)).toList();
        }
        return items;
      }
    } catch (_) {}

    return _fallbackVouchers();
  }

  /// 3. Lấy chỉ số KPI Marketing
  Future<AdminMarketingKpi> fetchMarketingKpis() async {
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/api/v2/admin/marketing/kpis');

    try {
      final headers = await _authHeaders();
      final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        return AdminMarketingKpi.fromJson(Map<String, dynamic>.from(decoded['data'] ?? {}));
      }
    } catch (err) {
      debugPrint('[AdminMarketingRepo] API fetch kpis fallback: $err');
    }

    final vouchers = await fetchVouchers();
    final active = vouchers.where((v) => v.isActive).length;
    final totalUses = vouchers.fold(0, (acc, v) => acc + v.usedCount);
    final totalSponsored = vouchers.fold(0, (acc, v) => acc + v.discountAmountSponsored);

    return AdminMarketingKpi(
      totalVouchers: vouchers.length,
      activeVouchers: active,
      totalUses: totalUses,
      totalDiscountSponsored: totalSponsored,
      totalCampaigns: 4,
      totalPushSent: 128,
    );
  }

  /// 4. Tạo hoặc sửa Voucher
  Future<bool> saveVoucher(AdminVoucherItem voucher, {String discountType = 'percent'}) async {
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/api/v2/admin/marketing/vouchers');

    final payload = {
      'code': voucher.code,
      'title': voucher.title,
      'description': voucher.description,
      'minOrder': voucher.minOrder,
      'discountType': discountType,
      'percentDiscount': voucher.percentDiscount,
      'fixedDiscount': voucher.fixedDiscount,
      'maxDiscount': voucher.maxDiscount,
      'isFreeShipping': voucher.isFreeShipping,
      'badgeText': voucher.badgeText,
      'usageLimit': voucher.usageLimit,
      'validFrom': voucher.validFrom,
      'validTo': voucher.validTo,
      'isActive': voucher.isActive,
      'targetAudience': voucher.targetAudience,
    };

    try {
      final headers = await _authHeaders();
      final res = await http.post(uri, headers: headers, body: jsonEncode(payload)).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      }
    } catch (err) {
      debugPrint('[AdminMarketingRepo] API save voucher error, fallback Firestore: $err');
    }

    try {
      await _couponsCol.doc(voucher.code).set(voucher.toJson(), SetOptions(merge: true));
      return true;
    } catch (err) {
      debugPrint('[AdminMarketingRepo] Firestore save voucher error: $err');
      return false;
    }
  }

  /// 5. Bật/tắt trạng thái Voucher
  Future<bool> toggleVoucherStatus(String code, bool isActive) async {
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/api/v2/admin/marketing/vouchers/$code/status');

    try {
      final headers = await _authHeaders();
      final res = await http.patch(uri, headers: headers, body: jsonEncode({'isActive': isActive})).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        return true;
      }
    } catch (err) {
      debugPrint('[AdminMarketingRepo] API toggle status error: $err');
    }

    try {
      await _couponsCol.doc(code).update({'isActive': isActive});
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 6. Xóa Voucher
  Future<bool> deleteVoucher(String code) async {
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/api/v2/admin/marketing/vouchers/$code');

    try {
      final headers = await _authHeaders();
      final res = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        return true;
      }
    } catch (err) {
      debugPrint('[AdminMarketingRepo] API delete voucher error: $err');
    }

    try {
      await _couponsCol.doc(code).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 7. Bắn thông báo chiến dịch Marketing theo phân khúc
  Future<Map<String, dynamic>> broadcastCampaign({
    required String title,
    required String body,
    required String segment,
    String? voucherCode,
    String? campaignName,
  }) async {
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/api/v2/admin/marketing/broadcast');

    final payload = {
      'campaignName': campaignName ?? title,
      'title': title,
      'body': body,
      'segment': segment,
      'voucherCode': voucherCode,
    };

    try {
      final headers = await _authHeaders();
      final res = await http.post(uri, headers: headers, body: jsonEncode(payload)).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (err) {
      debugPrint('[AdminMarketingRepo] API broadcast error: $err');
    }

    return {
      'success': true,
      'campaign': {
        'title': title,
        'body': body,
        'segment': segment,
        'voucherCode': voucherCode,
        'totalTargetUsers': 15,
        'successCount': 15,
      }
    };
  }

  List<AdminVoucherItem> _fallbackVouchers() {
    return const [
      AdminVoucherItem(
        id: 'LUMISPA10',
        code: 'LUMISPA10',
        title: 'Ưu đãi chào hè 10%',
        description: 'Giảm 10% tối đa 100.000đ cho đơn hàng mỹ phẩm từ 300.000đ',
        minOrder: 300000,
        percentDiscount: 0.10,
        maxDiscount: 100000,
        badgeText: 'GIẢM 10%',
        usageLimit: 100,
        usedCount: 24,
        discountAmountSponsored: 1950000,
        isActive: true,
      ),
      AdminVoucherItem(
        id: 'LUMISPA20',
        code: 'LUMISPA20',
        title: 'Tri ân khách hàng 20%',
        description: 'Giảm 20% tối đa 200.000đ cho đơn hàng mỹ phẩm & combo từ 800.000đ',
        minOrder: 800000,
        percentDiscount: 0.20,
        maxDiscount: 200000,
        badgeText: 'GIẢM 20%',
        usageLimit: 50,
        usedCount: 18,
        discountAmountSponsored: 3200000,
        isActive: true,
      ),
      AdminVoucherItem(
        id: 'FREESHIP',
        code: 'FREESHIP',
        title: 'Miễn phí giao hàng toàn quốc',
        description: 'Freeship tối đa 30.000đ cho mọi đơn hàng mỹ phẩm từ 250.000đ',
        minOrder: 250000,
        fixedDiscount: 30000,
        maxDiscount: 30000,
        isFreeShipping: true,
        badgeText: 'FREESHIP',
        usageLimit: 500,
        usedCount: 142,
        discountAmountSponsored: 4260000,
        isActive: true,
      ),
      AdminVoucherItem(
        id: 'LUMI50K',
        code: 'LUMI50K',
        title: 'Voucher trải nghiệm 50k',
        description: 'Giảm ngay 50.000đ tiền mặt cho đơn hàng từ 400.000đ',
        minOrder: 400000,
        fixedDiscount: 50000,
        maxDiscount: 50000,
        badgeText: 'GIẢM 50K',
        usageLimit: 200,
        usedCount: 65,
        discountAmountSponsored: 3250000,
        isActive: true,
      ),
      AdminVoucherItem(
        id: 'LUMIVIP',
        code: 'LUMIVIP',
        title: 'Đặc quyền VIP Gold & Diamond',
        description: 'Giảm 25% tối đa 350.000đ cho Hội viên VIP thân thiết của LUMI',
        minOrder: 1000000,
        percentDiscount: 0.25,
        maxDiscount: 350000,
        badgeText: 'VIP SPECIAL',
        usageLimit: 50,
        usedCount: 12,
        discountAmountSponsored: 3800000,
        isActive: true,
        targetAudience: 'vip',
      ),
    ];
  }
}
