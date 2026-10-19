import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/local/db.dart';
import '../../data/repositories/note_repositories_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/get_notes.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(openDb: openNotesDb);
});

final getNotesProvider = Provider<GetNotes>((ref) {
  return GetNotes(ref.watch(noteRepositoryProvider));
});

final addNoteProvider = Provider<AddNote>((ref) {
  return AddNote(ref.watch(noteRepositoryProvider));
});

final notesProvider = FutureProvider<List<Note>>((ref) async {
  final result = await ref.watch(getNotesProvider).call();
  if (result.failure != null) {
    throw Exception(result.failure!.message);
  }
  return result.notes;
});

final dirtyCountProvider = FutureProvider<int>((ref) async {
  final result = await ref.watch(noteRepositoryProvider).countDirty();
  if (result.failure != null) {
    throw Exception(result.failure!.message);
  }
  return result.count;
});

final notesActionsProvider = Provider<NotesActions>((ref) {
  return NotesActions(ref);
});

class NotesActions {
  const NotesActions(this._ref);

  final Ref _ref;

  Future<void> addNote({
    required String title,
    String body = '',
  }) async {
    final result = await _ref.read(addNoteProvider).call(
          title: title,
          body: body,
        );
    if (result.failure != null) {
      throw Exception(result.failure!.message);
    }
    _invalidateNotes();
  }

  Future<void> deleteNote(int id) async {
    final failure = await _ref.read(noteRepositoryProvider).deleteNote(id);
    if (failure != null) {
      throw Exception(failure.message);
    }
    _invalidateNotes();
  }

  Future<int> syncNotes() async {
    final dirtyResult = await _ref.read(noteRepositoryProvider).countDirty();
    if (dirtyResult.failure != null) {
      throw Exception(dirtyResult.failure!.message);
    }
    if (dirtyResult.count == 0) {
      return 0;
    }

    await Future<void>.delayed(const Duration(seconds: 1));
    final failure = await _ref.read(noteRepositoryProvider).markAllSynced();
    if (failure != null) {
      throw Exception(failure.message);
    }
    _invalidateNotes();
    return dirtyResult.count;
  }

  void _invalidateNotes() {
    _ref
      ..invalidate(notesProvider)
      ..invalidate(dirtyCountProvider);
  }
}