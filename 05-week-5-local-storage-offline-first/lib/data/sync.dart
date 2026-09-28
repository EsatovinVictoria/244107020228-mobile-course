import 'package:sqflite/sqflite.dart';

import 'local/db.dart';
import 'models/post.dart';
import 'repositories/note_repository.dart';
import 'repositories/post_repository.dart';

Future<List<Post>> readCachedPosts() async {
  final db = await openNotesDb();

  final rows = await db.query(
    'cached_posts',
    orderBy: 'id ASC',
  );

  return rows.map(Post.fromMap).toList();
}

Future<void> saveCachedPosts(List<Post> posts) async {
  final db = await openNotesDb();

  await db.transaction((txn) async {
    await txn.delete('cached_posts');

    for (final post in posts) {
      await txn.insert(
        'cached_posts',
        post.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  });
}

Future<List<Post>> loadPostsCacheFirst(
  PostRepository repository, {
  void Function()? onCacheUpdated,
}) async {
  final cached = await readCachedPosts();

  refreshPostsInBackground(
    repository,
    onCacheUpdated: onCacheUpdated,
  );

  return cached;
}

Future<void> refreshPostsInBackground(
  PostRepository repository, {
  void Function()? onCacheUpdated,
}) async {
  try {
    final posts = await repository.fetchPosts();

    await saveCachedPosts(posts);

    onCacheUpdated?.call();
  } catch (_) {}
}

Future<int> syncNotes(NoteRepository repository) async {
  final dirtyCount = await repository.countDirty();

  if (dirtyCount == 0) {
    return 0;
  }

  await Future.delayed(
    const Duration(seconds: 1),
  );

  await repository.markAllSynced();

  return dirtyCount;
}