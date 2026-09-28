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

---

## Tugas dan AI design exploration

---

## Reflection

**1. Apa perbedaan cara berpikir imperative dan declarative saat membangun UI?**

- **2. Kapan Expanded membantu dan kapan penggunaannya justru menghasilkan layout error?**

- **3. Bagaimana breakpoint dan theme memengaruhi pengalaman pengguna?**

- **4. Apa yang Anda verifikasi dari rekomendasi AI setelah tugas inti selesai?**

-
