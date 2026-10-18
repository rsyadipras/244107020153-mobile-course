// REFRACTORING: Semua route aplikasi dan parsing deep link FCM dipusatkan agar GoRouter dan PushService selalu memakai sumber yang sama.
abstract final class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static const announcementPattern = '/pengumuman/:id';

  static String announcement(String id) => '/pengumuman/$id';
}

// REFRACTORING: Fungsi murni ini tidak membutuhkan Firebase atau BuildContext, sehingga dapat diuji langsung dengan unit test.
String routeFromMessage(Map<String, dynamic> data) {
  final route = data['route'];
  if (route is! String || route.isEmpty) return AppRoutes.home;
  return route.startsWith('/') ? route : '/$route';
}
