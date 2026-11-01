import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:lumi_spa/core/data/lumi_catalog_repository.dart';
import 'package:lumi_spa/core/network/api_config.dart';
import 'package:lumi_spa/features/booking/data/models/booking_item.dart';

class BookingApiException implements Exception {
  final String message;
  final int? statusCode;

  BookingApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class BookingApiService {
  BookingApiService._();
  static final BookingApiService instance = BookingApiService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> _requireToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw BookingApiException(
        'Vui lòng đăng nhập để thực hiện thao tác này.',
        statusCode: 401,
      );
    }
    String? token;
    try {
      token = await user.getIdToken(true);
    } catch (_) {
      token = await user.getIdToken();
    }
    if (token == null || token.isEmpty) {
      throw BookingApiException(
        'Không lấy được mã xác thực. Vui lòng đăng nhập lại.',
        statusCode: 401,
      );
    }
    return token;
  }

  /// GET /api/services
  Future<List<Map<String, dynamic>>> getServices() async {
    try {
      final response = await http.get(ApiConfig.servicesUri).timeout(
            const Duration(seconds: 4),
          );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is List) {
          return List<Map<String, dynamic>>.from(
            (body['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
          );
        }
      }
    } catch (_) {}
    return LumiCatalogRepository.fetchServices();
  }

  /// GET /api/services/:id
  Future<Map<String, dynamic>?> getServiceDetail(String id) async {
    try {
      final response = await http.get(ApiConfig.serviceDetailUri(id)).timeout(
            const Duration(seconds: 4),
          );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is Map) {
          return Map<String, dynamic>.from(body['data'] as Map);
        }
      }
    } catch (_) {}

    final all = await LumiCatalogRepository.fetchServices();
    return all.firstWhere((s) => s['id'] == id, orElse: () => <String, dynamic>{});
  }

  /// GET /api/bookings/slots (Kiểm tra slot trống từ server)
  Future<List<Map<String, dynamic>>> getAvailableSlots(String date, String serviceId) async {
    try {
      final response = await http
          .get(ApiConfig.slotsUri(date, serviceId))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data']?['slots'] is List) {
          return List<Map<String, dynamic>>.from(
            (body['data']['slots'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
          );
        }
      }
    } catch (_) {}
    return [];
  }

  /// POST /api/bookings
  Future<BookingItem> createBooking({
    required String serviceId,
    required String date, // YYYY-MM-DD
    required int hour, // 9-17
    required String contactName,
    required String contactPhone,
  }) async {
    final token = await _requireToken();

    http.Response response;
    try {
      response = await http.post(
        ApiConfig.bookingsUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'serviceId': serviceId,
          'date': date,
          'hour': hour,
          'contactName': contactName.trim(),
          'contactPhone': contactPhone.trim(),
        }),
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      throw BookingApiException(
        'Không thể kết nối đến máy chủ backend (port 3000). Vui lòng kiểm tra server Node.js đang chạy.',
      );
    }

    Map<String, dynamic> body = {};
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}

    if (response.statusCode == 201 && body['success'] == true) {
      final data = Map<String, dynamic>.from(body['data'] as Map? ?? {});
      return BookingItem.fromJson(data);
    }

    if (response.statusCode == 409) {
      final msg = body['message']?.toString() ??
          'Khung giờ này đã kín phòng hoặc không còn chuyên viên trống. Vui lòng chọn thời gian khác.';
      throw BookingApiException(msg, statusCode: 409);
    }

    final message = body['message']?.toString() ??
        'Đã xảy ra lỗi khi đặt lịch (${response.statusCode}).';
    throw BookingApiException(message, statusCode: response.statusCode);
  }

  /// GET /api/bookings
  Future<List<BookingItem>> getMyBookings() async {
    final token = await _requireToken();

    http.Response response;
    try {
      response = await http.get(
        ApiConfig.bookingsUri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      throw BookingApiException(
        'Không thể kết nối máy chủ. Kiểm tra backend local tại ${ApiConfig.baseUrl}.',
      );
    }

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] is List) {
        return (body['data'] as List)
            .map((item) => BookingItem.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>?;
    final message = body?['message']?.toString() ?? 'Không thể tải danh sách lịch hẹn.';
    throw BookingApiException(message, statusCode: response.statusCode);
  }

  /// PATCH /api/bookings/:id/cancel
  Future<void> cancelBooking(String bookingId) async {
    final token = await _requireToken();

    http.Response response;
    try {
      response = await http.patch(
        ApiConfig.cancelBookingUri(bookingId),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      throw BookingApiException(
        'Không thể kết nối máy chủ để hủy lịch hẹn.',
      );
    }

    if (response.statusCode == 200) {
      return;
    }

    Map<String, dynamic> body = {};
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}

    final message = body['message']?.toString() ?? 'Không thể hủy lịch hẹn.';
    throw BookingApiException(message, statusCode: response.statusCode);
  }
}
