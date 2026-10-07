import 'package:campus_notify/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('routeFromMessage', () {
    test('menerima rute pengumuman yang valid', () {
      expect(
        routeFromMessage({'route': '/pengumuman/3', 'id': '3'}),
        AppRoutes.announcement('3'),
      );
    });

    test('menerima rute Home', () {
      expect(routeFromMessage({'route': '/'}), AppRoutes.home);
    });

    test('payload kosong diarahkan ke Home', () {
      expect(routeFromMessage({}), AppRoutes.home);
    });

    test('route dengan tipe bukan String diarahkan ke Home', () {
      expect(routeFromMessage({'route': 123}), AppRoutes.home);
    });

    test('menolak rute tidak dikenal dan ID tidak valid', () {
      for (final route in [
        '/login',
        '/debug',
        '/pengumuman/abc',
        '/pengumuman/3/tambahan',
        'https://example.com/pengumuman/3',
      ]) {
        expect(
          routeFromMessage({'route': route}),
          AppRoutes.home,
          reason: 'Harus menolak $route',
        );
      }
    });

    test('tujuan mengikuti route ketika id berbeda', () {
      expect(
        routeFromMessage({'route': '/pengumuman/3', 'id': '9'}),
        AppRoutes.announcement('3'),
      );
    });
  });
}
