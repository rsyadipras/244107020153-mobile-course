File `comment.dart`:
```dart
/// Model satu komentar dari JSONPlaceholder.
class Comment {
  /// Membuat model komentar dengan nilai yang sudah dinormalisasi.
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  final int postId;
  final int id;
  final String name;
  final String email;
  final String body;

  /// Mengubah JSON menjadi [Comment].
  ///
  /// Operator `as` dibuat nullable dan setiap field memiliki nilai default,
  /// sehingga respons dengan field hilang atau bernilai null tetap aman.
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      postId: (json['postId'] as num?)?.toInt() ?? 0,
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  /// Mengubah model kembali ke bentuk JSON.
  Map<String, dynamic> toJson() => {
    'postId': postId,
    'id': id,
    'name': name,
    'email': email,
    'body': body,
  };
}
```

File `comment_repository.dart`:
```dart
import 'package:dio/dio.dart';

import '../models/comment.dart';

/// Repository yang bertanggung jawab mengambil komentar dari API.
class CommentRepository {
  /// Menerima instance Dio agar repository mudah dipakai ulang dan diuji.
  CommentRepository(this._dio);

  final Dio _dio;

  /// Mengambil semua komentar untuk post tertentu.
  ///
  /// Timeout ditetapkan di request ini agar kontrak repository tetap berlaku
  /// walaupun konfigurasi Dio dibuat dari tempat lain.
  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List<dynamic>>(
      '/comments',
      queryParameters: {'postId': postId},
      options: Options(
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    // Respons yang bukan list dianggap sebagai list kosong agar parsing aman.
    final data = response.data ?? <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}

```

File `comment_provider.dart`:
```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'models/comment.dart';
import 'repositories/comment_repository.dart';

/// Provider Dio bersama untuk repository komentar.
final commentDioProvider = Provider<Dio>((ref) => createDio());

/// Provider repository yang menerima Dio melalui dependency injection.
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(commentDioProvider)),
);

/// AsyncNotifier memuat komentar dan meneruskan exception menjadi AsyncError.
class CommentListNotifier extends AsyncNotifier<List<Comment>> {
  CommentListNotifier(this._postId);

  final int _postId;

  @override
  Future<List<Comment>> build() {
    // postId disimpan pada notifier yang dibuat oleh family sehingga setiap
    // post memiliki state AsyncValue yang terpisah.
    return ref.watch(commentRepositoryProvider).fetchComments(_postId);
  }

  /// Memuat ulang komentar dan mempertahankan status error Riverpod.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(commentRepositoryProvider).fetchComments(_postId),
    );
  }
}

/// Provider komentar untuk satu post.
final commentsProvider =
    AsyncNotifierProvider.family<CommentListNotifier, List<Comment>, int>(
      CommentListNotifier.new,
      // Riverpod tidak mengulang request otomatis agar timeout/error segera
      // diterima oleh UI dan mudah dipetakan ke pesan yang sesuai.
      retry: (retryCount, error) => null,
    );

/// Mengubah error jaringan menjadi pesan yang mudah dipahami pengguna.
String commentErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi terlalu lama (timeout). Periksa internet Anda lalu coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) {
          return 'Komentar untuk post tersebut tidak ditemukan (404).';
        }
        if (statusCode == 500) {
          return 'Server sedang bermasalah (500). Silakan coba lagi nanti.';
        }
        return 'Server mengembalikan error ($statusCode). Silakan coba lagi.';
      default:
        return 'Terjadi kesalahan jaringan. Silakan coba lagi.';
    }
  }

  return 'Terjadi kesalahan tak terduga. Silakan coba lagi.';
}

```

File `comment_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart';

void main() {
  test('Comment.fromJson mengisi default saat field hilang', () {
    // Hanya postId yang dikirim untuk memastikan semua field lain aman null.
    final comment = Comment.fromJson({'postId': 7});

    expect(comment.postId, 7);
    expect(comment.id, 0);
    expect(comment.name, '');
    expect(comment.email, '');
    expect(comment.body, '');
  });
}
```

File `comment_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/comment_provider.dart';

class CommentPage extends ConsumerWidget {
  const CommentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memanggil provider family untuk mengambil komentar post dengan ID 1.
    final commentsAsync = ref.watch(commentsProvider(1));

    // AsyncValue otomatis menangani loading, data, dan error.
    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),
      body: commentsAsync.when(
        // Ditampilkan selama request masih berjalan.
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),

        // Ditampilkan ketika data berhasil diterima.
        data: (comments) => ListView.builder(
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];

            return ListTile(
              title: Text(comment.name),
              subtitle: Text(comment.body),
              trailing: Text(comment.email),
            );
          },
        ),

        // Ditampilkan jika terjadi timeout, koneksi gagal, 404, atau 500.
        error: (error, stackTrace) => Center(
          child: Text(commentErrorMessage(error)),
        ),
      ),
    );
  }
}
```