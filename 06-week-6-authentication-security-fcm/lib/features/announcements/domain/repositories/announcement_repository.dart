import '../../../../core/failures.dart';
import '../entities/announcement.dart';

abstract class AnnouncementRepository {
  Future<({List<Announcement> items, Failure? failure})> fetchAnnouncements();
  Future<({Announcement? item, Failure? failure})> fetchAnnouncementById(
    String id,
  );
}
