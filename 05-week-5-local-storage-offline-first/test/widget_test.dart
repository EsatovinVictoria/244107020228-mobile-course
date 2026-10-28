import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/main.dart';
import 'package:week5_offline_notes/pages/notes_page.dart';

class SmokeFakeNoteRepository extends NoteRepository {
  SmokeFakeNoteRepository() : super(openDb: () => throw UnimplementedError());

  @override
  Future<List<Note>> fetchNotes() async => [];

  @override
  Future<int> countDirty() async => 0;
}

void main() {
  testWidgets('App renders Offline Notes title', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noteRepositoryProvider.overrideWithValue(SmokeFakeNoteRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Offline Notes'), findsOneWidget);
  });
}
