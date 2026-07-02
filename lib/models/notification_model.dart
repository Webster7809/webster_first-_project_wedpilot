class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final String? entityId;
  final String? entityType;
  final bool isRead;
  final DateTime sentAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.entityId,
    this.entityType,
    required this.isRead,
    required this.sentAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['notif_id'] as String,
        userId: json['user_id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        entityId: json['entity_id'] as String?,
        entityType: json['entity_type'] as String?,
        isRead: json['is_read'] as bool? ?? false,
        sentAt: DateTime.parse(json['sent_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'notif_id': id,
        'user_id': userId,
        'type': type,
        'title': title,
        'body': body,
        'entity_id': entityId,
        'entity_type': entityType,
        'is_read': isRead,
        'sent_at': sentAt.toIso8601String(),
      };
}
