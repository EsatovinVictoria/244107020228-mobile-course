import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/announcement_repository_impl.dart';
import '../domain/repositories/announcement_repository.dart';
import '../domain/usecases/get_announcement.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => const AnnouncementRepositoryImpl(),
);

final getAnnouncementProvider = Provider<GetAnnouncement>((ref) {
  return GetAnnouncement(ref.watch(announcementRepositoryProvider));
});
