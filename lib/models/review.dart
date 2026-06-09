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
  final String? vendorReply;
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
    this.vendorReply,
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
        status: ReviewStatus.values.byName(json['status'] as String? ?? 'pending'),
        vendorReply: json['vendor_reply'] as String?,
        photoUrls: List<String>.from(json['photo_urls'] ?? []),
        publishedAt: json['published_at'] != null
            ? DateTime.parse(json['published_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
