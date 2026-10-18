import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../routes.dart';

class PushService {
  PushService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? notifications,
    this.apiClient,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _notifications;
  final Dio? apiClient;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  void Function(String route)? _goToRoute;
  String? pendingDeepLink;

  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> initializeLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notifications.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final route = response.payload;
        if (route == null || route.isEmpty) return;
        pendingDeepLink = route;
        _goToRoute?.call(route);
      },
    );
  }

  Future<void> initializeTokenLifecycle({
    Future<void> Function(String token)? onToken,
  }) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _registerToken(token, onToken);
    }

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
      _registerToken(token, onToken);
    });
    await _messaging.subscribeToTopic('pengumuman-kampus');
  }

  Future<void> _registerToken(
    String token,
    Future<void> Function(String token)? onToken,
  ) async {
    if (onToken != null) {
      await onToken(token);
      return;
    }
    final client = apiClient;
    if (client == null) return;
    await client.post(
      '/devices',
      data: <String, String>{'fcm_token': token, 'platform': 'android'},
    );
  }

  void listen(void Function(String route) go) {
    _goToRoute = go;
    _foregroundSubscription?.cancel();
    _openedAppSubscription?.cancel();

    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      _showForegroundNotification(message);
    });
    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => go(routeFromMessage(message.data)),
    );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final route = routeFromMessage(message.data);
    const androidDetails = AndroidNotificationDetails(
      'pengumuman',
      'Pengumuman Kampus',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _notifications.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'Pengumuman',
      body: message.notification?.body ?? '',
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: route,
    );
  }

  Future<void> handleTerminated(void Function(String route) go) async {
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      go(routeFromMessage(initial.data));
      return;
    }
    final route = pendingDeepLink;
    if (route != null) {
      pendingDeepLink = null;
      go(route);
    }
  }

  Future<void> unsubscribeFromCampusTopic() {
    return _messaging.unsubscribeFromTopic('pengumuman-kampus');
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
  }
}

PushService? _pushService;
PushService get pushService => _pushService ??= PushService();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background isolate: jangan akses BuildContext, GoRouter, Riverpod,
  // atau state UI. Simpan/catat data ringan saja.
}

Future<void> initLocalNotifications() =>
    pushService.initializeLocalNotifications();

Future<bool> requestNotificationPermission() => pushService.requestPermission();

Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
}) => pushService.initializeTokenLifecycle(onToken: onToken);

void listenPushMessages(void Function(String route) go) =>
    pushService.listen(go);

Future<void> handleTerminated(void Function(String route) go) =>
    pushService.handleTerminated(go);

Future<void> unsubscribeFromCampusTopic() =>
    pushService.unsubscribeFromCampusTopic();
