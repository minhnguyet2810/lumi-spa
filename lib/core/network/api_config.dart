import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Centralized API configuration for LUMI SPA.
/// Respects requirement: "Không hardcode base URL trong từng màn hình."
class ApiConfig {
  ApiConfig._();

  static String? _customBaseUrl;

  /// Default backend URL:
  /// - Android Emulator: http://10.0.2.2:3000
  /// - Others (iOS, Web, Desktop): http://localhost:3000
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  static set customBaseUrl(String? url) {
    _customBaseUrl = url?.trim();
  }

  // Endpoints
  static Uri get servicesUri => Uri.parse('$baseUrl/api/services');
  static Uri serviceDetailUri(String id) =>
      Uri.parse('$baseUrl/api/services/$id');
  static Uri get bookingsUri => Uri.parse('$baseUrl/api/bookings');
  static Uri slotsUri(String date, String serviceId) =>
      Uri.parse('$baseUrl/api/bookings/slots?date=$date&serviceId=$serviceId');
  static Uri cancelBookingUri(String id) =>
      Uri.parse('$baseUrl/api/bookings/$id/cancel');
}
