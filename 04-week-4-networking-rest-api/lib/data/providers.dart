import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'api_client.dart';
import 'models/post.dart';
import 'repositories/post_repository.dart';

final dioProvider = Provider<Dio>((ref) => createDio());

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(ref.watch(dioProvider))
);

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

Future<List<Post>> readPostOnce(ProviderContainer container) {
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

String friendlyErrorMessage(Object error) {
  if(error is DioException) {
    switch(error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi lambat. Periksa internet anda';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung dengan server. Periksa internet anda';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 404) return 'Data tidak ditemukan (404)';
        if (code == 401 || code == 403) {
          return 'Akses ditolak ($code). Perika kredensial anda.';
        }
        return 'Server bermasalah ($code). Coba lagi nanti';
      default:
        return 'Terjadi kesalahan jaringan. Coba lagi';
    }
  }
  return 'Terjadi kesalahan tak terduga';
}


