import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/note_repository.dart';
import '../data/local/note.dart';
import '../data/sync_service.dart';
import '../providers/offline_provider.dart';
import 'posts_page.dart';

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(),
);

final notesProvider = FutureProvider<List<Note>>(
  (ref) => ref.watch(noteRepositoryProvider).fetchNotes(),
);

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  Future<void> _addNote(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tambah Catatan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                ),
              ),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(
                  labelText: 'Isi',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                final body = bodyController.text.trim();

                if (title.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop({
                  'title': title,
                  'body': body,
                });
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (result == null) {
      return;
    }

    final repository = ref.read(noteRepositoryProvider);

    await repository.addNote(
      title: result['title']!,
      body: result['body'] ?? '',
    );

    ref.invalidate(notesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notesProvider);
    final forceOffline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Notes'),
        actions: [
          IconButton(
            tooltip: forceOffline
                ? 'Sync tidak tersedia saat offline'
                : 'Sync Notes',
            icon: const Icon(Icons.sync),

            onPressed: forceOffline
                ? null
                : () async {
                    final repository = ref.read(
                      noteRepositoryProvider,
                    );

                    final syncedCount = await syncNotes(
                      repository,
                    );

                    ref.invalidate(notesProvider);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            syncedCount == 0
                                ? 'Tidak ada catatan yang perlu '
                                    'disinkronkan.'
                                : '$syncedCount catatan berhasil '
                                    'disinkronkan.',
                          ),
                        ),
                      );
                    }
                  },
          ),

          IconButton(
            tooltip: 'Lihat Posts',
            icon: const Icon(Icons.article_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PostsPage(),
                ),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Force Offline'),
            subtitle: Text(
              forceOffline
                  ? 'Simulasi offline aktif'
                  : 'Simulasi online aktif',
            ),
            value: forceOffline,
            onChanged: (value) {
              ref
                  .read(forceOfflineProvider.notifier)
                  .setOffline(value);
            },
          ),

          Expanded(
            child: state.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),

              data: (notes) {
                final dirtyCount = notes
                    .where((note) => note.dirty)
                    .length;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text(
                            'Dirty Notes: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Badge(
                            label: Text('$dirtyCount'),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    Expanded(
                      child: notes.isEmpty
                          ? const Center(
                              child: Text(
                                'Belum ada catatan.',
                              ),
                            )
                          : ListView.builder(
                              itemCount: notes.length,
                              itemBuilder: (context, index) {
                                final note = notes[index];

                                return ListTile(
                                  title: Text(note.title),
                                  subtitle: Text(note.body),
                                  trailing: note.dirty
                                      ? const Icon(
                                          Icons.cloud_off,
                                        )
                                      : const Icon(
                                          Icons.cloud_done,
                                        ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },

              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Error: $e'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(notesProvider);
                      },
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addNote(context, ref);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}