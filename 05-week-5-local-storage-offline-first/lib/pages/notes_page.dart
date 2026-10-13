import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/local/note.dart';
import '../data/providers/notes_providers.dart';
import '../data/sync.dart';
import 'cached_posts_page.dart';
import 'setting_page.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  bool _openingDialog = false;

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);
    final dirtyCount = ref.watch(dirtyCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: [
          IconButton(
            tooltip: 'Cache posts',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CachedPostsPage()),
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
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('Belum sync: $count')),
            ),
          ),
          IconButton(
            tooltip: 'Sinkronkan catatan',
            onPressed: () async {
              final count = await syncNotes(
                ref.read(noteRepositoryProvider),
              );
              ref.invalidate(notesProvider);
              ref.invalidate(dirtyCountProvider);
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
            },
            icon: const Icon(Icons.sync),
          ),
        ],
      ),
      body: notes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
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
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Belum ada catatan'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(notesProvider.notifier).reload(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final note = items[index];
                return NoteTile(
                  note: note,
                  onOpen: () => context.push('/note/${note.id}'),
                  onDelete: () => ref
                      .read(notesProvider.notifier)
                      .deleteNote(note.id!),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openingDialog ? null : _openAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }

  Future<void> _openAddDialog() async {
    setState(() => _openingDialog = true);
    try {
      await showDialog<void>(
        context: context,
        builder: (_) => AddNoteDialog(
          onSave: (title, body) => ref
              .read(notesProvider.notifier)
              .addNote(title: title, body: body),
        ),
      );
    } finally {
      if (mounted) setState(() => _openingDialog = false);
    }
  }
}

class AddNoteDialog extends StatefulWidget {
  const AddNoteDialog({required this.onSave, super.key});

  final Future<void> Function(String title, String body) onSave;

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _saving) return;

    setState(() => _saving = true);
    try {
      await widget.onSave(title, _bodyController.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah catatan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Judul',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Isi catatan',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}

class NoteTile extends StatelessWidget {
  const NoteTile({
    required this.note,
    required this.onOpen,
    required this.onDelete,
    super.key,
  });

  final Note note;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    // Widget ini memusatkan tampilan baris dan badge status dirty.
    return ListTile(
      onTap: onOpen,
      title: Text(note.title),
      subtitle: Text(note.body.isEmpty ? 'Tanpa isi' : note.body),
      leading: note.dirty
          ? const Chip(
              avatar: Icon(Icons.cloud_upload_outlined, size: 16),
              label: Text('Belum sync'),
            )
          : const Icon(Icons.check_circle_outline),
      trailing: IconButton(
        onPressed: onDelete,
        tooltip: 'Hapus',
        icon: const Icon(Icons.delete_outline),
      ),
    );
  }
}
