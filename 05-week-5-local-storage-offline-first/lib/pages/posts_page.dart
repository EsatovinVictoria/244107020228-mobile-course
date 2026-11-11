import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';

class PostsPage extends ConsumerStatefulWidget {
  const PostsPage({super.key});

  @override
  ConsumerState<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends ConsumerState<PostsPage> {
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 15;
  int _visibleCount = _pageSize;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    final cached = ref.read(cachedPostsProvider).asData?.value ?? [];
    if (_isLoadingMore || _visibleCount >= cached.length) return;

    setState(() {
      _isLoadingMore = true;
    });

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _visibleCount = (_visibleCount + _pageSize).clamp(0, cached.length);
        _isLoadingMore = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final cacheFirst = ref.watch(postsCacheFirstProvider);
    final cachedPosts = ref.watch(cachedPostsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts Cache-first & Paging'),
        actions: [
          IconButton(
            tooltip: 'Refresh dari API',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _visibleCount = _pageSize;
              });
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

          final displayed = posts.take(_visibleCount).toList();
          final hasMore = _visibleCount < posts.length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.storage),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Menampilkan ${displayed.length} dari ${posts.length} posts (Lazy Paging)',
                      ),
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
                  controller: _scrollController,
                  itemCount: displayed.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == displayed.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }

                    final post = displayed[index];
                    return RepaintBoundary(
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${post.id}')),
                        title: Text(post.title),
                        subtitle: Text(
                          post.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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
