import '../routes.dart';

String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString().padLeft(4, '0');

  return '$day/$month/$year';
}

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
