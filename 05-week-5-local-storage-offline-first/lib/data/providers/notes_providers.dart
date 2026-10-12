import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/note.dart';
import '../prefs.dart';
import '../repositories/note_repository.dart';

final prefsRepositoryProvider = Provider<PrefsRepository>(
  (ref) => PrefsRepository(),
);

final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

final lastOpenedProvider = FutureProvider<String?>((ref) {
  return ref.watch(prefsRepositoryProvider).getLastOpened();
});

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() {
    return ref.watch(prefsRepositoryProvider).getDarkMode();
  }

  Future<void> toggle() async {
    final next = !(state.value ?? false);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(),
);

final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

final dirtyCountProvider = FutureProvider<int>((ref) {
  return ref.watch(noteRepositoryProvider).countDirty();
});

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    await ref.read(prefsRepositoryProvider).markOpenedNow();
    ref.invalidate(lastOpenedProvider);
    return ref.read(noteRepositoryProvider).fetchNotes();
  }

  Future<void> addNote({required String title, String body = ''}) async {
    await ref.read(noteRepositoryProvider).addNote(title: title, body: body);
    await reload();
  }

  Future<void> deleteNote(int id) async {
    await ref.read(noteRepositoryProvider).deleteNote(id);
    await reload();
  }

  Future<void> reload() async {
    state = await AsyncValue.guard(
      () => ref.read(noteRepositoryProvider).fetchNotes(),
    );
    ref.invalidate(dirtyCountProvider);
  }
}
