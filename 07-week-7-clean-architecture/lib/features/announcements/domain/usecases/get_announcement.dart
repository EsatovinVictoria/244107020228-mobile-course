import '../../../../core/failures.dart';
import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

class GetAnnouncement {
  const GetAnnouncement(this._repository);

  final AnnouncementRepository _repository;

  Future<({Announcement? announcement, Failure? failure})> call(
    String id,
  ) async {
    if (!RegExp(r'^[0-9]+$').hasMatch(id)) {
      return (
        announcement: null,
        failure: const LocalFailure('ID pengumuman tidak valid.'),
      );
    }

    return _repository.getAnnouncement(id);
  }
}
