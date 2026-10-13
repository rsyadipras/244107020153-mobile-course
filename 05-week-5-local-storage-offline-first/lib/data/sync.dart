import 'local/post.dart';
import 'repositories/note_repository.dart';
import 'repositories/post_cache_repository.dart';

Future<int> syncNotes(NoteRepository repository) async {
  final dirtyCount = await repository.countDirty();
  if (dirtyCount == 0) return 0;

  await Future<void>.delayed(const Duration(seconds: 1));
  await repository.markAllSynced();
  return dirtyCount;
}

// Cache dibaca dulu; refresh jaringan berjalan tanpa mengosongkan UI.
Future<List<Post>> loadPostsCacheFirst({
  required PostCacheRepository repository,
  required bool forceOffline,
  required void Function(List<Post>) onRefresh,
}) async {
  final cached = await repository.readCachedPosts();
  if (!forceOffline) {
    _refreshPostsInBackground(repository, onRefresh);
  }
  return cached;
}

Future<void> _refreshPostsInBackground(
  PostCacheRepository repository,
  void Function(List<Post>) onRefresh,
) async {
  try {
    final fresh = await repository.fetchPostsFromNetwork();
    await repository.saveCachedPosts(fresh);
    onRefresh(fresh);
  } catch (_) {
    // Cache tetap menjadi sumber data ketika jaringan tidak tersedia.
  }
}
