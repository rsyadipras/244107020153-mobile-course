import 'package:flutter/material.dart';

class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pengumuman')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengumuman #$id',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text(
              'Jadwal kuliah Mobile berubah. Kelas dipindahkan ke Ruang A2 '
              'pukul 13.00.',
            ),
          ],
        ),
      ),
    );
  }
}
