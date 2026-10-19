# Week 07 — Clean Architecture Feature-First

<p align="left">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Riverpod-2E7D32?style=for-the-badge" alt="Riverpod">
  <img src="https://img.shields.io/badge/Clean%20Architecture-1565C0?style=for-the-badge" alt="Clean Architecture">
  <img src="https://img.shields.io/badge/Status-In%20Progress-orange?style=for-the-badge" alt="Status">
</p>

> Dokumentasi praktikum Pemrograman Mobile — refactor project Week 5

| Informasi         | Detail                |
| ----------------- | --------------------- |
| **Nama**          | Risky Adi Prasetya    |
| **NIM**           | 244107020153          |
| **Program Studi** | Teknik Informatika    |
| **Kelas**         | TI-3E                 |
| **Project**       | `week5_offline_notes` |

## Daftar Isi

- [Struktur Target Feature-First](#struktur-target-feature-first)
- [Praktikum 1 — Audit Layer](#praktikum-1--audit-layer)
- [Praktikum 2 — Domain dan Data](#praktikum-2--domain-dan-data)
- [Praktikum 3 — Presentation, DI, dan Verifikasi](#praktikum-3--presentation-di-dan-verifikasi)

---

## Kondisi Project Week 5

Project yang direfactor adalah aplikasi catatan offline-first dari
[README Week 5](README.md). Fitur yang sudah tersedia adalah CRUD catatan dengan SQLite, preferensi dark mode dan waktu terakhir dibuka dengan SharedPreferences, cache-first, penanda `dirty`, serta antrean sinkronisasi.

Struktur awal yang digunakan:

```text
lib/
├── main.dart
├── data/
│   ├── api_client.dart
│   ├── prefs.dart
│   ├── sync.dart
│   ├── local/
│   │   ├── db.dart
│   │   ├── note.dart
│   │   └── post.dart
│   ├── providers/
│   │   ├── notes_providers.dart
│   │   └── posts_providers.dart
│   └── repositories/
│       ├── note_repository.dart
│       └── post_cache_repository.dart
├── pages/
│   ├── cached_posts_page.dart
│   ├── note_detail_page.dart
│   ├── notes_page.dart
│   └── setting_page.dart
└── core/
    ├── failures.dart
    └── providers.dart
```

Struktur tersebut termasuk _layer-first_ karena kode dikelompokkan
berdasarkan jenis teknologinya. Entity catatan, mapping SQLite, repository,
provider, dan halaman masih berada di tempat yang sama-sama berorientasi
implementasi sehingga batas domain, data, dan presentation belum terlihat.

Sebelum refactor, buat snapshot:

```bash
git add 05-week-5-local-storage-offline-first
git commit -m "chore: snapshot before clean architecture"
```
---

## Praktikum 1 — Audit Layer

### 1. Pemetaan file lama

| File lama                                    | Layer saat ini                | Tujuan setelah refactor                                                                                                                            | Masalah yang diaudit                                                    |
| -------------------------------------------- | ----------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| `lib/data/local/note.dart`                   | Data/model + entity tercampur | Entity ke `features/notes/domain/entities/note.dart`; mapping ke `features/notes/data/models/note_model.dart`                                      | `Note` memiliki `toMap`/`fromMap` sehingga domain masih mengenal SQLite |
| `lib/data/repositories/note_repository.dart` | Data + kontrak tercampur      | Kontrak ke `features/notes/domain/repositories/note_repository.dart`; implementasi ke `features/notes/data/repositories/note_repository_impl.dart` | Interface dan akses SQLite masih berada pada tanggung jawab yang sama   |
| `lib/data/prefs.dart`                        | Data/infrastructure           | Tetap sebagai adapter data atau dipindahkan ke `features/settings/data`                                                                            | Widget tidak boleh memanggil `SharedPreferences` langsung               |
| `lib/data/sync.dart`                         | Data/infrastructure           | `features/notes/data/usecases/sync_notes.dart` dan adapter data terkait                                                                            | Logika antrean dan detail jaringan/storage perlu dipisahkan dari domain |
| `lib/pages/notes_page.dart`                  | Presentation                  | `features/notes/presentation/pages/notes_page.dart`                                                                                                | Halaman hanya membaca state dan mengirim aksi ke provider               |
| `lib/pages/setting_page.dart`                | Presentation                  | `features/settings/presentation/pages/setting_page.dart` atau tetap sebagai presentation sementara                                                 | UI tidak boleh memuat logika preferensi                                 |
| `lib/data/providers/notes_providers.dart`    | Presentation/state            | `features/notes/presentation/providers/notes_providers.dart`                                                                                       | Provider menjadi tempat DI, bukan tempat mapping SQLite                 |
| `lib/data/providers/posts_providers.dart`    | Presentation/state            | `features/posts/presentation/providers/posts_providers.dart`                                                                                       | Provider cache posts tidak boleh bercampur dengan UI                    |
| `lib/main.dart`                              | Composition root              | Tetap di root                                                                                                                                      | Hanya bootstrap aplikasi dan provider scope                             |

### 2. Tiga pencarian pelanggaran

Jalankan dari folder `05-week-5-local-storage-offline-first`:

```bash
# Widget yang menyentuh database atau storage langsung
rg "SharedPreferences\.getInstance|openDatabase|getDatabasesPath|sqflite|http\.|Dio\(" lib
```

<p align="center">
  <img src="screenshots\bef-audit1.png" width="60%" alt="ripgrep-audit 1">
<br>
<i>Hasil audit 1</i>
</p>

```bash
# Logika mapping atau serialisasi di widget
rg "fromMap|toMap|jsonDecode|toIso8601String|DateFormat" lib
```

<p align="center">
  <img src="screenshots\bef-audit2.png" width="60%" alt="ripgrep-audit 2">
<br>
<i>Hasil audit 2</i>
</p>

```bash
# Instansiasi manual yang membocorkan DI
rg "Repository\(|Database\(|SharedPreferences|Provider<" lib
```
<p align="center">
  <img src="screenshots\bef-audit3.png" width="60%" alt="ripgrep-audit 3">
<br>
<i>Hasil audit 3</i>
</p>

---

## Praktikum 2 — Domain dan Data per Fitur

### 1. Entity murni (domain)

Buat `lib/features/notes/domain/entities/note.dart`. Entity tidak mengimpor
Flutter dan tidak berisi mapping SQLite/JSON:

```dart
class Note {
  const Note({
    this.id,
    required this.title,
    this.body = '',
    required this.updatedAt,
    this.dirty = false,
  });

  final int? id;
  final String title;
  final String body;
  final DateTime updatedAt;
  final bool dirty;
}
```

### 2. Failure dan kontrak repository (domain)

Buat `lib/core/failures.dart` dan
`lib/features/notes/domain/repositories/note_repository.dart`:

```dart
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}
```

```dart
import '../../../../core/failures.dart';
import '../entities/note.dart';

abstract class NoteRepository {
  Future<({List<Note> notes, Failure? failure})> fetchNotes();

  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  });
}
```

Record Dart membuat hasil sukses/gagal eksplisit tanpa exception mentah bocor
ke presentation. Alternatif industri seperti `fpdart` atau `dartz`
menggunakan `Either<Failure, T>` dengan pola kontrak yang sama.

### 3. Model dan implementasi (data)

Buat `lib/features/notes/data/models/note_model.dart`. Mapping hanya boleh
berada di model:

```dart
import '../../domain/entities/note.dart';

class NoteModel extends Note {
  const NoteModel({
    super.id,
    required super.title,
    super.body = '',
    required super.updatedAt,
    super.dirty = false,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'updated_at': updatedAt.toIso8601String(),
        'dirty': dirty ? 1 : 0,
      };

  factory NoteModel.fromMap(Map<String, Object?> map) {
    return NoteModel(
      id: (map['id'] as num?)?.toInt(),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      updatedAt: DateTime.tryParse(
            map['updated_at'] as String? ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      dirty: ((map['dirty'] as num?)?.toInt() ?? 0) == 1,
    );
  }

  Note toEntity() => Note(
        id: id,
        title: title,
        body: body,
        updatedAt: updatedAt,
        dirty: dirty,
      );
}
```

Buat `lib/features/notes/data/repositories/note_repository_impl.dart`.
Implementasi ini menjadi satu-satunya tempat yang mengimpor `sqflite`:

```dart
import 'package:sqflite/sqflite.dart';
import '../../../../core/failures.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl({required Future<Database> Function() openDb})
      : _openDb = openDb;

  final Future<Database> Function() _openDb;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    try {
      final db = await _openDb();
      final rows = await db.query(
        'notes',
        orderBy: 'updated_at DESC',
      );
      final notes = rows
          .map((row) => NoteModel.fromMap(row).toEntity())
          .toList();
      return (notes: notes, failure: null);
    } catch (error) {
      return (
        notes: const <Note>[],
        failure: LocalFailure('Gagal membaca catatan: $error'),
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
    } catch (error) {
      return (
        note: null,
        failure: LocalFailure('Gagal menyimpan catatan: $error'),
      );
    }
  }
}
```

Repository mengubah `NoteModel` menjadi entity melalui `.toEntity()` sebelum
hasil data dikembalikan ke domain.

### 4. Use case: satu operasi bisnis

Buat `lib/features/notes/domain/usecases/get_notes.dart`:

```dart
import '../../../../core/failures.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class GetNotes {
  const GetNotes(this._repository);

  final NoteRepository _repository;

  Future<({List<Note> notes, Failure? failure})> call() {
    return _repository.fetchNotes();
  }
}
```

Use case diperlukan ketika operasi memiliki validasi, sorting, sinkronisasi,
atau menggabungkan beberapa repository. CRUD satu baris boleh langsung dari
repository ke notifier jika belum memiliki aturan bisnis.

---

## Praktikum 3 — Presentation, DI, dan Verifikasi

### 1. Dependency injection dengan Riverpod

Buat `lib/features/notes/presentation/providers/notes_providers.dart`.
Inilah satu-satunya tempat wiring:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/get_notes.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(openDb: openNotesDb);
});

final getNotesProvider = Provider<GetNotes>((ref) {
  return GetNotes(ref.watch(noteRepositoryProvider));
});

final notesProvider = FutureProvider<List<Note>>((ref) async {
  final result = await ref.watch(getNotesProvider).call();
  if (result.failure != null) {
    throw Exception(result.failure!.message);
  }
  return result.notes;
});
```

Database opener `openNotesDb` disuntikkan agar dapat diganti dengan fake saat
test. Domain menerima abstraksi `NoteRepository`, bukan implementasi SQLite.

### 2. Halaman hanya membaca state

`lib/features/notes/presentation/pages/notes_page.dart` versi bersih tidak
mengandung SQL, Dio, JSON, atau formatting tanggal mentah:

```dart
class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notesProvider);
    return state.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => ErrorView(
        message: '$error',
        onRetry: () => ref.invalidate(notesProvider),
      ),
      data: (notes) => notes.isEmpty
          ? const Center(child: Text('Belum ada catatan.'))
          : NotesList(notes),
    );
  }
}
```

Halaman hanya menampilkan state dan mengirim aksi UI ke provider. Akses
SQLite, `SharedPreferences`, serta mapping model tetap berada di data layer.

### 3. Verifikasi dependency rule

Jalankan tiga pemeriksaan ini dari folder project Week 5; dua grep pertama
harus menghasilkan nol temuan:

```bash
# 1. Presentation steril dari data mentah
rg "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode" lib/features/*/presentation lib/pages

# 2. Domain steril dari framework dan package
rg "import 'package:flutter|import 'package:dio|import 'package:sqflite|import 'package:firebase" lib/features/*/domain lib/core

# 3. Static analysis + test
flutter analyze
flutter test
```

Definisi selesai: aplikasi berjalan sama seperti sebelum refactor, hasil grep
bersih, `flutter analyze` bersih, test hijau, dan screenshot before/after
tersimpan di `screenshots/`.

---
