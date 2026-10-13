import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  const AnnouncementRepositoryImpl();

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncement(
    String id,
  ) async {
    return (announcement: Announcement(id: id), failure: null);
  }
}
