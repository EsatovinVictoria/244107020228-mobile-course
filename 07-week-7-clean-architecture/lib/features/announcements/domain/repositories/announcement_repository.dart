import '../../../../core/failures.dart';
import '../entities/announcement.dart';

abstract class AnnouncementRepository {
  Future<({Announcement? announcement, Failure? failure})> getAnnouncement(
    String id,
  );
}
