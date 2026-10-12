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
