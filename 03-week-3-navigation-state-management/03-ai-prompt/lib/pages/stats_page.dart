import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/stats_provider.dart';

/// Halaman statistik yang mengonsumsi state dari [statsProvider].
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watch membuat UI dibangun ulang ketika state asynchronous berubah.
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      body: statsAsync.when(
        // Spinner ditampilkan selama notifier menunggu data.
        loading: () => const Center(child: CircularProgressIndicator()),
        // Error menampilkan pesan dan tombol untuk meminta data ulang.
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gagal memuat statistik: $error'),
              const SizedBox(height: 12),
              FilledButton(
                // invalidate membuang state lama dan memanggil build lagi.
                onPressed: () => ref.invalidate(statsProvider),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        // Data sukses ditampilkan sebagai ListView berisi tiga item.
        data: (stats) => ListView.builder(
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final statistic = stats[index];
            return ListTile(
              leading: const Icon(Icons.bar_chart),
              title: Text(statistic.label),
              trailing: Text(
                statistic.value.toString(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          },
        ),
      ),
    );
  }
}
