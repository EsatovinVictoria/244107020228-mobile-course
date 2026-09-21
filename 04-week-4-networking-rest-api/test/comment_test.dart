import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart';

void main() {
  test('Comment.fromJson memakai nilai default saat field hilang', () {
    // Map kosong mensimulasikan response JSON yang tidak lengkap.
    final comment = Comment.fromJson({});

    // Semua field tetap valid dan tidak menghasilkan exception cast/null.
    expect(comment.postId, 0);
    expect(comment.id, 0);
    expect(comment.name, '');
    expect(comment.email, '');
    expect(comment.body, '');
  });

  test('Comment.fromJson aman ketika beberapa field bernilai null', () {
    final comment = Comment.fromJson({
      'postId': null,
      'id': null,
      'name': null,
      'email': null,
      'body': null,
    });

    expect(comment.postId, 0);
    expect(comment.id, 0);
    expect(comment.name, '');
    expect(comment.email, '');
    expect(comment.body, '');
  });
}