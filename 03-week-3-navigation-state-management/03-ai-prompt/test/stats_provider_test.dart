import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stats_prompt/providers/stats_provider.dart';

/// Random deterministik untuk memaksa cabang sukses atau gagal.
class FixedRandom implements Random {
  FixedRandom(this.value);

  final double value;

  @override
  bool nextBool() => value >= 0.5;

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => (value * max).floor();
}

void main() {
  test('notifier mengembalikan tiga item saat request sukses', () async {
    // Override provider dengan delay nol dan random yang tidak gagal.
    final container = ProviderContainer(
      overrides: [
        statsProvider.overrideWith(
          () => StatsNotifier(random: FixedRandom(0.5), delay: Duration.zero),
        ),
      ],
    );
    addTearDown(container.dispose);

    // future selesai ketika AsyncNotifier menghasilkan data.
    final result = await container.read(statsProvider.future);

    expect(result, hasLength(3));
    expect(result.first.label, 'Pengunjung hari ini');
  });

  test('notifier menghasilkan error saat request gagal', () async {
    // Nilai 0.1 berada di bawah ambang kegagalan 0.3.
    final container = ProviderContainer(
      overrides: [
        statsProvider.overrideWith(
          () => StatsNotifier(random: FixedRandom(0.1), delay: Duration.zero),
        ),
      ],
    );
    addTearDown(container.dispose);

    // future harus melempar exception dari build notifier.
    await expectLater(
      container.read(statsProvider.future),
      throwsA(isA<Exception>()),
    );
  });
}
