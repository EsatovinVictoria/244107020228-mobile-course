import '../../data/local/note.dart';

abstract interface class NoteRepositoryContract {
  Future<List<Note>> fetchNotes();
  Future<Note> addNote({required String title, String body = ''});
  Future<void> deleteNote(int id);
  Future<int> countDirty();
  Future<void> markAllSynced();
  Future<Note?> fetchNoteById(int id);
  Future<List<Note>> searchNotes(String query);
}
