# Week 01 - Mobile Development Ecosystem Flutter Refresh

<p align="left">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Status-On Progress-brightgreen?style=for-the-badge" alt="Status">
</p>

- **Nama** : Risky Adi Prasetya
- **NIM** : 244107020153
- **Program Studi** : Teknik Informatika
- **Kelas** : TI- 3E

## Tujuan

## Fitur Utama

## Tech Stack

- **Framework:** Flutter & Dart
- **IDE:** VS Code
- **Device:** Smartphone Infinix
- **Version Control:** Github

## How to

Berikut adalah cara menjalankan project ini dengan metode **perangkat fisik:**

```bash
# 1. Lakukan clone/pull repositori
git pull https://github.com/rsyadipras/244107020153-mobile-course.git

# 2. Masuk ke dalam folder minggu ini
cd 02-week-2-declarative-ui-responsive-design

# 3. Pastikan Perangkat Fisik sudah terhubung menggunakan kabel data, dan sudah mengaktifkan mode usb debugging pada Developer Options

# 4. Jalankan aplikasi
flutter run
```

---

## Praktikum Layout Sederhana Warm-up

Kode Program

```dart
import 'package:flutter/material.dart';

void main() => runApp(const ProfileApp());

class ProfileApp extends StatelessWidget {
  const ProfileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: ProfileCard())),
    );
  }
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const CircleAvatar(child: Icon(Icons.person)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Nama Mahasiswa',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Risky Adi Prasetya'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: Text('NIM')),
              Text('244107020153'),
            ],
          ),
          const Row(
            children: [
              Expanded(child: Text('Kelas')),
              Text('TI - 3E'),
            ],
          ),
          const Row(
            children: [
              Expanded(child: Text('Email')),
              Text('244107020153@student.polinema.ac.id'),
            ],
          ),
        ],
      ),
    );
  }
}

```

<p align="center">
  <img src="screenshots\layout-warmup.jpeg" width="35%" alt="Default Warm-Up">
</p>

Eksperimen Warm-up

1. Hapus Expanded pada baris nama, lalu amati peringatan overflow atau perilaku layout-nya; kembalikan setelah itu.

```dart
  ...
    child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const CircleAvatar(child: Icon(Icons.person)),
              const SizedBox(width: 12),
              // Expanded( -> Menghapus Expanded untuk mengetahui efek apa yang akan terjadi
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Nama Mahasiswa',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Risky Adi Prasetyassssssssssssssssssssssssssssssss'),
                  ],
                ),
              // ),
            ],
          ),
  ...
```

   <p align="center">
  <img src="screenshots\expanded-effect.jpeg" width="35%" alt="Expanded Effect">
</p>

2. Ganti mainAxisSize: MainAxisSize.min menjadi nilai default dan amati perubahan tinggi kartu.

```dart
....
  child: Column(
      // mainAxisSize: MainAxisSize.min, -> ganti MainAixsSize menjadi default value
      children: [
        Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Nama Mahasiswa',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Risky Adi Prasetya'),
                ],
              ),
            ),
          ],
        ),
....
```

  <p align="center">
   <img src="screenshots\ubah-mainAxisSize.jpeg" width="35%" alt="mainAxisSize Effect">
  </p>

3. Tambahkan satu baris data (misal Email) menggunakan pola Row + Expanded yang sama.

```dart
...
          const Row(
            children: [
              Expanded(child: Text('Kelas')),
              Text('TI - 3E'),
            ],
          ),
          const Row(
            children: [
              Expanded(child: Text('Email')),
              Text('244107020153@student.polinema.ac.id'), // Penambahan Email
            ],
          ),
...
```

<p align="center">
  <img src="screenshots\add-email.jpeg" width="35%" alt="Tampilan tambah baris email">
</p>

---

## Praktikum: Dashboard Responsif

Menyiapkan Project

```dart
import 'package:flutter/material.dart';

void main() => runApp(const DashboardApp());

class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: Colors.indigo),
      themeMode: ThemeMode.system,
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Dashboard')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 700 ? 2 : 1;
          return GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.6,
            children: const [
              DashboardCard(title: 'Assignments', value: '8'),
              DashboardCard(title: 'Attendance', value: '92%'),
              DashboardCard(title: 'Portfolio', value: 'Ready'),
              DashboardCard(title: 'Current week', value: '02'),
            ],
          );
        },
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  const DashboardCard({required this.title, required this.value, super.key});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          Expanded(child: Text(title)),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
        ]),
      ),
    );
  }
}
```

  <p align="center">
    <img src="screenshots\defproj-dashb-responsive.jpeg" width="35%" alt="First Dashboard">
  </p>
  <p align="center">
    <i>Hasil Persiapan Project Awal Dashboard Responsive</i><br>
  </p>

Menambahkan interaksi: StatefulWidget dan Cupertino

```dart
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
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: Colors.indigo),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: DashboardPage(
        isDark: isDark,
        onDarkChanged: (value) => setState(() => isDark = value),
      ),
    );
  }
}
```

```dart
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
        title: const Text('Student Dashboard'),
        actions: [
          Row(
            children: [
              Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              const SizedBox(width: 4),
              CupertinoSwitch(
                value: isDark,
                onChanged: onDarkChanged,
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        // ... kode GridView sebelumnya, tidak berubah
      ),
    );
  }
}
```

  <p align="center">
    <img src="screenshots\statefulwidget-cupertino.jpeg" width="35%" alt="Stateful widget and cupertino">
  </p>

Eksperimen Layout

1. Ubah breakpoint dari 700 menjadi nilai lain dan amati perubahan jumlah kolom.
```dart
....
  body: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 300 ? 2 : 1; // ubah 700 -> 300
            return GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: columns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.6,
              children: const [
                DashboardCard(title: 'Assignments', value: '8'),
                DashboardCard(title: 'Attendance', value: '92%'),
                DashboardCard(title: 'Portfolio', value: 'Ready'),
                DashboardCard(title: 'Current week', value: '02'),
              ],
            );
          },
        ),
....
```
  <p align="center">
    <img src="screenshots\breakpoint-700-300.jpeg" width="35%" alt="breakpoint effect 700 to 300">
  </p>

2. Ubah themeMode menjadi ThemeMode.dark, lalu kembalikan ke ThemeMode.system.
```dart
....
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.indigo,
      ),
      themeMode: ThemeMode.system, // ubah themeMode.dark ke ThemeMode.system
      home: DashboardPage(
        isDark: isDark,
        onDarkChanged: (value) => setState(() => isDark = value),
      ),
    );
  }
....
```
  <p align="center">
    <img src="screenshots\thememode-system-default.jpeg" width="35%" alt="effect of changing thememode.dark into thememode.system">
  </p>

3. Uji aplikasi dengan ukuran layar emulator yang berbeda.
  <p align="center">
    <img src="screenshots\change-diff-screen-emu.jpeg" width="75%" alt="effect of changing screen devices">
  </p>
4. Tambahkan Semantics atau label yang bermakna pada elemen yang penting bagi screen reader.

```dart
....
  Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Student Dashboard'),
          actions: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                ),
                const SizedBox(width: 4),
                Semantics(
                  // Penambahan Semantics
                  label: 'Mode Gelap',
                  hint: 'Ketuk sekali untuk beralih antara mode terang dan gelap',
                  value: isDark ? 'Aktif' : 'Tidak aktif',
                  child: CupertinoSwitch(value: isDark, onChanged: onDarkChanged),
                ),
                const SizedBox(width: 12),
              ],
....

....
  Widget build(BuildContext context) {
      return Card(
        child: Semantics( // Penambahan Semantics
          label: '$title, nilainya adalah $value',
          container: true,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // ExcludeSemantics agar teks di dalamnya tidak dibaca dua kali
                Expanded(child: ExcludeSemantics(child: Text(title))),
                ExcludeSemantics(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
....
```

---

## Tugas dan AI design exploration

---

## Reflection

**1. Apa perbedaan cara berpikir imperative dan declarative saat membangun UI?**

- **2. Kapan Expanded membantu dan kapan penggunaannya justru menghasilkan layout error?**

- **3. Bagaimana breakpoint dan theme memengaruhi pengalaman pengguna?**

- **4. Apa yang Anda verifikasi dari rekomendasi AI setelah tugas inti selesai?**

-
