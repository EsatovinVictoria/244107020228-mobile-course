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
