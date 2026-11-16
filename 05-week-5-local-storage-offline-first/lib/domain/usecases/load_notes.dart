import '../../data/local/note.dart';
import '../repositories/note_repository_contract.dart';
import '../validators/note_validator.dart';

class NoteService {
  NoteService(this._repository);

  final NoteRepositoryContract _repository;

  Future<List<Note>> loadNotes() {
    return _repository.fetchNotes();
  }

  Future<Note> createNote({required String title, String body = ''}) {
    final error = validateNoteTitle(title);
    if (error != null) {
      throw ArgumentError(error);
    }
    return _repository.addNote(title: title.trim(), body: body.trim());
  }
}
