import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  const AnnouncementRepositoryImpl({this.fetchJson});

  final Future<List<Map<String, Object?>>> Function()? fetchJson;

  @override
  Future<({List<Announcement> items, Failure? failure})>
  fetchAnnouncements() async {
    try {
      if (fetchJson != null) {
        final rows = await fetchJson!();
        final items = rows
            .map((row) => AnnouncementModel.fromJson(row).toEntity())
            .toList();
        return (items: items, failure: null);
      }

      await Future.delayed(const Duration(milliseconds: 300));
      final mockData = [
        Announcement(
          id: 3,
          title: 'Jadwal kuliah berubah',
          body: 'Kelas Mobile pindah ke Ruang A2 pukul 13.00.',
          publishedAt: DateTime.now(),
        ),
      ];
      return (items: mockData, failure: null);
    } catch (error) {
      return (
        items: const <Announcement>[],
        failure: NetworkFailure('Gagal memuat pengumuman: $error'),
      );
    }
  }

  @override
  Future<({Announcement? item, Failure? failure})> fetchAnnouncementById(
    String id,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final item = Announcement(
        id: int.tryParse(id) ?? 0,
        title: 'Pengumuman #$id',
        body: 'Jadwal kuliah Mobile berubah. Kelas dipindahkan ke Ruang A2 pukul 13.00.',
        publishedAt: DateTime.now(),
      );
      return (item: item, failure: null);
    } catch (error) {
      return (
        item: null,
        failure: NetworkFailure('Gagal mengambil detail pengumuman: $error'),
      );
    }
  }
}
