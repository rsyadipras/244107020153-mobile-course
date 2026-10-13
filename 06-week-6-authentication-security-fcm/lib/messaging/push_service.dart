import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final localNotifications = FlutterLocalNotificationsPlugin();
String? pendingDeepLink;
StreamSubscription<String>? _tokenRefreshSubscription;
StreamSubscription<RemoteMessage>? _foregroundSubscription;
StreamSubscription<RemoteMessage>? _openedAppSubscription;
void Function(String route)? _goToRoute;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Jangan mengakses BuildContext, GoRouter, atau Riverpod di isolate ini.
}

Future<bool> requestNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
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

Future<void> initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  await localNotifications.initialize(
    settings: const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: (response) {
      final route = response.payload;
      if (route == null || route.isEmpty) return;
      pendingDeepLink = route;
      _goToRoute?.call(route);
    },
  );
}

String routeFromMessage(Map<String, dynamic> data) {
  final route = data['route'] as String? ?? '/';
  return route.startsWith('/') ? route : '/$route';
}

void listenPushMessages(void Function(String route) go) {
  _goToRoute = go;
  _foregroundSubscription?.cancel();
  _openedAppSubscription?.cancel();

  _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) async {
    final route = routeFromMessage(message.data);
    const androidDetails = AndroidNotificationDetails(
      'pengumuman',
      'Pengumuman Kampus',
      importance: Importance.high,
      priority: Priority.high,
    );
    await localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'Pengumuman',
      body: message.notification?.body ?? '',
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: route,
    );
  });

  _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
    (message) => go(routeFromMessage(message.data)),
  );
}

Future<void> handleTerminated(void Function(String route) go) async {
  final initial = await FirebaseMessaging.instance.getInitialMessage();
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

Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
}) async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await onToken(token);
  }

  await _tokenRefreshSubscription?.cancel();
  _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
    onToken,
  );

  await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
}

Future<void> unsubscribeFromCampusTopic() {
  return FirebaseMessaging.instance.unsubscribeFromTopic('pengumuman-kampus');
}
