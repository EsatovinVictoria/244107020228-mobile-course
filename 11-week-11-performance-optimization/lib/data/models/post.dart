class Post {
  const Post({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
  });

  final int userId;
  final int id;
  final String title;
  final String body;

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'id': id,
    'title': title,
    'body': body,
  };

  factory Post.fromMap(Map<String, Object?> map) {
    return Post(
      userId: (map['user_id'] as num?)?.toInt() ?? 0,
      id: (map['id'] as num?)?.toInt() ?? 0,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
    );
  }

  Map<String, Object?> toMap() => {
    'user_id': userId,
    'id': id,
    'title': title,
    'body': body,
  };
}
