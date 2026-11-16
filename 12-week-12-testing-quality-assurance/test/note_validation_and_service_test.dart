import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/domain/repositories/note_repository_contract.dart';
import 'package:week5_offline_notes/domain/usecases/load_notes.dart';
import 'package:week5_offline_notes/domain/validators/note_validator.dart';

class FakeNoteRepositoryContract implements NoteRepositoryContract {
  FakeNoteRepositoryContract({List<Note>? initialNotes, this.error})
    : _notes = List<Note>.from(initialNotes ?? const []);

  final List<Note> _notes;
  final Exception? error;

  @override
  Future<List<Note>> fetchNotes() async {
    if (error != null) throw error!;
    return List<Note>.unmodifiable(_notes);
  }

  @override
  Future<Note> addNote({required String title, String body = ''}) async {
    if (error != null) throw error!;
    final created = Note(
      id: _notes.length + 1,
      title: title,
      body: body,
      updatedAt: DateTime(2026, 11, 16),
      dirty: true,
    );
    _notes.add(created);
    return created;
  }

  @override
  Future<void> deleteNote(int id) async {
    if (error != null) throw error!;
    _notes.removeWhere((note) => note.id == id);
  }

  @override
  Future<int> countDirty() async {
    if (error != null) throw error!;
    return _notes.where((note) => note.dirty).length;
  }

  @override
  Future<void> markAllSynced() async {
    if (error != null) throw error!;
  }

  @override
  Future<Note?> fetchNoteById(int id) async {
    if (error != null) throw error!;
    for (final note in _notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  @override
  Future<List<Note>> searchNotes(String query) async {
    if (error != null) throw error!;
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return List<Note>.unmodifiable(_notes);
    return _notes
        .where(
          (n) =>
              n.title.toLowerCase().contains(trimmed) ||
              n.body.toLowerCase().contains(trimmed),
        )
        .toList();
  }
}

void main() {
  group('isValidNoteTitle dan validateNoteTitle', () {
    test('menerima judul valid termasuk dengan spasi di tepi', () {
      const input = '  Belajar Pengujian Flutter  ';

      final isValid = isValidNoteTitle(input);
      final error = validateNoteTitle(input);

      expect(isValid, isTrue);
      expect(error, isNull);
    });

    test('menolak string kosong atau hanya spasi', () {
      expect(isValidNoteTitle(''), isFalse);
      expect(isValidNoteTitle('   \t\n  '), isFalse);
      expect(validateNoteTitle(''), 'Judul catatan tidak boleh kosong');
      expect(validateNoteTitle('   '), 'Judul catatan tidak boleh kosong');
    });

    test('menerima panjang tepat 100 karakter dan menolak 101 karakter', () {
      final exactBoundary = 'a' * 100;
      final overBoundary = 'a' * 101;

      expect(isValidNoteTitle(exactBoundary), isTrue);
      expect(validateNoteTitle(exactBoundary), isNull);

      expect(isValidNoteTitle(overBoundary), isFalse);
      expect(
        validateNoteTitle(overBoundary),
        'Judul catatan maksimal 100 karakter',
      );
    });
  });

  group('NoteService dengan FakeNoteRepositoryContract', () {
    test('loadNotes mengembalikan daftar catatan saat sukses', () async {
      final sample = [
        Note(
          id: 1,
          title: 'Rangkuman Bab 12',
          body: 'Unit, Widget, Integration',
          updatedAt: DateTime(2026, 11, 16),
          dirty: false,
        ),
      ];
      final service = NoteService(
        FakeNoteRepositoryContract(initialNotes: sample),
      );

      final result = await service.loadNotes();

      expect(result, hasLength(1));
      expect(result.first.title, 'Rangkuman Bab 12');
    });

    test('loadNotes meneruskan exception saat repository gagal', () async {
      final service = NoteService(
        FakeNoteRepositoryContract(error: Exception('Database terkunci')),
      );

      expect(service.loadNotes(), throwsException);
    });

    test('createNote memangkas spasi judul dan menyimpan catatan', () async {
      final fakeRepo = FakeNoteRepositoryContract();
      final service = NoteService(fakeRepo);

      final created = await service.createNote(
        title: '  Tugas Minggu 12  ',
        body: '  Buat test suite  ',
      );

      expect(created.title, 'Tugas Minggu 12');
      expect(created.body, 'Buat test suite');
      expect(await service.loadNotes(), hasLength(1));
    });

    test('createNote melempar ArgumentError bila judul tidak valid', () async {
      final fakeRepo = FakeNoteRepositoryContract();
      final service = NoteService(fakeRepo);

      expect(
        () => service.createNote(title: '   ', body: 'Isi'),
        throwsArgumentError,
      );
    });
  });
}
