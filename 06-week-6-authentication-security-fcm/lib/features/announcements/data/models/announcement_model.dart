import '../../domain/entities/announcement.dart';

class AnnouncementModel extends Announcement {
  const AnnouncementModel({
    super.id,
    required super.title,
    super.body = '',
    required super.publishedAt,
  });

  factory AnnouncementModel.fromJson(Map<String, Object?> json) {
    return AnnouncementModel(
      id: (json['id'] as num?)?.toInt(),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      publishedAt:
          DateTime.tryParse(json['published_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'published_at': publishedAt.toIso8601String(),
  };

  Announcement toEntity() =>
      Announcement(id: id, title: title, body: body, publishedAt: publishedAt);
}
