import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/post.dart';
import '../data/network_errors.dart';
import '../data/providers.dart';

class PostDetailPage extends ConsumerWidget {
  const PostDetailPage({
    super.key,
    required this.postId,
    this.post,
  });

  final int postId;
  final Post? post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (post != null) {
      return _buildPage(post!);
    }

    final detail = ref.watch(postDetailProvider(postId));

    return detail.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(
          title: const Text('Detail Post'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              friendlyErrorMessage(error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: _buildPage,
    );
  }

  Widget _buildPage(Post post) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              post.body,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}