import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Lebar minimum (px) untuk beralih dari 1 kolom ke 2 kolom
const double kWideBreakpoint = 700;

/// Rasio lebar : tinggi kartu pada GridView
const double kCardAspectRatio = 2.6;

/// Warna dasar tema untuk terang dan gelap
const Color kSeedColor = Colors.indigo;

/// Ukuran ikon di header profil
const double kHeaderIconSize = 56;

/// Padding halaman dan jarak antar kartu
const double kPagePadding = 16;

/// Membuat tema dari satu tempat, hanya brightness yang berbeda.
ThemeData buildTheme(Brightness brightness) => ThemeData(
  useMaterial3: true,
  brightness: brightness,
  colorSchemeSeed: kSeedColor,
);

void main() => runApp(const DashboardApp());

class DashboardApp extends StatefulWidget {
  const DashboardApp({super.key});

  @override
  State<DashboardApp> createState() => _DashboardAppState();
}

class _DashboardAppState extends State<DashboardApp> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: DashboardPage(
        isDark: isDark,
        onDarkChanged: (value) => setState(() => isDark = value),
      ),
    );
  }
}

// Header profil
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  static const String name = 'Risky Adi Prasetya';
  static const String nim = '244107020153';
  static const String prodi = 'D-IV Rekayasa Informatika';
  static const String course = 'Pemrograman Mobile — Minggu 2';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onColor = theme.colorScheme.onPrimaryContainer;

    return Semantics(
      container: true,
      label: 'Profil mahasiswa. Nama $name. NIM $nim. Program studi $prodi.',
      child: ExcludeSemantics(
        child: Container(
          margin: const EdgeInsets.fromLTRB(
            kPagePadding,
            kPagePadding,
            kPagePadding,
            0,
          ),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.verified, size: kHeaderIconSize, color: onColor),
              const SizedBox(width: kPagePadding),
              Expanded(
                // Warna teks diatur sekali untuk semua baris di bawahnya
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: onColor),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: onColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(nim),
                      const Text(prodi),
                      const Text(course),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Halaman utama
class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.isDark,
    required this.onDarkChanged,
    super.key,
  });
  final bool isDark;
  final ValueChanged<bool> onDarkChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Overview'),
        actions: [
          Row(
            children: [
              ExcludeSemantics(
                child: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              ),
              const SizedBox(width: 4),
              Semantics(
                label: 'Mode Gelap',
                hint: 'Ketuk sekali untuk beralih antara mode terang dan gelap',
                value: isDark ? 'Aktif' : 'Tidak aktif',
                child: CupertinoSwitch(value: isDark, onChanged: onDarkChanged),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= kWideBreakpoint ? 2 : 1;
          return Column(
            children: [
              const ProfileHeader(),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.all(kPagePadding),
                  crossAxisCount: columns,
                  crossAxisSpacing: kPagePadding,
                  mainAxisSpacing: kPagePadding,
                  childAspectRatio: kCardAspectRatio,
                  children: const [
                    InfoCard(title: 'Assignments', value: '8'),
                    InfoCard(title: 'Attendance', value: '92%'),
                    InfoCard(title: 'Portfolio', value: 'Ready'),
                    InfoCard(title: 'Current week', value: '02'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Kartu informasi reusable
class InfoCard extends StatelessWidget {
  const InfoCard({required this.title, required this.value, super.key});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Semantics(
        label: '$title, nilainya adalah $value',
        container: true,
        child: Container(
          padding: const EdgeInsets.all(20),
          alignment: Alignment.center,
          child: Row(
            children: [
              // ExcludeSemantics agar teks di dalamnya tidak dibaca dua kali
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              ExcludeSemantics(
                child: Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
