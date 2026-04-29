import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import '../../firebase_options.dart';
import '../constants/storage_keys.dart';
import '../constants/supabase_tables.dart';
import '../notifications/notification_deep_link_router.dart';
import '../notifications/notification_route_payload.dart';
import '../storage/local_storage.dart';

/// FCM + local notifications. Degrades gracefully when Firebase is not configured.
class PushNotificationService {
  PushNotificationService(this._localStorage);

  final LocalStorage _localStorage;
  final Logger _log = Logger();

  static const _androidChannelId = 'habra_high_importance';
  static const _androidChannelName = 'Habra notifications';
  static const _androidChannelDescription = 'Important updates from Habra';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _firebaseReady = false;
  FirebaseMessaging? _messaging;
  NotificationRoutePayload? _pendingDeepLink;
  StreamSubscription<String>? _tokenRefreshSub;
  String? _lastSyncedUserId;

  static String _pushPrefKey(String userId) =>
      '${StorageKeys.ownerPushNotificationsEnabled}_$userId';

  Future<bool> _isUserPushEnabled(String userId) async {
    final v = await _localStorage.getBool(_pushPrefKey(userId));
    return v ?? true;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) return;

    if (!DefaultFirebaseOptions.isConfigured) {
      _log.w(
        'Firebase not configured (placeholder firebase_options.dart). '
        'Push is disabled. Run: dart pub global activate flutterfire_cli && flutterfire configure',
      );
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _firebaseReady = true;
    } catch (e, st) {
      _log.w('Firebase init skipped or failed (add firebase_options / native config): $e',
          stackTrace: st);
      return;
    }

    _messaging = FirebaseMessaging.instance;

    try {
      await _messaging!.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e, st) {
      _log.w('setForegroundNotificationPresentationOptions: $e', stackTrace: st);
    }

    await _setupLocalNotifications();

    try {
      final initial = await _messaging!.getInitialMessage();
      if (initial != null) {
        _pendingDeepLink = NotificationRoutePayload.fromRemoteMessage(initial);
      }
    } catch (e, st) {
      _log.w('getInitialMessage: $e', stackTrace: st);
    }

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final payload = NotificationRoutePayload.fromRemoteMessage(message);
      NotificationDeepLinkRouter.openFromPayload(payload);
    });

    _tokenRefreshSub = _messaging!.onTokenRefresh.listen(
      (token) => unawaited(_onTokenRefreshed(token)),
      onError: (Object e, StackTrace st) =>
          _log.w('onTokenRefresh error: $e', stackTrace: st),
    );
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _androidChannelId,
          _androidChannelName,
          description: _androidChannelDescription,
          importance: Importance.high,
        ),
      );
    }
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    final payload = NotificationRoutePayload.fromLocalNotificationPayload(
      response.payload,
    );
    NotificationDeepLinkRouter.openFromPayload(payload);
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Habra';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        '';

    try {
      await _localNotifications.show(
        message.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannelId,
            _androidChannelName,
            channelDescription: _androidChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    } catch (e, st) {
      _log.w('Foreground local notification: $e', stackTrace: st);
    }
  }

  Future<void> _onTokenRefreshed(String token) async {
    final uid = _lastSyncedUserId;
    if (uid == null) return;
    if (!await _isUserPushEnabled(uid)) return;
    await _uploadToken(uid, token, isRetry: true);
  }

  /// Call after the main navigator is ready (e.g. from [MainNavigationWrapper]).
  void consumePendingDeepLink() {
    final p = _pendingDeepLink;
    _pendingDeepLink = null;
    if (p == null) return;
    NotificationDeepLinkRouter.openFromPayload(p);
  }

  /// Registers device token for [userId] when push is enabled in settings.
  Future<void> registerTokenForUser(String userId) async {
    if (kIsWeb) return;
    if (!_firebaseReady || _messaging == null) return;

    if (!await _isUserPushEnabled(userId)) {
      await clearTokenForUser(userId);
      return;
    }

    try {
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _log.i('FCM permission denied');
        return;
      }
    } catch (e, st) {
      _log.w('requestPermission: $e', stackTrace: st);
    }

    String? token;
    try {
      token = await _messaging!.getToken();
    } catch (e, st) {
      _log.w('getToken: $e', stackTrace: st);
      return;
    }

    if (token == null || token.isEmpty) return;

    _lastSyncedUserId = userId;
    await _uploadToken(userId, token, isRetry: false);
  }

  Future<void> _uploadToken(
    String userId,
    String token, {
    required bool isRetry,
  }) async {
    try {
      await Supabase.instance.client
          .from(SupabaseTables.profiles)
          .update({'fcm_token': token})
          .eq('id', userId);
    } catch (e, st) {
      _log.w('fcm_token upload failed: $e', stackTrace: st);
      if (!isRetry) {
        await Future<void>.delayed(const Duration(seconds: 3));
        try {
          await Supabase.instance.client
              .from(SupabaseTables.profiles)
              .update({'fcm_token': token})
              .eq('id', userId);
        } catch (e2, st2) {
          _log.w('fcm_token retry failed: $e2', stackTrace: st2);
        }
      }
    }
  }

  /// Clears server-side token (call on logout or when user disables push).
  Future<void> clearTokenForUser(String userId) async {
    _lastSyncedUserId = null;
    if (kIsWeb) return;

    try {
      await Supabase.instance.client
          .from(SupabaseTables.profiles)
          .update({'fcm_token': null}).eq('id', userId);
    } catch (e, st) {
      _log.w('clear fcm_token failed: $e', stackTrace: st);
    }

    if (_firebaseReady && _messaging != null) {
      try {
        await _messaging!.deleteToken();
      } catch (e, st) {
        _log.w('deleteToken: $e', stackTrace: st);
      }
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }
}
