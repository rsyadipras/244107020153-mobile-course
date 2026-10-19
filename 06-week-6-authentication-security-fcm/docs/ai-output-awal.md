Kode program `push-service.dart`:
```dart
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushService {
  PushService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? notifications,
    this.apiClient,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
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
      data: <String, String>{
        'fcm_token': token,
        'platform': 'android',
      },
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
      notificationDetails: const NotificationDetails(
        android: androidDetails,
      ),
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

String routeFromMessage(Map<String, dynamic> data) {
  final route = data['route'] as String? ?? '/';
  return route.startsWith('/') ? route : '/$route';
}

Future<void> initLocalNotifications() =>
    pushService.initializeLocalNotifications();

Future<bool> requestNotificationPermission() =>
    pushService.requestPermission();

Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
}) =>
    pushService.initializeTokenLifecycle(onToken: onToken);

void listenPushMessages(void Function(String route) go) => pushService.listen(go);

Future<void> handleTerminated(void Function(String route) go) =>
    pushService.handleTerminated(go);

Future<void> unsubscribeFromCampusTopic() =>
    pushService.unsubscribeFromCampusTopic();

```

Hasil output AI Clean Architecture:

## 1. Usulan Struktur Feature-First

Struktur awal project:

```text
lib/
├── data/
├── providers/
├── pages/
├── messaging/
└── routes.dart
```

Struktur target feature-first:

```text
lib/
├── core/
│   ├── failures.dart
│   ├── providers.dart
│   └── format.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── auth_session_model.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository_impl.dart
│   │   │   └── sources/
│   │   │       └── token_store.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── auth_session.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── login.dart
│   │   │       └── refresh_session.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── login_page.dart
│   │       └── providers/
│   │           └── auth_providers.dart
│   └── announcements/
│       ├── data/
│       │   ├── models/
│       │   │   └── announcement_model.dart
│       │   ├── repositories/
│       │   │   └── announcement_repository_impl.dart
│       │   └── sources/
│       │       └── announcement_api.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── announcement.dart
│       │   ├── repositories/
│       │   │   └── announcement_repository.dart
│       │   └── usecases/
│       │       └── get_announcements.dart
│       └── presentation/
│           ├── pages/
│           │   ├── home_page.dart
│           │   └── announcement_page.dart
│           └── providers/
│               └── announcement_providers.dart
├── messaging/
│   └── push_service.dart
├── routes.dart
└── main.dart
```

Aturan dependency:

```text
presentation ────────> domain <──────── data
     |                   ^
     |                   |
     └── memakai use case ┘
```

- `domain` tidak mengenal Flutter, Dio, Firebase, atau secure storage.
- `data` mengimplementasikan interface dari `domain`.
- `presentation` hanya membaca state dan memanggil use case/provider.
- `messaging` menangani FCM sebagai infrastructure service.
- `routes.dart` menangani routing, bukan logika bisnis.

## 2. Pemetaan File Lama

| File lama | Tujuan baru | Tindakan |
| --- | --- | --- |
| `lib/data/auth_repository.dart` | Interface dipindahkan ke `auth/domain/repositories/auth_repository.dart`; implementasi ke `auth/data/repositories/auth_repository_impl.dart` | Pecah |
| `lib/data/token_store.dart` | `auth/data/sources/token_store.dart` | Pindah |
| `lib/data/api_client.dart` | `core` atau `announcements/data/sources/announcement_api.dart`, tergantung pemakaian | Pecah/pindah |
| `lib/data/api_errors.dart` | Mapping error ke `core/failures.dart` | Refactor |
| `lib/providers/auth_provider.dart` | `features/auth/presentation/providers/auth_providers.dart` | Pindah dan sederhanakan |
| `lib/pages/login_page.dart` | `features/auth/presentation/pages/login_page.dart` | Pindah |
| `lib/pages/home_page.dart` | `features/announcements/presentation/pages/home_page.dart` | Pindah |
| `lib/pages/announcement_page.dart` | `features/announcements/presentation/pages/announcement_page.dart` | Pindah |
| `lib/messaging/push_service.dart` | Tetap sebagai `messaging/push_service.dart` atau dipindah ke `core/messaging` | Pertahankan |
| `lib/routes.dart` | Tetap di root | Pertahankan |
| `lib/main.dart` | Tetap di root sebagai composition root | Pertahankan |

### Pemisahan `auth_repository.dart`

Sebelum refactor, satu kelas dapat mencampur kontrak, Dio, dan token store:

```text
AuthRepository
├── login()
├── refresh()
├── Dio
└── TokenStore
```

Sesudah refactor:

```text
domain/repositories/auth_repository.dart
└── abstract class AuthRepository

data/repositories/auth_repository_impl.dart
├── Dio
└── TokenStore
```

Contoh kontrak domain:

```dart
abstract class AuthRepository {
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  });

  Future<({AuthSession? session, Failure? failure})> refresh(
    String refreshToken,
  );
}
```

## 3. Use Case dan Risiko Over-Engineering

### Use case diperlukan ketika:

- terdapat validasi bisnis;
- operasi menggabungkan beberapa repository;
- terdapat refresh token;
- request membutuhkan retry;
- terdapat sinkronisasi;
- terdapat sorting atau filtering berdasarkan aturan bisnis;
- beberapa sumber data harus diubah dalam satu operasi.

Use case yang sesuai untuk project ini:

```text
Login
RefreshSession
GetAnnouncements
OpenAnnouncementFromNotification
```

Contoh alur `Login`:

```text
validasi email/password
        ↓
repository.login()
        ↓
simpan session/token
        ↓
kembalikan state authenticated
```

### Use case belum diperlukan ketika:

Operasi hanya meneruskan satu method repository tanpa logika tambahan:

```dart
Future<List<Announcement>> call() {
  return repository.fetchAnnouncements();
}
```

Untuk CRUD sederhana, pola berikut masih wajar:

```text
widget → notifier/provider → repository interface
```

Tidak perlu membuat use case terpisah untuk setiap operasi satu baris seperti
`deleteAnnouncement`, `getAnnouncementById`, atau `clearAnnouncement` jika
belum memiliki aturan bisnis.

### Trade-off

| Keputusan | Keuntungan | Biaya |
| --- | --- | --- |
| Interface repository di domain | Mudah dibuat fake dan diuji | Menambah file dan abstraksi |
| Use case untuk operasi kompleks | Logika bisnis terisolasi | Boilerplate lebih banyak |
| Use case untuk setiap CRUD | Struktur seragam | Over-engineering dan sulit dinavigasi |
| Feature-first | Fitur mudah dipahami dan dihapus | Struktur folder lebih dalam |
| Riverpod sebagai DI | Tidak perlu package tambahan | Provider harus disiplin ditempatkan |
| `Failure` eksplisit | UI menerima pesan yang lebih aman | Semua error harus dipetakan |

Keputusan final: gunakan use case untuk login, refresh session, dan
pengambilan announcements. Untuk operasi presentation sederhana yang hanya
meneruskan repository, gunakan provider/notifier langsung sampai kompleksitas
bisnis meningkat.

## 4. Wiring Dependency Injection dengan Riverpod

### Repository provider

```dart
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    apiClient: ref.watch(apiClientProvider),
    tokenStore: ref.watch(tokenStoreProvider),
  );
});
```

```dart
final announcementRepositoryProvider =
    Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepositoryImpl(
    apiClient: ref.watch(apiClientProvider),
  );
});
```

### Use case provider

```dart
final loginProvider = Provider<Login>((ref) {
  return Login(ref.watch(authRepositoryProvider));
});
```

```dart
final getAnnouncementsProvider = Provider<GetAnnouncements>((ref) {
  return GetAnnouncements(
    ref.watch(announcementRepositoryProvider),
  );
});
```

### Auth state provider

```dart
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    return const AuthState.unauthenticated();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final result = await ref.read(loginProvider).call(
            email: email,
            password: password,
          );

      if (result.failure != null) {
        throw Exception(result.failure!.message);
      }

      return AuthState.authenticated(result.session!);
    });
  }
}
```

### Announcement state provider

```dart
final announcementsProvider =
    FutureProvider<List<Announcement>>((ref) async {
  final result = await ref
      .read(getAnnouncementsProvider)
      .call();

  if (result.failure != null) {
    throw Exception(result.failure!.message);
  }

  return result.items;
});
```

### Presentation

`LoginPage` hanya membaca dan mengubah state:

```dart
final state = ref.watch(authStateProvider);
```

```dart
ref.read(authStateProvider.notifier).login(
  email: email,
  password: password,
);
```

`AnnouncementPage` hanya membaca:

```dart
final announcements = ref.watch(announcementsProvider);
```

Widget tidak boleh melakukan:

```dart
Dio(...)
FlutterSecureStorage(...)
AuthRepositoryImpl(...)
jsonDecode(...)
```

## Keputusan Final

Untuk project `campus_notify`, arsitektur yang dipilih adalah:

1. `auth` dan `announcements` menjadi feature terpisah.
2. Interface repository ditempatkan di `domain`.
3. Implementasi Dio dan secure storage ditempatkan di `data`.
4. Riverpod digunakan sebagai dependency injection.
5. `push_service.dart` tetap menjadi service infrastructure karena dipakai
   untuk FCM.
6. Use case digunakan untuk login, refresh token, dan pengambilan
   announcements.
7. Use case tidak dibuat secara berlebihan untuk setiap CRUD satu baris.
8. Semua exception teknis dipetakan menjadi `Failure` sebelum mencapai UI.
9. Domain diuji dengan fake repository tanpa Dio, Firebase, atau jaringan.
10. UI harus tetap memiliki perilaku yang sama setelah refactor.
