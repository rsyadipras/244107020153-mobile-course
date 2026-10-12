import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/post.dart';
import '../repositories/post_cache_repository.dart';

final forceOfflineProvider = NotifierProvider<ForceOfflineNotifier, bool>(
  ForceOfflineNotifier.new,
);

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setEnabled(bool value) => state = value;
}

final postCacheRepositoryProvider = Provider<PostCacheRepository>(
  (ref) => PostCacheRepository(),
);

final cachedPostsProvider =
    AsyncNotifierProvider<CachedPostsNotifier, List<Post>>(
  CachedPostsNotifier.new,
);

class CachedPostsNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    final repository = ref.read(postCacheRepositoryProvider);
    final cached = await repository.readCachedPosts();
    if (!ref.read(forceOfflineProvider)) {
      unawaited(_refresh(repository, cached.isNotEmpty));
    }
    return cached;
  }

  Future<void> _refresh(
    PostCacheRepository repository,
    bool hasCache,
  ) async {
    try {
      final fresh = await repository.fetchPostsFromNetwork();
      await repository.saveCachedPosts(fresh);
      if (ref.mounted) state = AsyncData(fresh);
    } catch (error, stackTrace) {
      if (!hasCache && ref.mounted) state = AsyncError(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    final repository = ref.read(postCacheRepositoryProvider);
    if (ref.read(forceOfflineProvider)) {
      state = await AsyncValue.guard(repository.readCachedPosts);
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final fresh = await repository.fetchPostsFromNetwork();
      await repository.saveCachedPosts(fresh);
      return fresh;
    });
  }
}
