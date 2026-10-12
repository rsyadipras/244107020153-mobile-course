# Week 05 — Local Storage & Offline-First

<p align="left">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Riverpod-2E7D32?style=for-the-badge" alt="Riverpod">
  <img src="https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white" alt="SQLite">
  <img src="https://img.shields.io/badge/Status-In%20Progress-orange?style=for-the-badge" alt="Status">
</p>

> Dokumentasi praktikum Pemrograman Mobile — Minggu 5

| Informasi | Detail |
| --- | --- |
| **Nama** | Risky Adi Prasetya |
| **NIM** | 244107020153 |
| **Program Studi** | Teknik Informatika |
| **Kelas** | TI-3E |

## Daftar Isi

- [Tujuan Pembelajaran](#tujuan-pembelajaran)
- [Tech Stack](#tech-stack)
- [Konsep Local Storage dan Offline-First](#konsep-local-storage-dan-offline-first)
- [Praktikum 1 — SharedPreferences](#praktikum-1--sharedpreferences)
- [Praktikum 2 — SQLite dan Repository Catatan](#praktikum-2--sqlite-dan-repository-catatan)
- [Praktikum 3 — Cache-First dan Antrean Sync](#praktikum-3--cache-first-dan-antrean-sync)
- [AI Challenge](#ai-challenge)
- [Refactoring dan Testing](#refactoring-dan-testing)
- [Tugas dan Refleksi](#tugas-dan-refleksi)

---

## Tujuan Pembelajaran

- menjelaskan perbedaan penyimpanan key-value, relasional, dan NoSQL di perangkat;
- menyimpan preferensi sederhana (tema dan terakhir dibuka) dengan SharedPreferences;
- menerapkan CRUD catatan dengan SQLite (sqflite) melalui repository lokal;
- menerapkan pola offline-first: cache-first read, dirty flag, dan antrean sinkronisasi;
- menampilkan state loading, error, empty, dan success untuk data lokal dengan Riverpod;
- menguji repository lokal dengan repository palsu tanpa database sungguhan.

## Tech Stack

| Komponen | Detail |
| --- | --- |
| Framework | Flutter & Dart |
| State management | flutter_riverpod |
| Key-value storage | shared_preferences |
| Database lokal | sqflite |
| Path database | path |
| API cache | JSONPlaceholder dari materi Minggu 4 |
| IDE | VS Code |
| Device | Smartphone atau emulator Android |
| Version Control | GitHub |

---
## Konsep Local Storage dan Offline-First

### Jenis Penyimpanan di Perangkat

| Jenis | Contoh | Cocok untuk |
| --- | --- | --- |
| Key-value | SharedPreferences | Preferensi sederhana seperti tema dan waktu terakhir dibuka |
| Relasional | SQLite melalui sqflite | Data terstruktur, CRUD, query, dan relasi |
| NoSQL | Hive atau database dokumen lain | Data berbasis objek dengan kebutuhan query berbeda |

### Offline-First

Offline-first berarti aplikasi tetap memberikan pengalaman yang berguna ketika jaringan tidak tersedia. Data lokal menjadi sumber baca utama atau cache, sedangkan sinkronisasi jaringan dilakukan kemudian.

Pola yang digunakan:

1. Baca cache lokal terlebih dahulu.
2. Tampilkan data cache seketika agar UI tidak blank.
3. Refresh data dari jaringan di background.
4. Simpan hasil jaringan ke storage lokal.
5. Tandai data lokal yang belum tersinkron dengan `dirty`.
6. Sinkronkan antrean ketika koneksi tersedia.

### State Lokal

Walaupun data berasal dari storage lokal, UI tetap perlu menangani:

- **loading** — database atau preferensi sedang dibuka;
- **error** — pembacaan atau penulisan gagal;
- **empty** — belum ada catatan;
- **success** — data berhasil dimuat.

---

## Praktikum 1 — SharedPreferences

### Membuat Project

```bash
flutter create week5_offline_notes
cd week5_offline_notes
flutter pub add flutter_riverpod shared_preferences sqflite path
```

### 1. Repository Preferensi

File: `lib/data/prefs.dart`

Seluruh akses key-value dipusatkan di repository, bukan tersebar di widget:

```dart
import 'package:shared_preferences/shared_preferences.dart';

class PrefsRepository {
  static const _darkModeKey = 'dark_mode';
  static const _lastOpenedKey = 'last_opened_at';

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  Future<void> markOpenedNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastOpenedKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<String?> getLastOpened() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastOpenedKey);
  }
}
```

### 2. Provider dan Halaman Pengaturan

File: `lib/pages/settings_page.dart`

Gunakan provider dan `AsyncNotifier` untuk menghubungkan repository preferensi dengan UI:

```dart
final prefsRepositoryProvider = Provider<PrefsRepository>(
  (ref) => PrefsRepository(),
);

final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(
  DarkModeNotifier.new,
);

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
```

**Hasil Implementasi:**
<p align="center">
  <video src="screenshots/Practicum1.mp4" alt="SharedPreferences result" width="50%" muted autoplay loop></video>
  <br>
  <i>Tampilan halaman pengaturan dengan toggle tema gelap/terang dan waktu terakhir dibuka.</i>
</p>

---

## Praktikum 2 — SQLite dan Repository Catatan

### 1. Model Catatan

File: `lib/data/local/note.dart`

Field `dirty` menandai catatan yang belum tersinkron:

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

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'updated_at': updatedAt.toIso8601String(),
        'dirty': dirty ? 1 : 0,
      };

  factory Note.fromMap(Map<String, Object?> map) {
    return Note(
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
}
```

### 2. Pembuka Database

File: `lib/data/local/db.dart`

Satu fungsi pembuka database digunakan oleh repository:

```dart
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

Future<Database> openNotesDb() async {
  final dir = await getDatabasesPath();

  return openDatabase(
    p.join(dir, 'offline_notes.db'),
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE notes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL DEFAULT '',
          updated_at TEXT NOT NULL,
          dirty INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE cached_posts(
          id INTEGER PRIMARY KEY,
          payload TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');
    },
  );
}
```

### 3. Repository sebagai Satu-satunya Pintu Data

File: `lib/data/repositories/note_repository.dart`

Repository bertanggung jawab atas operasi CRUD dan status sinkronisasi:

```dart
import 'package:sqflite/sqflite.dart';
import '../local/db.dart';
import '../local/note.dart';

class NoteRepository {
  NoteRepository({Future<Database> Function()? openDb})
      : _openDb = openDb ?? openNotesDb;

  final Future<Database> Function() _openDb;

  Future<List<Note>> fetchNotes() async {
    final db = await _openDb();
    final rows = await db.query(
      'notes',
      orderBy: 'updated_at DESC',
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<Note> addNote({
    required String title,
    String body = '',
  }) async {
    final db = await _openDb();
    final note = Note(
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    final id = await db.insert('notes', note.toMap());

    return Note(
      id: id,
      title: note.title,
      body: note.body,
      updatedAt: note.updatedAt,
      dirty: true,
    );
  }

  Future<void> deleteNote(int id) async {
    final db = await _openDb();
    await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> countDirty() async {
    final db = await _openDb();
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM notes WHERE dirty = 1',
    );
    return ((rows.first['c'] as num?)?.toInt() ?? 0);
  }

  Future<void> markAllSynced() async {
    final db = await _openDb();
    await db.update(
      'notes',
      {'dirty': 0},
      where: 'dirty = 1',
    );
  }
}
```

### 4. Halaman Catatan Offline

File: `lib/pages/notes_page.dart`

Halaman catatan harus tetap berfungsi dalam mode pesawat. Tampilkan:

- daftar catatan lokal;
- state loading, error, empty, dan success;
- aksi tambah dan hapus catatan;
- badge jumlah catatan yang belum tersinkron (`dirty`);
- tombol atau aksi untuk menjalankan sinkronisasi.

**Hasil implementasi halaman:**
<p align="center">
  <video src="screenshots/practicum1.1.mp4" alt="Result" width="50%" muted autoplay loop></video>
  <br>
  <i>Hasil implementasi halaman catatan offline.</i>
</p>

---

## Praktikum 3 — Cache-First dan Antrean Sync

### 1. Cache-First Read untuk Data API

Gunakan kembali endpoint Minggu 4, yaitu `GET /posts` dari JSONPlaceholder.

Contoh bentuk fungsi:

```dart
Future<List<Post>> loadPostsCacheFirst() async {
  final cached = await readCachedPosts();
  refreshPostsInBackground();
  return cached;
}
```
### 2. Sinkronisasi Catatan Dirty

Karena codelab ini belum memiliki backend tulis, gunakan simulasi delay:

```dart
Future<int> syncNotes(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;

  await Future.delayed(const Duration(seconds: 1));
  await repo.markAllSynced();
  return dirtyCount;
}
```

### 3. Simulasi Offline yang Deterministik

Sediakan toggle `forceOffline` pada provider agar demo dan testing tidak bergantung pada kondisi Wi-Fi:

- matikan Wi-Fi atau aktifkan mode pesawat, lalu buka aplikasi;
- pastikan catatan tetap tampil;
- pastikan badge dirty tetap akurat;
- aktifkan kembali koneksi;
- jalankan `syncNotes`;
- pastikan badge kembali menjadi 0.


<p align="center">
  <video src="screenshots/Practicum1.2.mp4" alt="Simulasi Offline" width="50%" muted autoplay loop></video>
  <br>
  <i>Simulasi offline dalam aplikasi catatan offline.</i>
</p>

---

## AI Challenge

### AI Prompt Challenge

Gunakan prompt berikut:

```text
Aplikasi Flutter Offline Notes: CRUD catatan + preferensi tema.
Bandingkan SharedPreferences, Hive, sqflite (SQLite), dan Drift
untuk dua kebutuhan ini. Requirements:
- Kriteria: kompleksitas query, kebutuhan relasi, reaktivitas (stream),
  type-safety, ukuran boilerplate, dan kemudahan testing.
- Beri rekomendasi final: mana untuk preferensi, mana untuk catatan,
  beserta alasannya dalam 1 tabel.
- Tunjukkan skema tabel/kotak untuk 1000+ catatan.
Jelaskan trade-off setiap pilihan.
```

### AI Verification Checklist
1. **Apakah AI menempatkan daftar catatan di SharedPreferences? (menolak: rapuh untuk koleksi).**
   - Tidak. `SSharedPreferences` hanya digunakan untuk preferensi kecil seperti dark_mode dan last_opened_at. Catatan disimpan di `SQLite` karena lebih sesuai untuk data CRUD dan jumlah besar.
2. **Apakah skema AI mendukung antrean sync (dirty flag / updated_at) atau hanya CRUD polos?**
   - Ya. Tabel notes memiliki `dirty` dan `updated_at`. Catatan baru diberi `dirty = 1`, kemudian diubah menjadi 0 setelah berhasil disinkronkan.
3. **Apakah klaim "real-time" AI didukung stream (Drift/watch) atau hanya asumsi?**
   - Belum real-time. Implementasi saat ini menggunakan reload/invalidate Riverpod setelah perubahan, bukan stream database. Stream seperti Drift `watch()` belum digunakan.
4. **Apakah estimasi boilerplate AI masuk akal setelah Anda mencoba instalasinya (flutter pub add + migrasi skema)?**
   - Cukup masuk akal. `sqflite` lebih sederhana dan sudah digunakan di proyek. Drift membutuhkan konfigurasi tambahan seperti generator dan migration strategy, sehingga boilerplate-nya lebih besar.
5. **Keputusan final Anda beserta alasannya, boleh berbeda dari rekomendasi AI selama berargumen.**
   - Kami memilih SharedPreferences untuk preferensi dan sqflite/SQLite untuk catatan. Keduanya sudah terpasang, SQLite mendukung CRUD serta sinkronisasi melalui `dirty` dan `updated_at`, dan kebutuhannya sesuai dengan scope aplikasi saat ini.

### Dokumentasi AI

Artefak AI dalam folder `docs/`:

| Dokumen | Lokasi | Status |
| --- | --- | --- |
| Prompt yang digunakan | [`docs/ai-prompt.md`](docs/ai-prompt.md) |
| Output awal AI | [`docs/ai-output-awal.md`](docs/ai-output-awal.md) |
| Tabel perbandingan storage | [`docs/storage-comparison.md`](docs/storage-comparison.md) |
| Keputusan final dan alasan teknis | [`docs/decision.md`](docs/decision.md) |

---

## Refactoring dan Testing
### Refactoring Challenge

1. Ekstrak baris catatan menjadi widget `NoteTile` yang menampilkan badge **belum tersinkron** ketika `dirty == true`.
2. Pindahkan logika cache posts dan `syncNotes` ke `lib/data/sync.dart` agar repository tetap fokus pada CRUD.
3. Tambahkan halaman detail catatan dengan GoRouter pada route `/note/:id`.
4. Halaman detail membaca data dari repository lokal, bukan hanya dari state halaman list.

### Testing: Unit Test Model dan Repository Palsu

Buat `test/note_test.dart` dengan minimal empat skenario:

1. `fromMap` aman terhadap field yang hilang.
2. Flag `dirty` bertahan setelah serialisasi dan deserialisasi.
3. Provider berhasil menggunakan repository palsu.
4. Provider menghasilkan error menggunakan repository palsu.

Gunakan repository palsu agar test tidak menggunakan database SQLite sungguhan:

```dart
class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository({
    this.items = const [],
    this.throwError = false,
  }) : super(openDb: () => throw UnimplementedError());

  final List<Note> items;
  final bool throwError;

  @override
  Future<List<Note>> fetchNotes() async {
    if (throwError) {
      throw Exception('db locked (simulasi)');
    }
    return items;
  }

  @override
  Future<int> countDirty() {
    return Future.value(
      items.where((note) => note.dirty).length,
    );
  }
}
```

Contoh test mapping:

```dart
test('fromMap aman terhadap field yang hilang', () {
  final note = Note.fromMap({'title': 'Belanja'});

  expect(note.title, 'Belanja');
  expect(note.body, '');
  expect(note.dirty, isFalse);
});

test('flag dirty bertahan pada serialisasi', () {
  final note = Note(
    title: 'a',
    updatedAt: DateTime(2026, 9, 18),
    dirty: true,
  );
  final restored = Note.fromMap(note.toMap());

  expect(restored.dirty, isTrue);
});
```

Jalankan verifikasi:

```bash
flutter analyze
flutter test
```

### Hasil Testing

| Perintah | Hasil | Catatan |
| --- | --- | --- |
| `flutter analyze` | ☐ Lulus / ☐ Gagal | Isi hasil aktual |
| `flutter test` | ☐ Lulus / ☐ Gagal | Isi hasil aktual |

## Tugas dan Refleksi

### Mini Project / Industry Challenge

Bangun **aplikasi Offline Notes** sebagai tugas minggu ini:

1. Tambahkan toggle tema gelap/terang dan waktu terakhir dibuka menggunakan SharedPreferences.
2. Terapkan CRUD catatan persisten menggunakan SQLite melalui repository lokal dan Riverpod.
3. Urutkan daftar berdasarkan `updated_at` terbaru.
4. Terapkan offline-first untuk data bacaan dengan cache-first.
5. Terapkan `dirty flag`, `syncNotes`, dan aturan konflik yang terdokumentasi.
6. Buktikan mode pesawat melalui screenshot sebelum dan sesudah sync.
7. Sertakan minimal dua test yang lulus: satu unit test model dan satu test provider dengan repository palsu.
8. Kerjakan AI Challenge dan dokumentasikan prompt, tabel perbandingan storage, keputusan final, serta alasan teknis di `docs/`.
9. Push ke repository portfolio pada folder `05-week-5-local-storage-offline-first/` dengan struktur `lib/`, `test/`, `docs/`, `README.md`, dan `screenshots/`.

README tugas menjelaskan:

- tujuan;
- fitur utama;
- stack teknologi;
- cara menjalankan;
- hasil yang dicapai.

### Refleksi

Tuliskan jawaban Anda sendiri:

1. Mengapa daftar catatan tidak boleh disimpan di SharedPreferences? Apa yang rusak jika aturan ini dilanggar?

   **Jawaban:**

2. Kapan cache-first cukup, dan kapan Anda membutuhkan strategi lain, misalnya network-first untuk data harga real-time?

   **Jawaban:**

3. Bagaimana dirty flag berubah menjadi antrean sync tanpa memblokir UI? Kapan antrean terpisah seperti tabel outbox menjadi perlu?

   **Jawaban:**

4. Bagian mana dari rekomendasi AI yang Anda tolak, dan mengapa?

   **Jawaban:**

---
