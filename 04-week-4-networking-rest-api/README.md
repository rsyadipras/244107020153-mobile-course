# Week 04 — Networking & REST API

<p align="left">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Dio-546E7A?style=for-the-badge" alt="Dio">
  <img src="https://img.shields.io/badge/Riverpod-2E7D32?style=for-the-badge" alt="Riverpod">
  <img src="https://img.shields.io/badge/Status-On Progress-brightgreen?style=for-the-badge" alt="Status">
</p>

> Dokumentasi praktikum Pemrograman Mobile — Minggu 4

| Informasi | Detail |
| --- | --- |
| **Nama** | Risky Adi Prasetya |
| **NIM** | 244107020153 |
| **Program Studi** | Teknik Informatika |
| **Kelas** | TI-3E |

## Daftar Isi

- [Tujuan Pembelajaran](#tujuan-pembelajaran)
- [Tech Stack](#tech-stack)
- [Struktur Folder](#struktur-folder)
- [Konsep HTTP, REST API, dan JSON](#konsep-http-rest-api-dan-json)
- [Praktikum 1 — Dio dan Model Data](#praktikum-1--dio-dan-model-data)
- [Praktikum 2 — Provider dan Error Handling](#praktikum-2--provider-dan-error-handling)
- [Praktikum 3 — Pagination Dasar](#praktikum-3--pagination-dasar)
- [AI Challenge](#ai-challenge)
- [Refactoring dan Testing](#refactoring-dan-testing)
- [Tugas dan Refleksi](#tugas-refleksi)

---

## Tujuan Pembelajaran

- menjelaskan konsep HTTP, REST API, dan JSON;
- memetakan JSON ke model Dart (*serialization*) dengan aman null;
- menerapkan *repository pattern* dasar sehingga UI tidak memanggil API secara langsung;
- mengonfigurasi Dio (base URL, timeout, interceptor) dan menangani error jaringan;
- menampilkan state loading, error, empty, dan success pada UI dengan `AsyncValue` + Riverpod;
- menerapkan pagination dasar (*infinite scroll*).

## Tech Stack

| Komponen | Detail |
| --- | --- |
| Framework | Flutter & Dart |
| HTTP client | Dio |
| State management | flutter_riverpod |
| API latihan | [JSONPlaceholder](https://jsonplaceholder.typicode.com/) |
| IDE | VS Code |
| Device | Smartphone atau emulator Android |
| Version Control | GitHub |

---
## Konsep HTTP, REST API, dan JSON

### HTTP

HTTP adalah protokol komunikasi antara client dan server. Pada aplikasi Flutter, client mengirim request ke server, kemudian menerima response yang berisi status, header, dan data.

Method yang umum digunakan:

| Method | Kegunaan |
| --- | --- |
| `GET` | Membaca data |
| `POST` | Membuat data |
| `PUT`/`PATCH` | Memperbarui data |
| `DELETE` | Menghapus data |

### REST API

REST API menyediakan resource melalui endpoint dan menggunakan method HTTP untuk menentukan operasi. Pada praktikum ini, endpoint yang digunakan adalah:

```text
GET https://jsonplaceholder.typicode.com/posts
GET https://jsonplaceholder.typicode.com/posts?_page=1&_limit=10
GET https://jsonplaceholder.typicode.com/comments?postId={id}
```
---

## Praktikum 1 — Dio dan Model Data

### Membuat Project

```bash
flutter create week4_api
cd week4_api
flutter pub add dio flutter_riverpod
```
### 1. Model Data dengan `fromJson` Aman Null


File: `lib/data/models/post.dart`

```dart
class Post {
  const Post({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
  });

  final int userId;
  final int id;
  final String title;
  final String body;

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'id': id,
        'title': title,
        'body': body,
      };
}
```
Cast defensif seperti `as String? ?? ''` membantu mencegah crash ketika field API hilang atau bernilai `null`.

### 2. Konfigurasi Dio Terpusat

File: `lib/data/api_client.dart`

```dart
import 'package:dio/dio.dart';

Dio createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    LogInterceptor(requestBody: true, responseBody: false),
  );

  return dio;
}
```
Konfigurasi jaringan ditempatkan di satu client agar base URL, timeout, header, dan logging tidak tersebar di setiap request.

### 3. Repository sebagai Pintu Data

File: `lib/data/repositories/post_repository.dart`

```dart
import 'package:dio/dio.dart';
import '../models/post.dart';

class PostRepository {
  PostRepository(this._dio);

  final Dio _dio;

  Future<List<Post>> fetchPosts() async {
    final response = await _dio.get<List>('/posts');
    final data = response.data ?? [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(Post.fromJson)
        .toList();
  }

  Future<List<Post>> fetchPostsPage({
    required int page,
    int limit = 10,
  }) async {
    final response = await _dio.get<List>(
      '/posts',
      queryParameters: {'_page': page, '_limit': limit},
    );
    final data = response.data ?? [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(Post.fromJson)
        .toList();
  }
}
```
---
## Praktikum 2 — Provider dan Error Handling

### 4. `AsyncNotifier` dan Pesan Error Ramah Pengguna

File: `lib/data/providers.dart`

- `dioProvider` menyediakan instance Dio;
- `postRepositoryProvider` menyediakan repository;
- `PostListNotifier` mengambil daftar post;
- `refresh()` memperbarui state dan mempertahankan error secara eksplisit;
- `friendlyErrorMessage()` mengubah error jaringan menjadi pesan yang dapat dipahami pengguna;
- provider dapat dioverride dengan repository palsu saat testing.

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'api_client.dart';
import 'models/post.dart';
import 'repositories/post_repository.dart';

final dioProvider = Provider<Dio>((ref) => createDio());

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(ref.watch(dioProvider)),
);

class PostListNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    // Exception dari repository otomatis menjadi AsyncError.
    // Inilah ekuivalen deklaratif dari AsyncValue.guard di versi lama.
    final repository = ref.watch(postRepositoryProvider);
    return repository.fetchPosts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(postRepositoryProvider);
      state = AsyncData(await repository.fetchPosts());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final postListProvider =
    AsyncNotifierProvider<PostListNotifier, List<Post>>(
        PostListNotifier.new,
        // Nonaktifkan retry otomatis Riverpod 3 agar error langsung
        // final dan mudah diuji (tanpa ini, future provider di-test
        // akan me-retry dan menggantung).
        retry: (retryCount, error) => null);

/// Helper khusus testing (letakkan di providers.dart): membaca state
/// pertama yang bukan loading lewat listener + completer, sehingga
/// test tidak menunggu retry dan tidak melakukan HTTP sungguhan.
Future<List<Post>> readPostsOnce(ProviderContainer container) {
  final completer = Completer<List<Post>>();
  final sub = container.listen<AsyncValue<List<Post>>>(
    postListProvider,
    (previous, next) {
      if (next.isLoading || completer.isCompleted) return;
      next.whenData(completer.complete);
      if (next.hasError) {
        completer.completeError(
          next.error ?? StateError('unknown error'),
          next.stackTrace ?? StackTrace.empty,
        );
      }
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}

Future<Object?> readPostsErrorOnce(ProviderContainer container) {
  final completer = Completer<Object?>();
  final sub = container.listen<AsyncValue<List<Post>>>(
    postListProvider,
    (previous, next) {
      if (next.isLoading || completer.isCompleted) return;
      completer.complete(next.error);
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}

String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi lambat atau timeout. Periksa internet Anda lalu coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa internet Anda.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 404) return 'Data tidak ditemukan (404).';
        if (code == 401 || code == 403) {
          return 'Akses ditolak ($code). Periksa kredensial Anda.';
        }
        return 'Server bermasalah ($code). Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan jaringan. Coba lagi.';
    }
  }
  return 'Terjadi kesalahan tak terduga: $error';
}
```

### 5. UI: Loading, Error, Empty, Success

File: `lib/pages/post_list_page.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers.dart';

class PostListPage extends ConsumerWidget {
  const PostListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts API'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(postListProvider.notifier).refresh(),
          ),
        ],
      ),
      body: postsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(friendlyErrorMessage(err),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(postListProvider),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(
                child: Text('Belum ada data dari server.'));
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(postListProvider.notifier).refresh(),
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return ListTile(
                  leading: CircleAvatar(
                      child: Text(post.id.toString())),
                  title: Text(post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  subtitle: Text(post.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
```

### 6. Entry Point dengan `ProviderScope`

File: `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/post_list_page.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Week 4 - REST API',
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        home: const PostListPage(),
      );
}
```

### Uji Tiga Skenario Error

1. Jalankan aplikasi dengan internet normal, amati loading lalu daftar 100 post.
2. Matikan internet, tekan refresh, lalu amati pesan ramah dan tombol **Coba lagi**.
3. Ubah sementara `baseUrl` menjadi URL yang salah dan amati pesan error koneksi.
4. Kembalikan `baseUrl` setelah pengujian selesai.

---

## Praktikum 3 — Pagination Dasar

### Konsep Pagination

API dengan data besar tidak selalu mengirim semua data sekaligus. Data dikirim per halaman menggunakan parameter `_page` dan `_limit`.

Strategi *infinite scroll*:

1. Muat halaman pertama.
2. Pantau posisi scroll.
3. Muat halaman berikutnya ketika pengguna mendekati ujung list.
4. Pertahankan data lama saat request berikutnya berlangsung.
5. Tampilkan indikator kecil di bagian bawah list.

### 7. State Pagination

File: `lib/data/paged_posts.dart`

```dart
class PagedPostsState {
  const PagedPostsState({
    this.items = const [],
    this.page = 0,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<Post> items;
  final int page;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
}
```

### 8. Notifier Pagination

Implementasikan `PagedPostsNotifier` dengan method:

- `loadFirstPage()` untuk memuat halaman pertama;
- `loadNextPage()` untuk memuat halaman berikutnya;
- guard ganda agar request tidak dipanggil berulang;
- data lama tetap dipertahankan saat request halaman berikutnya gagal.

Guard penting:

```dart
if (state.isLoadingMore || !state.hasMore) return;
```

Guard tersebut mencegah request ganda ketika listener scroll terpanggil berkali-kali dan menghentikan request ketika data sudah habis.

### 9. UI Infinite Scroll

File: `lib/pages/paged_post_page.dart`

Gunakan `ScrollController` untuk memanggil `loadNextPage()` sekitar 200 pixel sebelum ujung list:

```dart
if (_controller.position.pixels >=
    _controller.position.maxScrollExtent - 200) {
  ref.read(pagedPostsProvider.notifier).loadNextPage();
}
```

Pastikan:

- `ScrollController` dilepas pada `dispose`;
- data lama tidak dihapus ketika memuat halaman baru;
- indikator loading tampil di bawah list;
- pesan `Semua data termuat.` tampil saat `hasMore == false`;
- error halaman pertama dan error halaman berikutnya memiliki tampilan yang sesuai.

**Catatan hasil pagination:**

> Isi setelah mencoba scroll sampai bawah dan memverifikasi halaman berikutnya termuat.

---
## AI Challenge
### AI Prompt Challenge

Gunakan prompt berikut:

```text
Buatkan repository layer Flutter untuk endpoint GET /comments?postId={id}
dari JSONPlaceholder menggunakan Dio + flutter_riverpod.
Requirements:
- Model Comment dengan fromJson aman null (postId, id, name, email, body).
- CommentRepository dengan method fetchComments(postId) + timeout 10 detik.
- AsyncNotifierProvider dengan penanganan error otomatis (AsyncError)
  dan fungsi pesan error ramah pengguna untuk timeout, connection error,
  404, dan 500.
- Satu unit test untuk fromJson dengan field yang hilang.
Jelaskan setiap bagian kode dalam komentar.
```

### AI Verification Checklist
- [ ] UI tidak memanggil Dio secara langsung; UI menggunakan repository.
- [ ] `fromJson` aman null dan tidak memakai cast langsung yang dapat crash.
- [ ] `DioExceptionType` timeout, connection error, dan bad response dipetakan ke pesan pengguna.
- [ ] Base URL dan timeout terpusat di satu client.
- [ ] Test menguji field yang hilang, bukan hanya happy path.
- [ ] Ditambahkan minimal satu edge case sendiri.
- [ ] `flutter analyze` dan `flutter test` selesai tanpa warning/error.

### Dokumentasi AI

Simpan artefak AI di folder `docs/`:

| Dokumen | Lokasi | Status |
| --- | --- | --- |
| Prompt yang digunakan | `docs/ai-prompt.md` | Isi setelah AI Challenge |
| Output awal AI | `docs/ai-output-awal.md` | Isi setelah AI Challenge |
| Hasil testing | `docs/ai-testing.md` | Isi setelah testing |

## Refactoring dan Testing

### Refactoring Challenge

Lakukan refactoring berikut pada project API, lalu commit dengan pesan yang jelas:

1. Ekstrak widget baris post menjadi `PostTile` agar `ListView.builder` lebih pendek dan mudah diuji.
2. Pindahkan `friendlyErrorMessage` ke `lib/data/network_errors.dart` agar dapat digunakan ulang oleh halaman paged dan non-paged.
3. Tambahkan halaman detail post dengan GoRouter pada route `/post/:id`.
4. Tampilkan `title` dan `body` lengkap pada halaman detail.
5. Ambil state detail dari list yang sudah dimuat atau gunakan repository bila halaman dibuka langsung.

### Testing: Unit Test Model dan Mock Repository

Buat `test/post_test.dart` dengan minimal empat skenario:

1. `fromJson` aman terhadap field yang hilang.
2. `friendlyErrorMessage` menghasilkan pesan yang sesuai untuk connection error.
3. Provider berhasil menggunakan repository palsu.
4. Provider menghasilkan error menggunakan repository palsu.

Gunakan `ProviderContainer` dan override repository agar test tidak melakukan request HTTP sungguhan.

Contoh model test:

```dart
test('fromJson aman terhadap field yang hilang', () {
  final post = Post.fromJson({'id': 7});

  expect(post.id, 7);
  expect(post.title, '');
  expect(post.userId, 0);
});
```

Jalankan verifikasi:

```bash
flutter analyze
flutter test
```

### Hasil Testing

| Perintah | Hasil |
| --- | --- |
| `flutter analyze` | Lulus / Gagal |
| `flutter test` | Lulus / Gagal |

## Tugas, Refleksi

### Mini Project / Industry Challenge

Bangun **aplikasi daftar data dari REST API** sebagai tugas minggu ini:

1. Ambil data dari JSONPlaceholder `/posts` atau API publik lain tanpa API key, lalu tampilkan melalui repository dan Riverpod.
2. Terapkan Dio terpusat dengan base URL, timeout, interceptor logging, dan model `fromJson` aman null.
3. Tampilkan loading, error dengan tombol retry, empty, dan success.
4. Tambahkan pagination dasar dengan *infinite scroll*, 10 item per halaman, dan guard request ganda.
5. Sertakan minimal dua test yang lulus: satu unit test model/error mapping dan satu test provider dengan repository palsu.
6. Kerjakan AI Challenge dan dokumentasikan prompt, hasil AI, perbaikan, serta alasan keputusan teknis di `docs/`.
7. Push ke repository portfolio pada folder `04-week-4-networking-rest-api/` dengan struktur `lib/`, `test/`, `docs/`, `README.md`, dan `screenshots/`.

README tugas menjelaskan:

- tujuan;
- fitur utama;
- stack teknologi;
- cara menjalankan;
- hasil yang dicapai.

### Refleksi

Tuliskan jawaban Anda sendiri:

1. Mengapa UI dilarang memanggil Dio langsung? Apa yang rusak jika aturan ini dilanggar?

   **Jawaban:**

2. Kapan pagination client-side cukup, dan kapan harus mengandalkan pagination server (`_page`/`_limit`)?

   **Jawaban:**

3. Bagaimana exception repository berubah menjadi `AsyncError` tanpa try/catch di setiap widget? Kapan try/catch eksplisit tetap dibutuhkan?

   **Jawaban:**

4. Bagian mana dari hasil AI yang Anda perbaiki, dan mengapa?

   **Jawaban:**

---
