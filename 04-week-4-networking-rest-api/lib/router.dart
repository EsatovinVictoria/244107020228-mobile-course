import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/models/post.dart';
import 'pages/paged_post_page.dart';
import 'pages/post_detail_page.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return const PagedPostPage();
      },
    ),

    GoRoute(
      path: '/post/:id',
      builder: (context, state) {
        final id = int.tryParse(
          state.pathParameters['id'] ?? '',
        );

        if (id == null) {
          return const Scaffold(
            body: Center(
              child: Text('ID post tidak valid.'),
            ),
          );
        }

        final post = state.extra is Post
            ? state.extra as Post
            : null;

        return PostDetailPage(
          postId: id,
          post: post,
        );
      },
    ),
  ],
);