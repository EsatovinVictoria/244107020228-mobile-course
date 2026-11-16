import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:week5_offline_notes/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'alur utama pengguna menambah catatan dengan validasi dan mencarinya di daftar',
    (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_note_fab')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save_note_button')));
      await tester.pumpAndSettle();
      expect(find.text('Judul catatan tidak boleh kosong'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('note_title_field')),
        'Catatan Integrasi Minggu 12',
      );
      await tester.enterText(
        find.byKey(const Key('note_body_field')),
        'Verifikasi alur end to end aplikasi',
      );
      await tester.tap(find.byKey(const Key('save_note_button')));
      await tester.pumpAndSettle();

      expect(find.text('Catatan Integrasi Minggu 12'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('search_notes_field')),
        'Integrasi',
      );
      await tester.pumpAndSettle();

      expect(find.text('Catatan Integrasi Minggu 12'), findsOneWidget);
    },
  );
}
