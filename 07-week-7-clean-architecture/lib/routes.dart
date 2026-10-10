class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const home = '/';
  static const debug = '/debug';

  static const announcementBase = '/pengumuman';
  static const announcementPattern = '$announcementBase/:id';

  static String announcement(String id) {
    return '$announcementBase/$id';
  }
}

/// Mengambil rute yang dikenali dari payload notifikasi.
///
/// Payload kosong atau rute tidak dikenal diarahkan ke Home.
/// ID pengumuman mengikuti format angka pada aplikasi ini.
String routeFromMessage(Map<String, dynamic> data) {
  final route = data['route'];

  if (route is! String) {
    return AppRoutes.home;
  }

  if (route == AppRoutes.home) {
    return AppRoutes.home;
  }

  final pattern = RegExp(
    '^${RegExp.escape(AppRoutes.announcementBase)}/([0-9]+)\$',
  );

  final match = pattern.firstMatch(route);

  if (match == null) {
    return AppRoutes.home;
  }

  return AppRoutes.announcement(match.group(1)!);
}
