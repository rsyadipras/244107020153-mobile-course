import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/providers/notes_providers.dart';
import 'features/notes/presentation/pages/notes_page.dart';
import 'pages/note_detail_page.dart';

void main() {
  runApp(const ProviderScope(child: OfflineNotesApp()));
}

class OfflineNotesApp extends ConsumerWidget {
  const OfflineNotesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(darkModeProvider);
    // Memuat provider ini saat aplikasi dibuka untuk mencatat waktu terakhir.
    ref.watch(lastOpenedProvider);

    // GoRouter membuat URL detail bisa dibuka langsung dengan /note/:id.
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const NotesPage()),
        GoRoute(
          path: '/note/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) {
              return const Scaffold(
                body: Center(child: Text('ID catatan tidak valid')),
              );
            }
            return NoteDetailPage(id: id);
          },
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Offline Notes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: darkMode.value == true ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
