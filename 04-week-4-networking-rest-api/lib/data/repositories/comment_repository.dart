import 'package:dio/dio.dart';

import '../models/comment.dart';

/// Repository yang bertanggung jawab mengambil komentar dari API.
class CommentRepository {
  /// Menerima instance Dio agar repository mudah dipakai ulang dan diuji.
  CommentRepository(this._dio);

  final Dio _dio;

  /// Mengambil semua komentar untuk post tertentu.
  ///
  /// Timeout 10 detik berasal dari konfigurasi terpusat di [createDio].
  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List<dynamic>>(
      '/comments',
      queryParameters: {'postId': postId},
    );

    // Respons yang bukan list dianggap sebagai list kosong agar parsing aman.
    final data = response.data ?? <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}
