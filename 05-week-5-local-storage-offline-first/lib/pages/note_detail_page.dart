import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/note.dart';
import '../data/repositories/note_repository.dart';

final noteDetailRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(),
);

final noteDetailProvider =
    FutureProvider.family<Note?, int>((ref, id) {
  return ref
      .watch(noteDetailRepositoryProvider)
      .fetchNoteById(id);
});

class NoteDetailPage extends ConsumerWidget {
  const NoteDetailPage({
    super.key,
    required this.noteId,
  });

  final int noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteState = ref.watch(
      noteDetailProvider(noteId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Catatan'),
      ),
      body: noteState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text('Error: $error'),
        ),
        data: (note) {
          if (note == null) {
            return const Center(
              child: Text('Catatan tidak ditemukan.'),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall,
                ),
                const SizedBox(height: 16),

                Text(note.body),

                const SizedBox(height: 24),

                Text(
                  'Updated at: ${note.updatedAt}',
                ),

                const SizedBox(height: 8),

                Text(
                  note.dirty
                      ? 'Status: Belum tersinkron'
                      : 'Status: Tersinkron',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}