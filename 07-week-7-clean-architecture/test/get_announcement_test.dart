import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:campus_notify/features/announcements/domain/usecases/get_announcement.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAnnouncementRepository implements AnnouncementRepository {
  FakeAnnouncementRepository({this.announcement, this.failure});

  final Announcement? announcement;
  final Failure? failure;

  int calls = 0;
  String? receivedId;

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncement(
    String id,
  ) async {
    calls++;
    receivedId = id;

    return (announcement: announcement, failure: failure);
  }
}

void main() {
  group('GetAnnouncement', () {
    test('meneruskan ID dan pengumuman dari repository', () async {
      const announcement = Announcement(id: '3');

      final repo = FakeAnnouncementRepository(announcement: announcement);

      final result = await GetAnnouncement(repo).call('3');

      expect(result.failure, isNull);
      expect(result.announcement, same(announcement));
      expect(repo.receivedId, '3');
      expect(repo.calls, 1);
    });

    test('meneruskan Failure tanpa melempar exception', () async {
      const failure = NetworkFailure(
        'Tidak dapat mengambil pengumuman. Silakan coba lagi.',
      );

      final repo = FakeAnnouncementRepository(failure: failure);

      final result = await GetAnnouncement(repo).call('3');

      expect(result.announcement, isNull);
      expect(result.failure, same(failure));
      expect(repo.calls, 1);
    });

    test('menolak ID tidak valid tanpa memanggil repository', () async {
      for (final id in ['', 'abc', '-1', '3/tambahan']) {
        final repo = FakeAnnouncementRepository();

        final result = await GetAnnouncement(repo).call(id);

        expect(result.announcement, isNull);
        expect(result.failure, isA<LocalFailure>());
        expect(repo.calls, 0, reason: 'Harus menolak ID: $id');
      }
    });
  });
}
