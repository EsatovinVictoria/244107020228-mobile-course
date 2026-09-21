import 'package:dio/dio.dart';

import '../models/comment.dart';

/// Menyediakan akses khusus untuk endpoint komentar.
class CommentRepository {
  CommentRepository(this._dio);

  final Dio _dio;

  /// Mengambil komentar untuk post tertentu dengan batas waktu 10 detik.
  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List<dynamic>>(
      '/comments',
      queryParameters: {'postId': postId},
    );

    // Hanya item berbentuk object yang dipetakan agar response yang tidak
    // sesuai kontrak tidak membuat seluruh parsing gagal.
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}