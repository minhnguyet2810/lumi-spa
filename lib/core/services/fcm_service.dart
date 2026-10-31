import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:lumi_spa/firebase_options.dart';

/// Top-level background message handler bắt buộc cho FCM khi app đang tắt (terminated) hoặc chạy ngầm (background)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  debugPrint('🔔 [FCM Background] Đã nhận push notification: ${message.messageId}');
  debugPrint('Tiêu đề: ${message.notification?.title}');
  debugPrint('Nội dung: ${message.notification?.body}');
  debugPrint('Dữ liệu đính kèm: ${message.data}');
}

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _cachedToken;
  String? get fcmToken => _cachedToken;

  /// Callback khi có push notification đến lúc app đang mở (Foreground)
  void Function(RemoteMessage message)? onForegroundMessage;

  /// Callback khi người dùng bấm vào thông báo trên thanh Status Bar
  void Function(RemoteMessage message)? onNotificationTap;

  /// Khởi tạo Firebase Cloud Messaging (FCM)
  Future<void> initialize() async {
    try {
      // 1. Đăng ký background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 2. Yêu cầu quyền gửi thông báo từ người dùng (Android 13+ & iOS)
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('🔔 [FCM Permission] Trạng thái: ${settings.authorizationStatus}');

      // 3. Cấu hình hiển thị thông báo khi app đang chạy ở foreground
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. Lấy FCM Device Token hiện tại
      try {
        // ignore: deprecated_member_use
        _cachedToken = await _fcm.getToken();
      } catch (_) {}

      if (_cachedToken != null) {
        debugPrint('🔑 [FCM Token]: $_cachedToken');
        await syncTokenToFirestore(_cachedToken);
      }

      // 5. Lắng nghe đăng ký token FCM
      _fcm.onRegistered.listen((newToken) {
        _cachedToken = newToken;
        debugPrint('🔄 [FCM onRegistered]: $newToken');
        syncTokenToFirestore(newToken);
      });

      // ignore: deprecated_member_use
      _fcm.onTokenRefresh.listen((newToken) {
        _cachedToken = newToken;
        debugPrint('🔄 [FCM Token Refresh]: $newToken');
        syncTokenToFirestore(newToken);
      });

      try {
        await _fcm.register();
      } catch (_) {}

      // 6. Lắng nghe thông báo khi app đang ở foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 [FCM Foreground] Nhận tin: ${message.notification?.title}');
        onForegroundMessage?.call(message);
      });

      // 7. Lắng nghe sự kiện người dùng bấm vào notification từ thanh Status bar để mở app
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('👉 [FCM OpenApp] Người dùng bấm vào thông báo: ${message.data}');
        onNotificationTap?.call(message);
      });

      // 8. Kiểm tra xem app có được mở từ trạng thái terminated bằng cách bấm thông báo không
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🚀 [FCM InitialMessage]: ${initialMessage.data}');
        Future.delayed(const Duration(milliseconds: 500), () {
          onNotificationTap?.call(initialMessage);
        });
      }

      // 9. Lắng nghe trạng thái đăng nhập để tự động lưu FCM token cho user đó
      _auth.authStateChanges().listen((user) {
        if (user != null && _cachedToken != null) {
          syncTokenToFirestore(_cachedToken);
        }
      });
    } catch (e) {
      debugPrint('⚠️ [FCM Initialize Error]: $e');
    }
  }

  /// Lưu FCM Device Token vào document của user trên Firestore (users/{userId})
  Future<void> syncTokenToFirestore([String? token]) async {
    final user = _auth.currentUser;
    final tokenToSave = token ?? _cachedToken;

    if (user == null || tokenToSave == null || tokenToSave.isEmpty) {
      return;
    }

    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      await userDoc.set({
        'fcmToken': tokenToSave,
        'fcmTokens': FieldValue.arrayUnion([tokenToSave]),
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('✅ Đã lưu FCM Token vào Firestore users/${user.uid}');
    } catch (e) {
      debugPrint('⚠️ Không thể lưu FCM Token vào Firestore: $e');
    }
  }

  /// Xóa FCM token khi đăng xuất
  Future<void> removeTokenOnLogout() async {
    final user = _auth.currentUser;
    final token = _cachedToken;

    if (user != null && token != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      } catch (_) {}
    }
  }
}
