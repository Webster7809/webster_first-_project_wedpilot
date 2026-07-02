import '../core/utils/enum_utils.dart';

enum ReviewStatus { pending, approved, rejected, flagged }

class Review {
  final String id;
  final String coupleId;
  final String vendorId;
  final String? coupleName;
  final String? coupleAvatarUrl;
  final int rating;
  final String title;
  final String body;
  final ReviewStatus status;
  final List<String> photoUrls;
  final DateTime? publishedAt;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.coupleId,
    required this.vendorId,
    this.coupleName,
    this.coupleAvatarUrl,
    required this.rating,
    required this.title,
    required this.body,
    required this.status,
    this.photoUrls = const [],
    this.publishedAt,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['review_id'] as String,
        coupleId: json['couple_id'] as String,
        vendorId: json['vendor_id'] as String,
        coupleName: json['couple_name'] as String?,
        coupleAvatarUrl: json['couple_avatar_url'] as String?,
        rating: json['rating'] as int,
        title: json['title'] as String,
        body: json['body'] as String,
        status: enumByName(ReviewStatus.values, json['status'] as String?, ReviewStatus.pending),
        photoUrls: List<String>.from(json['photo_urls'] ?? []),
        publishedAt: json['published_at'] != null
            ? DateTime.parse(json['published_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'review_id': id,
        'couple_id': coupleId,
        'vendor_id': vendorId,
        'couple_name': coupleName,
        'couple_avatar_url': coupleAvatarUrl,
        'rating': rating,
        'title': title,
        'body': body,
        'status': status.name,
        'photo_urls': photoUrls,
        'published_at': publishedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}
