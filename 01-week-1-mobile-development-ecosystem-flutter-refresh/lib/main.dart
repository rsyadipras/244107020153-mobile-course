import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Profil Mahasiswa')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified, size: 72), // Perubahan Icon
              SizedBox(height: 16),
              Text(
                'Risky Adi Prasetya',
                style: TextStyle(fontSize: 24),
              ), // Perubahan Nama
              Text('244107020153'), // Penambahan NIM
              Text(
                'D-IV Rekayasa Informatika',
                style: TextStyle(color: Colors.blue),
              ), // Penambahan Prodi
              Text('Pemrograman Mobile — Minggu 1'),
            ],
          ),
        ),
      ),
    );
  }
}
