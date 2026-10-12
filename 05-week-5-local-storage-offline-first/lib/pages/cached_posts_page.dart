import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers/posts_providers.dart';

class CachedPostsPage extends ConsumerWidget {
  const CachedPostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(cachedPostsProvider);
    final offline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cache Posts'),
        actions: [
          const Text('Offline'),
          Switch(
            value: offline,
            onChanged: (value) {
              ref.read(forceOfflineProvider.notifier).setEnabled(value);
              ref.invalidate(cachedPostsProvider);
            },
          ),
          IconButton(
            onPressed: () => ref.read(cachedPostsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: posts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Cache kosong atau jaringan gagal:\n$error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Belum ada cache posts'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(cachedPostsProvider.notifier).refresh(),
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, index) {
                final post = items[index];
                return ListTile(
                  leading: CircleAvatar(child: Text('${post.id}')),
                  title: Text(post.title),
                  subtitle: Text(
                    post.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
