enum InquiryStatus { newInquiry, viewed, responded, quoted, booked, declined }

class Inquiry {
  final String id;
  final String coupleId;
  final String vendorId;
  final String? coupleName;
  final String? vendorName;
  final InquiryStatus status;
  final double? budgetRangeMin;
  final double? budgetRangeMax;
  final DateTime? weddingDate;
  final String message;
  final DateTime? respondedAt;
  final DateTime createdAt;

  const Inquiry({
    required this.id,
    required this.coupleId,
    required this.vendorId,
    this.coupleName,
    this.vendorName,
    required this.status,
    this.budgetRangeMin,
    this.budgetRangeMax,
    this.weddingDate,
    required this.message,
    this.respondedAt,
    required this.createdAt,
  });

  factory Inquiry.fromJson(Map<String, dynamic> json) => Inquiry(
        id: json['inquiry_id'] as String,
        coupleId: json['couple_id'] as String,
        vendorId: json['vendor_id'] as String,
        coupleName: json['couple_name'] as String?,
        vendorName: json['vendor_name'] as String?,
        status: InquiryStatus.values.byName(
          (json['status'] as String? ?? 'newInquiry')
              .replaceAll(' ', '')
              .toLowerCase(),
        ),
        budgetRangeMin: (json['budget_range_min'] as num?)?.toDouble(),
        budgetRangeMax: (json['budget_range_max'] as num?)?.toDouble(),
        weddingDate: json['wedding_date'] != null
            ? DateTime.parse(json['wedding_date'] as String)
            : null,
        message: json['message'] as String,
        respondedAt: json['responded_at'] != null
            ? DateTime.parse(json['responded_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class Conversation {
  final String id;
  final String coupleId;
  final String vendorId;
  final String? coupleName;
  final String? coupleAvatarUrl;
  final String? vendorName;
  final String? vendorAvatarUrl;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isArchived;

  const Conversation({
    required this.id,
    required this.coupleId,
    required this.vendorId,
    this.coupleName,
    this.coupleAvatarUrl,
    this.vendorName,
    this.vendorAvatarUrl,
    this.lastMessageText,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isArchived = false,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['convo_id'] as String,
        coupleId: json['couple_id'] as String,
        vendorId: json['vendor_id'] as String,
        coupleName: json['couple_name'] as String?,
        coupleAvatarUrl: json['couple_avatar_url'] as String?,
        vendorName: json['vendor_name'] as String?,
        vendorAvatarUrl: json['vendor_avatar_url'] as String?,
        lastMessageText: json['last_message_text'] as String?,
        lastMessageAt: json['last_message_at'] != null
            ? DateTime.parse(json['last_message_at'] as String)
            : null,
        unreadCount: json['unread_count'] as int? ?? 0,
        isArchived: json['is_archived'] as bool? ?? false,
      );
}

class Message {
  final String id;
  final String convoId;
  final String senderId;
  final String? senderName;
  final String? senderAvatarUrl;
  final String content;
  final String type;
  final bool isRead;
  final DateTime sentAt;

  const Message({
    required this.id,
    required this.convoId,
    required this.senderId,
    this.senderName,
    this.senderAvatarUrl,
    required this.content,
    this.type = 'text',
    this.isRead = false,
    required this.sentAt,
  });

  bool get isFile => type == 'file';
  bool get isImage => type == 'image';

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['message_id'] as String,
        convoId: json['convo_id'] as String,
        senderId: json['sender_id'] as String,
        senderName: json['sender_name'] as String?,
        senderAvatarUrl: json['sender_avatar_url'] as String?,
        content: json['content'] as String,
        type: json['type'] as String? ?? 'text',
        isRead: json['is_read'] as bool? ?? false,
        sentAt: DateTime.parse(json['sent_at'] as String),
      );
}
