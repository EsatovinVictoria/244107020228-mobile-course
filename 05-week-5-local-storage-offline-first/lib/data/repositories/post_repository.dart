import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../local/db.dart';
import '../models/post.dart';

class PostRepository {
  PostRepository(
    this._dio, {
    Future<Database> Function()? openDb,
  }) : _openDb = openDb ?? openNotesDb;

  final Dio _dio;
  final Future<Database> Function() _openDb;

  Future<List<Post>> fetchPosts() async {
    final response = await _dio.get<List>('/posts');
    final data = response.data ?? [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(Post.fromJson)
        .toList();
  }

  Future<List<Post>> readCachedPosts() async {
    final db = await _openDb();

    final rows = await db.query(
      'cached_posts',
      orderBy: 'id ASC',
    );

    return rows.map(Post.fromMap).toList();
  }

  Future<void> saveCachedPosts(List<Post> posts) async {
    final db = await _openDb();

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

  Future<List<Post>> loadPostsCacheFirst({
    void Function()? onCacheUpdated,
  }) async {
    final cached = await readCachedPosts();

    refreshPostsInBackground(
      onCacheUpdated: onCacheUpdated,
    );

    return cached;
  }

  Future<void> refreshPostsInBackground({
    void Function()? onCacheUpdated,
  }) async {
    try {
      final posts = await fetchPosts();

      await saveCachedPosts(posts);

      onCacheUpdated?.call();
    } catch (_) {}
  }
}