import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';

class PostsPage extends ConsumerWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheFirst = ref.watch(postsCacheFirstProvider);

    final cachedPosts = ref.watch(cachedPostsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts Cache-first'),
        actions: [
          IconButton(
            tooltip: 'Refresh dari API',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(postsCacheFirstProvider);
            },
          ),
        ],
      ),
      body: cachedPosts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gagal membaca cache: $error'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(cachedPostsProvider);
                },
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Cache posts masih kosong.'),
                  const SizedBox(height: 8),
                  Text(
                    cacheFirst.isLoading
                        ? 'Mengambil data dari API...'
                        : 'Hubungkan internet lalu tekan Refresh.',
                  ),
                  if (cacheFirst.isLoading) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.storage),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${posts.length} posts dari cache SQLite'),
                    ),
                    if (cacheFirst.isLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];

                    return ListTile(
                      leading: CircleAvatar(child: Text('${post.id}')),
                      title: Text(post.title),
                      subtitle: Text(
                        post.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
