import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/main.dart';

void main() {
  testWidgets('pengguna yang belum login diarahkan ke halaman login', (
    tester,
  ) async {
    final container = ProviderContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MyApp(container: container, enablePush: false),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Login Campus Notify'), findsOneWidget);
    expect(find.text('Masuk untuk melihat pengumuman kampus'), findsOneWidget);
  });
}
