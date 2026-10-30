import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LumiApiException implements Exception {
  const LumiApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class LumiApiClient {
  LumiApiClient._();

  static final LumiApiClient instance = LumiApiClient._();
  static const _configuredBaseUrl = String.fromEnvironment('LUMI_API_BASE_URL');
  static const _timeout = Duration(seconds: 20);

  Uri get _baseUri {
    if (_configuredBaseUrl.isNotEmpty) {
      return Uri.parse(_configuredBaseUrl);
    }
    if (kIsWeb) return Uri.parse('http://localhost:3000');
    if (defaultTargetPlatform == TargetPlatform.android) {
      return Uri.parse('http://10.0.2.2:3000');
    }
    return Uri.parse('http://localhost:3000');
  }

  Future<Map<String, dynamic>> get(String path) => _request('GET', path);

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) => _request('PATCH', path, body: body);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _baseUri.resolve(path);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const LumiApiException('Vui lòng đăng nhập để tiếp tục.');
    }

    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw const LumiApiException(
        'Không lấy được phiên đăng nhập. Vui lòng đăng nhập lại.',
      );
    }

    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };

    late final http.Response response;
    try {
      if (method == 'GET') {
        response = await http.get(uri, headers: headers).timeout(_timeout);
      } else {
        response = await http
            .patch(uri, headers: headers, body: jsonEncode(body))
            .timeout(_timeout);
      }
    } on Exception catch (error) {
      if (error is LumiApiException) rethrow;
      throw const LumiApiException(
        'Không thể kết nối máy chủ. Hãy kiểm tra mạng và thử lại.',
      );
    }

    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('API response must be a JSON object.');
      }
      payload = decoded;
    } on FormatException {
      throw LumiApiException(
        'Máy chủ trả về dữ liệu không hợp lệ.',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        payload['success'] == false) {
      throw LumiApiException(
        payload['message']?.toString() ??
            'Yêu cầu không thành công (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    return payload;
  }
}
