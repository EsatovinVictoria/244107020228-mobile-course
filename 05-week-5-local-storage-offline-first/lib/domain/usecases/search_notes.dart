import '../../data/local/note.dart';

class SearchNotes {
  const SearchNotes();

  List<Note> call({required List<Note> notes, required String query}) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return notes;
    }

    return notes.where((note) {
      final titleMatch = note.title.toLowerCase().contains(trimmed);
      final bodyMatch = note.body.toLowerCase().contains(trimmed);
      return titleMatch || bodyMatch;
    }).toList();
  }
}
