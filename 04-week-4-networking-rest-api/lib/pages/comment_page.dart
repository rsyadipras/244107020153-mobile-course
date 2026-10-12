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