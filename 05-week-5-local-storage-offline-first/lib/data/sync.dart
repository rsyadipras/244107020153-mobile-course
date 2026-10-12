import 'local/post.dart';
import 'repositories/note_repository.dart';

Future<int> syncNotes(NoteRepository repository) async {
  final dirtyCount = await repository.countDirty();
  if (dirtyCount == 0) return 0;

  await Future<void>.delayed(const Duration(seconds: 1));
  await repository.markAllSynced();
  return dirtyCount;
}

Future<List<Post>> loadPostsCacheFirst({
  required Future<List<Post>> Function() readCache,
  required Future<List<Post>> Function() refreshNetwork,
  required Future<void> Function(List<Post>) saveCache,
  required void Function(List<Post>) onRefresh,
}) async {
  final cached = await readCache();
  refreshNetwork().then((fresh) async {
    await saveCache(fresh);
    onRefresh(fresh);
  });
  return cached;
}
