class Comment {
  final String id;
  final String author; // username
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
  });
}
