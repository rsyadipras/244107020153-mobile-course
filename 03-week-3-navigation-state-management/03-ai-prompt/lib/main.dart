import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pages/stats_page.dart';

/// ProviderScope menyediakan container Riverpod untuk seluruh aplikasi.
void main() {
  runApp(const ProviderScope(child: StatsApp()));
}

/// Root widget aplikasi contoh.
class StatsApp extends StatelessWidget {
  const StatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Statistik',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const StatsPage(),
    );
  }
}
