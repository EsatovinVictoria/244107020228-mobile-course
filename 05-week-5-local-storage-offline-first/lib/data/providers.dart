
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'models/post.dart';
import 'repositories/post_repository.dart';

final dioProvider = Provider<Dio>(
  (ref) => createDio(),
);

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(
    ref.watch(dioProvider),
  ),
);

final cachedPostsProvider = FutureProvider<List<Post>>(
  (ref) {
    return ref
        .watch(postRepositoryProvider)
        .readCachedPosts();
  },
);

final postsCacheFirstProvider = FutureProvider<List<Post>>(
  (ref) {
    final repository = ref.watch(postRepositoryProvider);

    return repository.loadPostsCacheFirst(
      onCacheUpdated: () {
        ref.invalidate(cachedPostsProvider);
      },
    );
  },
);
