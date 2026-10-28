import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/pages/notes_page.dart';

class SearchFakeNoteRepository extends NoteRepository {
  SearchFakeNoteRepository({this.items = const []})
    : super(openDb: () => throw UnimplementedError());

  final List<Note> items;

  @override
  Future<List<Note>> fetchNotes() async => items;

  @override
  Future<List<Note>> searchNotes(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return items;
    return items.where((n) => n.title.toLowerCase().contains(trimmed)).toList();
  }

  @override
  Future<int> countDirty() async => items.where((n) => n.dirty).length;
}

void main() {
  group('Search Notes Repository & Provider Logic', () {
    final sampleNotes = [
      Note(
        id: 1,
        title: 'Catatan Kuliah Mobile',
        body: 'Belajar Flutter dan SQLite',
        updatedAt: DateTime(2026, 10, 1),
      ),
      Note(
        id: 2,
        title: 'Daftar Belanja',
        body: 'Beli kopi dan susu',
        updatedAt: DateTime(2026, 10, 2),
      ),
      Note(
        id: 3,
        title: 'KULIAH Pemrograman Web',
        body: 'React dan Node.js',
        updatedAt: DateTime(2026, 10, 3),
      ),
    ];

    test(
      'searchNotes mengembalikan seluruh catatan jika query kosong',
      () async {
        final repo = SearchFakeNoteRepository(items: sampleNotes);
        final results = await repo.searchNotes('');
        expect(results.length, 3);
      },
    );

    test('searchNotes menyaring catatan berdasarkan kecocokan judul', () async {
      final repo = SearchFakeNoteRepository(items: sampleNotes);
      final results = await repo.searchNotes('Belanja');
      expect(results.length, 1);
      expect(results.first.title, 'Daftar Belanja');
    });

    test('searchNotes bersifat case-insensitive', () async {
      final repo = SearchFakeNoteRepository(items: sampleNotes);
      final results = await repo.searchNotes('kuliah');
      expect(results.length, 2);
      expect(results.any((n) => n.id == 1), isTrue);
      expect(results.any((n) => n.id == 3), isTrue);
    });

    test(
      'searchNotes menghasilkan list kosong jika kata kunci tidak ditemukan',
      () async {
        final repo = SearchFakeNoteRepository(items: sampleNotes);
        final results = await repo.searchNotes('Algoritma');
        expect(results, isEmpty);
      },
    );

    test(
      'filteredNotesProvider bereaksi terhadap perubahan searchQueryProvider',
      () async {
        final container = ProviderContainer(
          overrides: [
            noteRepositoryProvider.overrideWithValue(
              SearchFakeNoteRepository(items: sampleNotes),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Awalnya query kosong
        final initialNotes = await container.read(notesProvider.future);
        expect(initialNotes.length, 3);

        final filteredInitial = container.read(filteredNotesProvider);
        expect(filteredInitial.value?.length, 3);

        // Ubah query menjadi 'Belanja'
        container.read(searchQueryProvider.notifier).setQuery('Belanja');

        final filteredResult = container.read(filteredNotesProvider);
        expect(filteredResult.value?.length, 1);
        expect(filteredResult.value?.first.title, 'Daftar Belanja');
      },
    );
  });

  group('NotesPage Search Widget Test', () {
    final sampleNotes = [
      Note(
        id: 1,
        title: 'Catatan Flutter',
        body: 'State Management Riverpod',
        updatedAt: DateTime.now(),
      ),
      Note(
        id: 2,
        title: 'Rapat Organisasi',
        body: 'Membahas proker',
        updatedAt: DateTime.now(),
      ),
    ];

    testWidgets(
      'menampilkan search field dan menyaring tampilan catatan secara interaktif',
      (tester) async {
        final repo = SearchFakeNoteRepository(items: sampleNotes);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [noteRepositoryProvider.overrideWithValue(repo)],
            child: const MaterialApp(home: NotesPage()),
          ),
        );

        // Tunggu data notes termuat
        await tester.pumpAndSettle();

        // Memastikan kedua catatan tampil awal
        expect(find.text('Catatan Flutter'), findsOneWidget);
        expect(find.text('Rapat Organisasi'), findsOneWidget);

        // Cari TextField pencarian berdasarkan Key
        final searchField = find.byKey(const Key('search_notes_field'));
        expect(searchField, findsOneWidget);

        // Ketik 'flutter' di kotak pencarian
        await tester.enterText(searchField, 'flutter');
        await tester.pumpAndSettle();

        // Hanya Catatan Flutter yang tampil
        expect(find.text('Catatan Flutter'), findsOneWidget);
        expect(find.text('Rapat Organisasi'), findsNothing);

        // Ketik kata kunci yang tidak ada: 'NonExistentNote'
        await tester.enterText(searchField, 'NonExistentNote');
        await tester.pumpAndSettle();

        // Memastikan Empty State pencarian muncul
        expect(
          find.text('Tidak ada catatan dengan kata kunci tersebut.'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.search_off), findsOneWidget);

        // Tekan tombol clear (Icons.clear)
        final clearButton = find.byIcon(Icons.clear);
        expect(clearButton, findsOneWidget);
        await tester.tap(clearButton);
        await tester.pumpAndSettle();

        // Kedua catatan muncul kembali
        expect(find.text('Catatan Flutter'), findsOneWidget);
        expect(find.text('Rapat Organisasi'), findsOneWidget);
      },
    );
  });

  group('filterNotes Pure Domain Function Test', () {
    final list = [
      Note(
        id: 1,
        title: 'Daftar Belanja Pasar',
        updatedAt: DateTime(2026, 10, 1),
      ),
      Note(id: 2, title: 'BELANJA Bulanan', updatedAt: DateTime(2026, 10, 2)),
      Note(id: 3, title: 'Catatan Kuliah', updatedAt: DateTime(2026, 10, 3)),
    ];

    test('filter abaikan huruf besar/kecil', () {
      expect(filterNotes(list, 'belanja'), hasLength(2));
    });

    test('query tak cocok kembalikan kosong', () {
      expect(filterNotes(list, 'zzz-tak-ada'), isEmpty);
    });

    test('query kosong kembalikan seluruh catatan', () {
      expect(filterNotes(list, ''), hasLength(3));
    });
  });
}
