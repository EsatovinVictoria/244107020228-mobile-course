import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/local/note.dart';
import '../data/repositories/note_repository.dart';
import '../data/sync.dart';
import '../domain/usecases/search_notes.dart';
import '../providers/offline_provider.dart';
import '../widgets/note_tile.dart';
import 'posts_page.dart';

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(),
);

final notesProvider = FutureProvider<List<Note>>(
  (ref) => ref.watch(noteRepositoryProvider).fetchNotes(),
);

final searchNotesUseCaseProvider = Provider<SearchNotes>(
  (ref) => const SearchNotes(),
);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;
  void clear() => state = '';
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notesState = ref.watch(notesProvider);
  final query = ref.watch(searchQueryProvider);
  final searchUseCase = ref.watch(searchNotesUseCaseProvider);

  return notesState.whenData(
    (notes) => searchUseCase(notes: notes, query: query),
  );
});

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final result = await _showAddNoteDialog(context);
    if (result == null) return;

    final repository = ref.read(noteRepositoryProvider);
    await repository.addNote(
      title: result['title']!,
      body: result['body'] ?? '',
    );
    ref.invalidate(notesProvider);
  }

  Future<Map<String, String>?> _showAddNoteDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tambah Catatan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Judul'),
            ),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: 'Isi'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              final body = bodyController.text.trim();
              if (title.isEmpty) return;
              Navigator.of(dialogContext).pop({'title': title, 'body': body});
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(noteRepositoryProvider);
    final syncedCount = await syncNotes(repository);
    ref.invalidate(notesProvider);

    if (context.mounted) {
      final message = syncedCount == 0
          ? 'Tidak ada catatan yang perlu disinkronkan.'
          : '$syncedCount catatan berhasil disinkronkan.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(filteredNotesProvider);
    final forceOffline = ref.watch(forceOfflineProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Notes'),
        actions: [
          IconButton(
            tooltip: forceOffline
                ? 'Sync tidak tersedia saat offline'
                : 'Sync Notes',
            icon: const Icon(Icons.sync),
            onPressed: forceOffline ? null : () => _sync(context, ref),
          ),
          IconButton(
            tooltip: 'Lihat Posts',
            icon: const Icon(Icons.article_outlined),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => const PostsPage())),
          ),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Force Offline'),
            subtitle: Text(
              forceOffline ? 'Simulasi offline aktif' : 'Simulasi online aktif',
            ),
            value: forceOffline,
            onChanged: (value) {
              ref.read(forceOfflineProvider.notifier).setOffline(value);
            },
          ),
          _NotesSearchBar(searchQuery: searchQuery),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              data: (notes) => _NotesContent(
                notes: notes,
                isSearching: searchQuery.trim().isNotEmpty,
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Error: $e'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(notesProvider),
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
        onPressed: () => _addNote(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _NotesSearchBar extends ConsumerWidget {
  const _NotesSearchBar({required this.searchQuery});

  final String searchQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        key: const Key('search_notes_field'),
        decoration: InputDecoration(
          hintText: 'Cari catatan berdasarkan judul...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    ref.read(searchQueryProvider.notifier).clear();
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).setQuery(value);
        },
      ),
    );
  }
}

class _NotesContent extends StatelessWidget {
  const _NotesContent({required this.notes, required this.isSearching});

  final List<Note> notes;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final dirtyCount = notes.where((note) => note.dirty).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'Dirty Notes: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Badge(label: Text('$dirtyCount')),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: notes.isEmpty
              ? _NotesEmptyState(isSearching: isSearching)
              : ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return NoteTile(
                      note: note,
                      onTap: () => context.push('/note/${note.id}'),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _NotesEmptyState extends StatelessWidget {
  const _NotesEmptyState({required this.isSearching});

  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.note_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          Text(
            isSearching
                ? 'Tidak ada catatan dengan kata kunci tersebut.'
                : 'Belum ada catatan.',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
