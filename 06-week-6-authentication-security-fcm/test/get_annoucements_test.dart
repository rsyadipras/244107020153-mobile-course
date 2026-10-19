import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:campus_notify/features/announcements/domain/usecases/get_announcements.dart';

class FakeAnnouncementRepository implements AnnouncementRepository {
  FakeAnnouncementRepository({this.items = const [], this.failure});

  final List<Announcement> items;
  final Failure? failure;

  @override
  Future<({List<Announcement> items, Failure? failure})>
  fetchAnnouncements() async {
    return (items: items, failure: failure);
  }

  @override
  Future<({Announcement? item, Failure? failure})> fetchAnnouncementById(
    String id,
  ) async {
    return (item: items.isEmpty ? null : items.first, failure: failure);
  }
}

void main() {
  test('GetAnnouncements meneruskan daftar dari repository', () async {
    final repository = FakeAnnouncementRepository(
      items: [
        Announcement(
          title: 'Jadwal kuliah umum',
          publishedAt: DateTime(2026, 9, 27),
        ),
      ],
    );

    final result = await GetAnnouncements(repository).call();

    expect(result.failure, isNull);
    expect(result.items, hasLength(1));
    expect(result.items.first.title, 'Jadwal kuliah umum');
  });

  test(
    'GetAnnouncements meneruskan failure tanpa melempar exception',
    () async {
      final repository = FakeAnnouncementRepository(
        failure: const NetworkFailure('offline (simulasi)'),
      );

      final result = await GetAnnouncements(repository).call();

      expect(result.failure, isA<NetworkFailure>());
      expect(result.items, isEmpty);
    },
  );
}
