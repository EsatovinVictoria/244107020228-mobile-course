import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'api_client.dart';
import 'models/comment.dart';
import 'models/post.dart';
import 'repositories/comment_repository.dart';
import 'repositories/post_repository.dart';

final dioProvider = Provider<Dio>((ref) => createDio());

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(ref.watch(dioProvider))
);

// Repository di-inject melalui provider agar mudah diganti dengan mock saat test.
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(dioProvider)),
);

// Notifier menerima postId dari family sehingga tiap postId punya state sendiri.
class CommentsNotifier extends AsyncNotifier<List<Comment>> {
  CommentsNotifier(this.postId);

  final int postId;

  // Exception dibiarkan naik agar Riverpod membentuk AsyncError otomatis.
  @override
  Future<List<Comment>> build() {
    return ref.watch(commentRepositoryProvider).fetchComments(postId);
  }

  // Memuat ulang komentar dan mempertahankan penanganan state async Riverpod.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(commentRepositoryProvider).fetchComments(postId),
    );
  }
}

// Family membuat instance dan state notifier terpisah untuk setiap postId.
final commentsProvider = AsyncNotifierProvider.family<
  CommentsNotifier,
  List<Comment>,
  int
>(CommentsNotifier.new);

class PostListNotifier extends AsyncNotifier<List<Post>> {

  @override
  Future<List<Post>> build() async {
    final repository = ref.watch(postRepositoryProvider);
    return repository.fetchPosts();
  }

  Future<void> refresh() async {
    state = AsyncLoading();
    try {
      final repository = ref.read(postRepositoryProvider);
      state = AsyncData(await repository.fetchPosts());
    } catch(e, st) {
      state = AsyncError(e, st);
    }
  }
}

final postListProvider =
  AsyncNotifierProvider<PostListNotifier, List<Post>>(
    PostListNotifier.new,
      retry: (retryCount, error) => null
  );

Future<List<Post>> readPostsOnce(ProviderContainer container) {
  final completer = Completer<List<Post>>();
  final sub = container.listen<AsyncValue<List<Post>>>(
    postListProvider,
    (previous, next) {
      if (next.isLoading || completer.isCompleted) return;
      next.whenData(completer.complete);
      if (next.hasError) {
        completer.completeError(
          next.error ?? StateError('unknown error'),
          next.stackTrace ?? StackTrace.empty,
        );
      }
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}

Future<Object?> readPostsErrorOnce(ProviderContainer container) {
  final completer = Completer<Object?>();
  final sub = container.listen<AsyncValue<List<Post>>>(
    postListProvider,
    (previous, next) {
      if (next.isLoading || completer.isCompleted) return;
      completer.complete(next.error);
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}

/// Mengubah error jaringan menjadi pesan yang dapat dipahami pengguna.
String commentErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Permintaan terlalu lama. Periksa koneksi internet lalu coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      case DioExceptionType.badResponse:
        switch (error.response?.statusCode) {
          case 404:
            return 'Komentar tidak ditemukan.';
          case 500:
            return 'Server sedang bermasalah. Coba lagi nanti.';
          default:
            return 'Server mengembalikan error. Coba lagi nanti.';
        }
      default:
        return 'Terjadi kesalahan jaringan. Coba lagi.';
    }
  }
  return 'Terjadi kesalahan tak terduga. Coba lagi.';
}


