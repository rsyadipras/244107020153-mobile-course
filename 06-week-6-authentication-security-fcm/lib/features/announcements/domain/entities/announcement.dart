class Announcement {
  const Announcement({
    this.id,
    required this.title,
    this.body = '',
    required this.publishedAt,
  });

  final int? id;
  final String title;
  final String body;
  final DateTime publishedAt;
}
