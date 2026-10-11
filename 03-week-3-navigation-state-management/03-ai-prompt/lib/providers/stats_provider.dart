import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Model untuk satu statistik yang ditampilkan di dalam daftar.
class Statistic {
  const Statistic({required this.label, required this.value});

  /// Nama statistik, misalnya jumlah pengunjung.
  final String label;

  /// Nilai numerik statistik.
  final int value;
}

/// AsyncNotifier yang mensimulasikan pengambilan statistik dari server.
class StatsNotifier extends AsyncNotifier<List<Statistic>> {
  /// Dependency dibuat dapat diinjeksi agar unit test tidak acak dan cepat.
  StatsNotifier({Random? random, Duration? delay})
    : _random = random ?? Random(),
      _delay = delay ?? const Duration(seconds: 2);

  final Random _random;
  final Duration _delay;

  @override
  Future<List<Statistic>> build() async {
    // Delay dua detik mensimulasikan waktu tunggu permintaan network.
    await Future<void>.delayed(_delay);

    // Nilai acak di bawah 0.3 berarti request gagal (probabilitas 30%).
    if (_random.nextDouble() < 0.3) {
      throw Exception('Gagal mengambil data statistik.');
    }

    // Data sukses selalu terdiri dari tiga item statistik.
    return const [
      Statistic(label: 'Pengunjung hari ini', value: 1280),
      Statistic(label: 'Pesanan bulan ini', value: 342),
      Statistic(label: 'Pendapatan bulan ini', value: 87500000),
    ];
  }
}

/// Satu-satunya provider yang menyuplai state loading, error, atau data.
final statsProvider = AsyncNotifierProvider<StatsNotifier, List<Statistic>>(
  StatsNotifier.new,
  // Retry dilakukan eksplisit oleh tombol di UI, bukan otomatis berulang.
  retry: (retryCount, error) => null,
);
