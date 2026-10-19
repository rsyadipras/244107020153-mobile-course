import 'package:sqflite/sqflite.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl({required this._openDb});

  final Future<Database> Function() _openDb;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    try {
      final db = await _openDb();
      final rows = await db.query('notes', orderBy: 'updated_at DESC');
      final notes = rows.map((r) => NoteModel.fromMap(r).toEntity()).toList();
      return (notes: notes, failure: null);
    } catch (e) {
      return (
        notes: const <Note>[],
        failure: LocalFailure('Gagal membaca catatan: $e'),
      );
    }
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    try {
      final db = await _openDb();
      final now = DateTime.now();
      final id = await db.insert(
        'notes',
        NoteModel(
          title: title,
          body: body,
          updatedAt: now,
          dirty: true,
        ).toMap(),
      );
      return (
        note: Note(
          id: id,
          title: title,
          body: body,
          updatedAt: now,
          dirty: true,
        ),
        failure: null,
      );
    } catch (e) {
      return (note: null, failure: LocalFailure('Gagal menyimpan catatan: $e'));
    }
  }

  @override
  Future<Failure?> deleteNote(int id) async {
    try {
      final db = await _openDb();
      await db.delete('notes', where: 'id = ?', whereArgs: [id]);
      return null;
    } catch (error) {
      return LocalFailure('Gagal menghapus catatan: $error');
    }
  }

  @override
  Future<({int count, Failure? failure})> countDirty() async {
    try {
      final db = await _openDb();
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM notes WHERE dirty = 1',
      );
      return (
        count: (rows.first['c'] as num?)?.toInt() ?? 0,
        failure: null,
      );
    } catch (error) {
      return (
        count: 0,
        failure: LocalFailure('Gagal membaca status sinkronisasi: $error'),
      );
    }
  }

  @override
  Future<Failure?> markAllSynced() async {
    try {
      final db = await _openDb();
      await db.update('notes', {'dirty': 0}, where: 'dirty = 1');
      return null;
    } catch (error) {
      return LocalFailure('Gagal menyinkronkan catatan: $error');
    }
  }
}
