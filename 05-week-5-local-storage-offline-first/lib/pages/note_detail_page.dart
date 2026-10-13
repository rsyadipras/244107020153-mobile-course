import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers/notes_providers.dart';

class NoteDetailPage extends ConsumerWidget {
  const NoteDetailPage({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Detail mengambil ulang data dari repository berdasarkan ID route.
    final note = ref.watch(noteByIdProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Catatan')),
      body: note.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Gagal membaca catatan: $error')),
        data: (item) {
          if (item == null) {
            return const Center(child: Text('Catatan tidak ditemukan'));
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                item.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(item.body.isEmpty ? 'Tanpa isi' : item.body),
              const SizedBox(height: 24),
              Text(
                item.dirty ? 'Belum tersinkron' : 'Sudah tersinkron',
                style: TextStyle(
                  color: item.dirty
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
