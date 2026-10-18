import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pages/announcement_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'messaging/push_service.dart';
import 'providers/auth_provider.dart';
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await initLocalNotifications();

  final container = ProviderContainer();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MyApp(container: container),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.container, this.enablePush = true});

  final ProviderContainer container;
  final bool enablePush;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;
  late final _AuthRouterRefresh _routerRefresh;

  @override
  void initState() {
    super.initState();
    _routerRefresh = _AuthRouterRefresh();
    widget.container.listen<AsyncValue<bool>>(
      authStateProvider,
      (previous, next) => _routerRefresh.notify(),
    );
    _router = GoRouter(
      refreshListenable: _routerRefresh,
      redirect: (context, state) {
        final loggedIn =
            widget.container.read(authStateProvider).value ?? false;
        final goingLogin = state.matchedLocation == AppRoutes.login;
        if (!loggedIn && !goingLogin) return AppRoutes.login;
        if (loggedIn && goingLogin) return AppRoutes.home;
        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: AppRoutes.announcementPattern,
          builder: (_, state) =>
              AnnouncementPage(id: state.pathParameters['id'] ?? ''),
        ),
      ],
    );
    if (widget.enablePush) {
      pushService.listen(_router.go);
      pushService.handleTerminated(_router.go);
    }
  }

  @override
  void dispose() {
    _router.dispose();
    _routerRefresh.dispose();
    if (widget.enablePush) {
      pushService.dispose();
    }
    widget.container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Campus Notify',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

class _AuthRouterRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}
