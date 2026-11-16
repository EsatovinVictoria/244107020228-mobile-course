import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/pages/notes_page.dart';

class FakeStatefulNoteRepository extends NoteRepository {
  FakeStatefulNoteRepository({
    List<Note>? initialNotes,
    this.shouldFail = false,
  }) : _notes = List<Note>.from(initialNotes ?? const []),
       super(openDb: () => throw UnimplementedError());

  final List<Note> _notes;
  final bool shouldFail;

  @override
  Future<List<Note>> fetchNotes() async {
    if (shouldFail) {
      throw Exception('Gagal memuat catatan lokal');
    }
    return List<Note>.unmodifiable(_notes);
  }

  @override
  Future<Note> addNote({required String title, String body = ''}) async {
    if (shouldFail) {
      throw Exception('Gagal menyimpan catatan');
    }
    final note = Note(
      id: _notes.length + 1,
      title: title,
      body: body,
      updatedAt: DateTime(2026, 11, 16),
      dirty: true,
    );
    _notes.add(note);
    return note;
  }

  @override
  Future<int> countDirty() async => _notes.where((note) => note.dirty).length;
}

void main() {
  group('NotesPage Widget Tests (Validasi, Interaksi, Error)', () {
    testWidgets('menampilkan tampilan awal kosong saat belum ada catatan', (
      tester,
    ) async {
      final fakeRepo = FakeStatefulNoteRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [noteRepositoryProvider.overrideWithValue(fakeRepo)],
          child: const MaterialApp(home: NotesPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Offline Notes'), findsOneWidget);
      expect(find.text('Belum ada catatan.'), findsOneWidget);
      expect(find.byKey(const Key('add_note_fab')), findsOneWidget);
    });

    testWidgets(
      'menampilkan pesan validasi dan menahan dialog bila judul kosong atau hanya spasi',
      (tester) async {
        final fakeRepo = FakeStatefulNoteRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [noteRepositoryProvider.overrideWithValue(fakeRepo)],
            child: const MaterialApp(home: NotesPage()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('add_note_fab')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('note_title_field')),
          '   ',
        );
        await tester.tap(find.byKey(const Key('save_note_button')));
        await tester.pumpAndSettle();

        expect(find.text('Tambah Catatan'), findsOneWidget);
        expect(find.text('Judul catatan tidak boleh kosong'), findsOneWidget);
        expect(await fakeRepo.fetchNotes(), isEmpty);
      },
    );

    testWidgets(
      'menambahkan catatan baru dan menampilkannya di daftar saat input valid',
      (tester) async {
        final fakeRepo = FakeStatefulNoteRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [noteRepositoryProvider.overrideWithValue(fakeRepo)],
            child: const MaterialApp(home: NotesPage()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('add_note_fab')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('note_title_field')),
          'Latihan Widget Test',
        );
        await tester.enterText(
          find.byKey(const Key('note_body_field')),
          'Memeriksa form validasi catatan',
        );
        await tester.tap(find.byKey(const Key('save_note_button')));
        await tester.pumpAndSettle();

        expect(find.text('Tambah Catatan'), findsNothing);
        expect(find.text('Latihan Widget Test'), findsOneWidget);
        expect(find.text('Memeriksa form validasi catatan'), findsOneWidget);
      },
    );

    testWidgets(
      'menampilkan pesan error dan tombol coba lagi saat repository gagal',
      (tester) async {
        final fakeRepo = FakeStatefulNoteRepository(shouldFail: true);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [noteRepositoryProvider.overrideWithValue(fakeRepo)],
            child: const MaterialApp(home: NotesPage()),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Gagal memuat catatan lokal'),
          findsOneWidget,
        );
        expect(find.text('Coba lagi'), findsOneWidget);
      },
    );
  });
}
