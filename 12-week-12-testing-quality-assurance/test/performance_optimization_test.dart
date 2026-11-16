import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/models/post.dart';
import 'package:week5_offline_notes/data/providers.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/pages/posts_page.dart';
import 'package:week5_offline_notes/widgets/note_tile.dart';

class FakePagedNoteRepository extends NoteRepository {
  FakePagedNoteRepository(this.dummyNotes)
    : super(openDb: () => throw UnimplementedError());

  final List<Note> dummyNotes;

  @override
  Future<List<Note>> fetchNotes() async => dummyNotes;

  @override
  Future<List<Note>> fetchNotesPaged({int offset = 0, int limit = 20}) async {
    if (offset >= dummyNotes.length) return [];
    final end = (offset + limit).clamp(0, dummyNotes.length);
    return dummyNotes.sublist(offset, end);
  }

  @override
  Future<int> countDirty() async =>
      dummyNotes.where((note) => note.dirty).length;
}

void main() {
  group('Performance Optimization Unit & Widget Tests', () {
    test('fetchNotesPaged mengembalikan subset data sesuai parameter limit dan offset', () async {
      final sampleNotes = List.generate(
        35,
        (i) => Note(
          id: i + 1,
          title: 'Catatan $i',
          body: 'Isi $i',
          updatedAt: DateTime.now(),
          dirty: false,
        ),
      );

      final repo = FakePagedNoteRepository(sampleNotes);

      final page1 = await repo.fetchNotesPaged(offset: 0, limit: 15);
      expect(page1.length, 15);
      expect(page1.first.title, 'Catatan 0');
      expect(page1.last.title, 'Catatan 14');

      final page2 = await repo.fetchNotesPaged(offset: 15, limit: 15);
      expect(page2.length, 15);
      expect(page2.first.title, 'Catatan 15');
      expect(page2.last.title, 'Catatan 29');

      final page3 = await repo.fetchNotesPaged(offset: 30, limit: 15);
      expect(page3.length, 5);
      expect(page3.first.title, 'Catatan 30');
      expect(page3.last.title, 'Catatan 34');

      final emptyPage = await repo.fetchNotesPaged(offset: 40, limit: 15);
      expect(emptyPage.isEmpty, isTrue);
    });

    testWidgets(
      'NoteTile dibungkus RepaintBoundary untuk mengisolasi rendering paint',
      (tester) async {
        final note = Note(
          id: 101,
          title: 'Optimized Note',
          body: 'Content for paint isolation',
          updatedAt: DateTime.now(),
          dirty: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NoteTile(key: const ValueKey('test_tile'), note: note),
            ),
          ),
        );

        expect(find.byType(NoteTile), findsOneWidget);
        expect(find.byType(RepaintBoundary), findsWidgets);
        expect(find.text('Optimized Note'), findsOneWidget);
        expect(find.text('Content for paint isolation'), findsOneWidget);
        expect(find.text('Belum tersinkron'), findsOneWidget);
      },
    );

    testWidgets(
      'PostsPage menampilkan header lazy paging dan membatasi item awal sesuai batch size',
      (tester) async {
        final dummyPosts = List.generate(
          40,
          (i) => Post(
            id: i + 1,
            userId: 1,
            title: 'Judul Post ${i + 1}',
            body: 'Body Post ${i + 1}',
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              cachedPostsProvider.overrideWithValue(
                AsyncValue.data(dummyPosts),
              ),
              postsCacheFirstProvider.overrideWithValue(
                AsyncValue.data(dummyPosts),
              ),
            ],
            child: const MaterialApp(home: PostsPage()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Posts Cache-first & Paging'), findsOneWidget);
        expect(
          find.text('Menampilkan 15 dari 40 posts (Lazy Paging)'),
          findsOneWidget,
        );
        expect(find.text('Judul Post 1'), findsOneWidget);
        expect(find.text('Judul Post 2'), findsOneWidget);
        expect(find.text('Judul Post 16'), findsNothing);
      },
    );
  });
}
