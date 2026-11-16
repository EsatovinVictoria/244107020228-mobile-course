import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/domain/usecases/search_notes.dart';
import 'package:week5_offline_notes/pages/notes_page.dart';

class FilterFakeNoteRepository extends NoteRepository {
  FilterFakeNoteRepository({this.items = const []})
    : super(openDb: () => throw UnimplementedError());

  final List<Note> items;

  @override
  Future<List<Note>> fetchNotes() async => items;

  @override
  Future<List<Note>> searchNotes(String query) async {
    const useCase = SearchNotes();
    return useCase(notes: items, query: query);
  }

  @override
  Future<int> countDirty() async => items.where((n) => n.dirty).length;
}

void main() {
  group('Search Filter Pure Domain UseCase Test', () {
    const useCase = SearchNotes();

    final sampleNotes = [
      Note(
        id: 1,
        title: 'Catatan Belanja Pasar',
        body: 'Beli sayur dan buah',
        updatedAt: DateTime(2026, 10, 1),
      ),
      Note(
        id: 2,
        title: 'BELANJA Bulanan Supermarket',
        body: 'Sabun, sampo, dan deterjen',
        updatedAt: DateTime(2026, 10, 2),
      ),
      Note(
        id: 3,
        title: 'Kuliah Pemrograman Mobile',
        body: 'Arsitektur Clean Architecture Flutter',
        updatedAt: DateTime(2026, 10, 3),
      ),
      Note(
        id: 4,
        title: 'Catatan Singkat',
        body: '',
        updatedAt: DateTime(2026, 10, 4),
      ),
    ];

    test('filter abaikan huruf besar/kecil', () {
      final results = useCase(notes: sampleNotes, query: 'belanja');
      expect(results, hasLength(2));
      expect(results.any((n) => n.id == 1), isTrue);
      expect(results.any((n) => n.id == 2), isTrue);
    });

    test('query tak cocok kembalikan kosong', () {
      final results = useCase(notes: sampleNotes, query: 'zzz-tak-ada');
      expect(results, isEmpty);
    });

    test('filter mencocokkan kata kunci pada body catatan', () {
      final results = useCase(notes: sampleNotes, query: 'deterjen');
      expect(results, hasLength(1));
      expect(results.first.id, 2);
    });

    test('filter mengabaikan spasi berlebih pada awal dan akhir query', () {
      final results = useCase(notes: sampleNotes, query: '   mobile   ');
      expect(results, hasLength(1));
      expect(results.first.id, 3);
    });

    test('filter query kosong mengembalikan seluruh catatan', () {
      final results = useCase(notes: sampleNotes, query: '   ');
      expect(results, hasLength(4));
    });

    test('filter aman terhadap catatan dengan body kosong', () {
      final results = useCase(notes: sampleNotes, query: 'singkat');
      expect(results, hasLength(1));
      expect(results.first.id, 4);
    });
  });

  group('Widget Test Empty State', () {
    testWidgets('menampilkan widget empty state saat pencarian tidak cocok', (
      tester,
    ) async {
      final sample = [
        Note(
          id: 1,
          title: 'Catatan Penting',
          body: 'Isi catatan',
          updatedAt: DateTime.now(),
        ),
      ];

      final repo = FilterFakeNoteRepository(items: sample);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [noteRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: NotesPage()),
        ),
      );

      await tester.pumpAndSettle();

      // Catatan awal tampil
      expect(find.text('Catatan Penting'), findsOneWidget);

      // Cari input search field
      final searchField = find.byKey(const Key('search_notes_field'));
      expect(searchField, findsOneWidget);

      // Masukkan query yang tidak cocok
      await tester.enterText(searchField, 'KataKunciTakDikenal');
      await tester.pumpAndSettle();

      // Catatan lama menghilang
      expect(find.text('Catatan Penting'), findsNothing);

      // Empty state tampil dengan teks dan ikon search_off
      expect(
        find.text('Tidak ada catatan dengan kata kunci tersebut.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.search_off), findsOneWidget);

      // Bersihkan pencarian dengan menekan tombol clear
      final clearButton = find.byIcon(Icons.clear);
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Catatan muncul kembali
      expect(find.text('Catatan Penting'), findsOneWidget);
    });
  });
}
