import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/format.dart';
import '../../../../routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/announcement_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(announcementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(announcementsProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Pengumuman terbaru',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Gagal memuat: $err')),
              data: (items) => Column(
                children: items.map((item) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.notifications_active_outlined),
                      title: Text(item.title),
                      subtitle: Text(
                        '${item.body}\n${formatDate(item.publishedAt)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          context.go(AppRoutes.announcement('${item.id ?? 1}')),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Praktikum Clean Architecture Feature-First aktif: '
              'Fitur Auth dan Announcements terisolasi rapi.',
            ),
          ],
        ),
      ),
    );
  }
}
