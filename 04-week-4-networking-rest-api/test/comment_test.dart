import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart';

void main() {
  test('Comment.fromJson mengisi default saat field hilang', () {
    // Hanya postId yang dikirim untuk memastikan semua field lain aman null.
    final comment = Comment.fromJson({'postId': 7});

    expect(comment.postId, 7);
    expect(comment.id, 0);
    expect(comment.name, '');
    expect(comment.email, '');
    expect(comment.body, '');
  });

  test('Comment.fromJson aman saat semua field bernilai null', () {
    // Edge case: API dapat mengirim null, bukan hanya menghilangkan field.
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
