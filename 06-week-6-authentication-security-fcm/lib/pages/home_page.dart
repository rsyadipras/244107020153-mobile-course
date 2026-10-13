import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Pengumuman terbaru',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('Jadwal kuliah berubah'),
              subtitle: const Text('Kelas Mobile pindah ke Ruang A2'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/pengumuman/3'),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Praktikum 1 aktif: token disimpan di secure storage dan '
            'route dilindungi oleh autentikasi.',
          ),
        ],
      ),
    );
  }
}
