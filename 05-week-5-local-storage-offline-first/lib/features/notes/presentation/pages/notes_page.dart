import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/notes_providers.dart';
import '../../../../pages/cached_posts_page.dart';
import '../../../../pages/setting_page.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notesProvider);
    final dirtyCount = ref.watch(dirtyCountProvider);
    return state.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Catatan Offline')),
        body: const Center(child: CircularProgressIndicator()),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: null,
          icon: const Icon(Icons.add),
          label: const Text('Tambah'),
        ),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Catatan Offline')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gagal membaca catatan: $error'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(notesProvider),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: null,
          icon: const Icon(Icons.add),
          label: const Text('Tambah'),
        ),
      ),
      data: (notes) => Scaffold(
        appBar: AppBar(
          title: const Text('Catatan Offline'),
          actions: [
            IconButton(
              tooltip: 'Cache posts',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CachedPostsPage(),
                  ),
                );
              },
              icon: const Icon(Icons.cloud_outlined),
            ),
            IconButton(
              tooltip: 'Pengaturan',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
              icon: const Icon(Icons.settings_outlined),
            ),
            dirtyCount.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, _) => const Icon(Icons.error_outline),
              data: (count) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(child: Text('Belum sync: $count')),
              ),
            ),
            IconButton(
              tooltip: 'Sinkronkan catatan',
              onPressed: () => _sync(context, ref),
              icon: const Icon(Icons.sync),
            ),
          ],
        ),
        body: notes.isEmpty
            ? const Center(child: Text('Belum ada catatan.'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(notesProvider),
                child: ListView.separated(
                  itemCount: notes.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return ListTile(
                      onTap: () => context.push('/note/${note.id}'),
                      title: Text(note.title),
                      subtitle: Text(
                        note.body.isEmpty ? 'Tanpa isi' : note.body,
                      ),
                      leading: note.dirty
                          ? const Icon(Icons.cloud_upload_outlined)
                          : const Icon(Icons.check_circle_outline),
                      trailing: IconButton(
                        tooltip: 'Hapus catatan',
                        onPressed: () => _delete(context, ref, note.id!),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    );
                  },
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _add(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Tambah'),
        ),
      ),
    );
  }

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    try {
      final count = await ref.read(notesActionsProvider).syncNotes();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? 'Tidak ada catatan untuk disinkronkan.'
                : '$count catatan berhasil disinkronkan.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyinkronkan: $error')),
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    try {
      await ref.read(notesActionsProvider).deleteNote(id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus catatan: $error')),
      );
    }
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    try {
      final result = await showDialog<({String title, String body})>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tambah catatan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Judul'),
              ),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(labelText: 'Isi catatan'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                Navigator.pop(
                  context,
                  (title: title, body: bodyController.text.trim()),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      );
      if (result == null) return;
      await ref.read(notesActionsProvider).addNote(
            title: result.title,
            body: result.body,
          );
    } finally {
      titleController.dispose();
      bodyController.dispose();
    }
  }
}