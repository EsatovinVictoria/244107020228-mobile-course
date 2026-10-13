import 'package:campus_notify/core/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatDate', () {
    test('menambahkan nol pada tanggal dan bulan satu digit', () {
      expect(formatDate(DateTime(2026, 1, 3)), '03/01/2026');
    });

    test('memformat tanggal dan bulan dua digit', () {
      expect(formatDate(DateTime(2026, 12, 31)), '31/12/2026');
    });

    test('memformat tanggal kabisat', () {
      expect(formatDate(DateTime(2024, 2, 29)), '29/02/2024');
    });

    test('tidak menyertakan bagian waktu', () {
      expect(formatDate(DateTime(2026, 10, 13, 15, 30, 45)), '13/10/2026');
    });
  });
}
