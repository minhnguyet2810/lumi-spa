import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lumi_spa/firebase_options.dart';

/// Kênh thông báo Android chuẩn High Importance cho LUMI SPA
const AndroidNotificationChannel _lumiChannel = AndroidNotificationChannel(
  'lumi_notifications_channel', // Id trùng khớp AndroidManifest và Backend push service
  'LUMI Thông báo',
  description: 'Kênh thông báo lịch hẹn, đơn hàng và ưu đãi LUMI SPA',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

/// Top-level background message handler bắt buộc cho FCM khi app đang tắt (terminated) hoặc chạy ngầm (background)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  debugPrint(
    '🔔 [FCM Background] Đã nhận push notification: ${message.messageId}',
  );
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

  /// Khởi tạo Firebase Cloud Messaging (FCM) & Local Notifications
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

      debugPrint(
        '🔔 [FCM Permission] Trạng thái: ${settings.authorizationStatus}',
      );

      // 3. Khởi tạo FlutterLocalNotifications để hiển thị thông báo ngoài màn hình (Status bar) khi app đang mở
      const androidInitSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInitSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidInitSettings,
        iOS: darwinInitSettings,
        macOS: darwinInitSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('👉 [Local Notification Tap]: ${response.payload}');
          if (response.payload != null && response.payload!.isNotEmpty) {
            try {
              final Map<String, dynamic> data =
                  jsonDecode(response.payload!) as Map<String, dynamic>;
              onNotificationTap?.call(RemoteMessage(data: data));
            } catch (_) {}
          }
        },
      );

      // Tạo Notification Channel trên Android với Importance cao nhất (Heads-up notification)
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_lumiChannel);
      }

      // Cấu hình hiển thị thông báo khi app đang chạy ở foreground cho iOS
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

      // 6. Lắng nghe thông báo khi app đang ở foreground (App mở)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          '🔔 [FCM Foreground] Nhận tin: ${message.notification?.title}',
        );

        // a) HIỂN THỊ NOTIFICATION NGOÀI MÀN HÌNH (Status bar / Notification Shade / Heads-up)
        final notification = message.notification;
        if (notification != null) {
          _localNotifications.show(
            id: message.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                _lumiChannel.id,
                _lumiChannel.name,
                channelDescription: _lumiChannel.description,
                icon: '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            payload: jsonEncode(message.data),
          );
        }

        // b) HIỂN THỊ NOTIFICATION TRONG APP (Banner / Snackbar thông báo trong giao diện app)
        onForegroundMessage?.call(message);
      });

      // 7. Lắng nghe sự kiện người dùng bấm vào notification từ thanh Status bar để mở app (khi app chạy ngầm)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
          '👉 [FCM OpenApp] Người dùng bấm vào thông báo: ${message.data}',
        );
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

  /// Hiển thị thủ công một thông báo ngoài màn hình và trong app (Local notification)
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _lumiChannel.id,
            _lumiChannel.name,
            channelDescription: _lumiChannel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: data != null ? jsonEncode(data) : null,
      );
    } catch (e) {
      debugPrint('⚠️ Lỗi hiển thị local notification: $e');
    }
  }

  /// Lưu FCM Device Token vào document của user trên Firestore (users/{userId})
  Future<void> syncTokenToFirestore([String? token]) async {
    final user = _auth.currentUser;
    var tokenToSave = token ?? _cachedToken;
    if (tokenToSave == null || tokenToSave.isEmpty) {
      try {
        // ignore: deprecated_member_use
        _cachedToken = await _fcm.getToken();
        tokenToSave = _cachedToken;
      } catch (_) {}
    }

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
