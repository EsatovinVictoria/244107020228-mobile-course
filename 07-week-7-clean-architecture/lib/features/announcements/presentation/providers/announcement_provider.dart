import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../di/announcement_providers.dart';
import '../../domain/entities/announcement.dart';

final announcementProvider = FutureProvider.autoDispose
    .family<Announcement, String>((ref, id) async {
      final getAnnouncement = ref.watch(getAnnouncementProvider);
      final result = await getAnnouncement(id);

      final failure = result.failure;
      if (failure != null) {
        throw failure;
      }

      final announcement = result.announcement;
      if (announcement == null) {
        throw const LocalFailure('Pengumuman tidak tersedia.');
      }

      return announcement;
    });
