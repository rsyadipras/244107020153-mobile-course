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

## Praktikum 2 — Domain dan Data

### 1. Entity murni

Contoh entity pengumuman di
`lib/features/announcements/domain/entities/announcement.dart`:

```dart
class Announcement {
  const Announcement({
    this.id,
    required this.title,
    this.body = '',
    required this.publishedAt,
  });

  final int? id;
  final String title;
  final String body;
  final DateTime publishedAt;
}
```

Entity tidak mengimpor Flutter, Dio, Firebase, atau package storage.

### 2. Failure dan repository interface

`lib/core/failures.dart` berisi kegagalan yang dapat dipahami domain:

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

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}
```

Kontrak `lib/features/announcements/domain/repositories/announcement_repository.dart`:

```dart
import '../../../../core/failures.dart';
import '../entities/announcement.dart';

abstract class AnnouncementRepository {
  Future<({List<Announcement> items, Failure? failure})>
      fetchAnnouncements();
}
```

Kontrak berada di domain karena domain menentukan kebutuhan bisnis, bukan
detail cara mengambil data. Implementasi data bebas memakai Dio atau sumber
lain selama kontrak tetap terpenuhi.

### 3. Model dan repository implementation

Mapping JSON hanya berada di
`lib/features/announcements/data/models/announcement_model.dart`:

```dart
import '../../domain/entities/announcement.dart';

class AnnouncementModel extends Announcement {
  const AnnouncementModel({
    super.id,
    required super.title,
    super.body = '',
    required super.publishedAt,
  });

  factory AnnouncementModel.fromJson(Map<String, Object?> json) {
    return AnnouncementModel(
      id: (json['id'] as num?)?.toInt(),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      publishedAt: DateTime.tryParse(
            json['published_at'] as String? ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Announcement toEntity() => Announcement(
        id: id,
        title: title,
        body: body,
        publishedAt: publishedAt,
      );
}
```

`announcement_repository_impl.dart` menangkap exception teknis, melakukan
mapping model ke entity, lalu mengembalikan `Failure`:

```dart
class AnnouncementRepositoryImpl implements AnnouncementRepository {
  const AnnouncementRepositoryImpl({required this.fetchJson});

  final Future<List<Map<String, Object?>>> Function() fetchJson;

  @override
  Future<({List<Announcement> items, Failure? failure})>
      fetchAnnouncements() async {
    try {
      final rows = await fetchJson();
      final items = rows
          .map((row) => AnnouncementModel.fromJson(row).toEntity())
          .toList();
      return (items: items, failure: null);
    } catch (error) {
      return (
        items: const <Announcement>[],
        failure: NetworkFailure('Gagal memuat pengumuman: $error'),
      );
    }
  }
}
```

Pada implementasi nyata, `fetchJson` dapat dibungkus oleh `ApiClient`.
Exception Dio, Firebase, dan secure storage tidak boleh bocor ke presentation.

### 4. Use case

`lib/features/announcements/domain/usecases/get_announcements.dart`:

```dart
import '../../../../core/failures.dart';
import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

class GetAnnouncements {
  const GetAnnouncements(this._repository);

  final AnnouncementRepository _repository;

  Future<({List<Announcement> items, Failure? failure})> call() {
    return _repository.fetchAnnouncements();
  }
}
```

Use case wajib ketika operasi memiliki validasi, sorting, gabungan beberapa
repository, refresh token, atau sinkronisasi. CRUD satu baris boleh langsung
dari repository ke notifier jika belum memiliki aturan bisnis; keputusan ini
harus didokumentasikan agar tidak menjadi over-engineering.

---

## Praktikum 3 — Presentation, DI, dan Verifikasi

### 1. Dependency injection dengan Riverpod

Semua wiring berada di
`lib/features/announcements/presentation/providers/announcement_providers.dart`:

```dart
final announcementRepositoryProvider =
    Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepositoryImpl(
    fetchJson: () => ref.watch(apiClientProvider).getAnnouncements(),
  );
});

final getAnnouncementsProvider = Provider<GetAnnouncements>((ref) {
  return GetAnnouncements(ref.watch(announcementRepositoryProvider));
});

final announcementsProvider =
    FutureProvider<List<Announcement>>((ref) async {
  final result = await ref.watch(getAnnouncementsProvider).call();
  if (result.failure != null) {
    throw Exception(result.failure!.message);
  }
  return result.items;
});
```

Provider `apiClientProvider` dapat ditempatkan di `core/providers.dart`.
Saat test, provider tersebut dapat dioverride dengan fake. Widget tidak
pernah menulis `AnnouncementRepositoryImpl()` atau `Dio()`.

### 2. Halaman hanya membaca state

Halaman pengumuman cukup membaca `announcementsProvider`:

```dart
class AnnouncementPage extends ConsumerWidget {
  const AnnouncementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(announcementsProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(
        message: '$error',
        onRetry: () => ref.invalidate(announcementsProvider),
      ),
      data: (items) => items.isEmpty
          ? const Center(child: Text('Belum ada pengumuman.'))
          : AnnouncementList(items),
    );
  }
}
```

Halaman tidak mengandung SQL, Dio, JSON, secure storage, atau formatting
tanggal mentah.

### 3. Formatting dan parsing rute

Ekstrak fungsi murni ke `lib/core/format.dart` dan `lib/routes.dart`:

```dart
String formatDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}

String? routeFromMessage(Map<String, dynamic> data) {
  final route = data['route'];
  return route is String && route.startsWith('/pengumuman/')
      ? route
      : null;
}
```

Fungsi tersebut dapat diuji tanpa `BuildContext` atau device.

### 4. Verifikasi dependency rule

Semua perintah berikut harus menghasilkan nol hasil pada dua grep pertama:

```bash
# Presentation steril dari data mentah
rg "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode" lib/features/*/presentation lib/pages

# Domain steril dari framework dan package
rg "import 'package:flutter|import 'package:dio|import 'package:sqflite|import 'package:firebase" lib/features/*/domain lib/core

# Static analysis dan seluruh test
flutter analyze
flutter test
```

Definisi selesai: aplikasi berjalan sama seperti sebelum refactor, hasil grep
bersih, `flutter analyze` bersih, test hijau, dan screenshot before/after
tersimpan di `screenshots/`.

---
