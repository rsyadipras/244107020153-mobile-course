/// Model satu komentar dari JSONPlaceholder.
class Comment {
  /// Membuat model komentar dengan nilai yang sudah dinormalisasi.
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  final int postId;
  final int id;
  final String name;
  final String email;
  final String body;

  /// Mengubah JSON menjadi [Comment].
  ///
  /// Operator `as` dibuat nullable dan setiap field memiliki nilai default,
  /// sehingga respons dengan field hilang atau bernilai null tetap aman.
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      postId: (json['postId'] as num?)?.toInt() ?? 0,
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  /// Mengubah model kembali ke bentuk JSON.
  Map<String, dynamic> toJson() => {
    'postId': postId,
    'id': id,
    'name': name,
    'email': email,
    'body': body,
  };
}
