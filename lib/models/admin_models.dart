class AdminOverview {
  final int activeCouples;
  final int registeredVendors;
  final int pendingVendorsCount;
  final int verificationRate;
  final int invitationsSentThisWeek;

  const AdminOverview({
    required this.activeCouples,
    required this.registeredVendors,
    required this.pendingVendorsCount,
    required this.verificationRate,
    required this.invitationsSentThisWeek,
  });

  factory AdminOverview.fromJson(Map<String, dynamic> json) => AdminOverview(
    activeCouples: json['active_couples'] as int,
    registeredVendors: json['registered_vendors'] as int,
    pendingVendorsCount: json['pending_vendors_count'] as int,
    verificationRate: json['verification_rate'] as int,
    invitationsSentThisWeek: json['invitations_sent_this_week'] as int,
  );
}

class AdminVendor {
  final String id;
  final String name;
  final String category;
  final DateTime submittedAt;
  final String? email;
  final String? phone;
  final String? location;
  final String? logoUrl;

  const AdminVendor({
    required this.id,
    required this.name,
    required this.category,
    required this.submittedAt,
    this.email,
    this.phone,
    this.location,
    this.logoUrl,
  });

  factory AdminVendor.fromJson(Map<String, dynamic> json) => AdminVendor(
    id: json['vendor_id'] as String,
    name: json['business_name'] as String,
    category: json['category'] as String,
    submittedAt: DateTime.parse(json['created_at'] as String),
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    location: json['location'] as String?,
    logoUrl: json['logo_url'] as String?,
  );
}

class AdminUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isSuspended;
  final DateTime joinedAt;
  final String? photoUrl;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isSuspended,
    required this.joinedAt,
    this.photoUrl,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
    id: json['user_id'] as String,
    name: (json['name'] as String?) ?? '(No name)',
    email: json['email'] as String,
    role: json['role'] as String,
    isSuspended: json['is_suspended'] as bool,
    joinedAt: DateTime.parse(json['created_at'] as String),
    photoUrl: json['photo_url'] as String?,
  );
}

/// A couple's private vendor feedback as seen by an admin — the raw
/// star + comment is never visible to other couples, only to the owning
/// vendor and admins (enforced server-side).
class AdminVendorFeedback {
  final String id;
  final String vendorId;
  final String vendor;
  final String coupleName;
  final int rating;
  final String? comment;
  final bool isFlagged;
  final String? flagReason;
  final DateTime createdAt;

  const AdminVendorFeedback({
    required this.id,
    required this.vendorId,
    required this.vendor,
    required this.coupleName,
    required this.rating,
    this.comment,
    required this.isFlagged,
    this.flagReason,
    required this.createdAt,
  });

  factory AdminVendorFeedback.fromJson(Map<String, dynamic> json) => AdminVendorFeedback(
    id: json['feedback_id'] as String,
    vendorId: json['vendor_id'] as String,
    vendor: json['vendor_name'] as String,
    coupleName: json['couple_name'] as String,
    rating: json['star_rating'] as int,
    comment: json['comment'] as String?,
    isFlagged: json['is_flagged'] as bool? ?? false,
    flagReason: json['flag_reason'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class FlaggedImage {
  final String id;
  final String vendor;
  final String category;
  final String flagReason;
  final String url;
  final String? thumbnailUrl;

  const FlaggedImage({
    required this.id,
    required this.vendor,
    required this.category,
    required this.flagReason,
    required this.url,
    this.thumbnailUrl,
  });

  factory FlaggedImage.fromJson(Map<String, dynamic> json) => FlaggedImage(
    id: json['media_id'] as String,
    vendor: json['vendor_name'] as String,
    category: json['category'] as String,
    flagReason: json['flag_reason'] as String,
    url: json['url'] as String,
    thumbnailUrl: json['thumbnail_url'] as String?,
  );
}

/// Placeholder shape for a future flagged-message queue — the messaging
/// system itself doesn't exist yet, so nothing produces this today.
class FlaggedMessage {
  final String id;
  final String sender;
  final String recipient;
  final String excerpt;
  final String flagReason;

  const FlaggedMessage({
    required this.id,
    required this.sender,
    required this.recipient,
    required this.excerpt,
    required this.flagReason,
  });
}

class AdminAnalytics {
  final List<int> userGrowthWeek;
  final List<int> userGrowthMonth;
  final List<int> userGrowthYear;
  final Map<String, int> vendorTierDistribution;
  final List<CategoryCount> topCategories;

  const AdminAnalytics({
    required this.userGrowthWeek,
    required this.userGrowthMonth,
    required this.userGrowthYear,
    required this.vendorTierDistribution,
    required this.topCategories,
  });

  factory AdminAnalytics.fromJson(Map<String, dynamic> json) {
    final growth = json['user_growth'] as Map<String, dynamic>;
    final tiers = json['vendor_tier_distribution'] as Map<String, dynamic>;
    return AdminAnalytics(
      userGrowthWeek: List<int>.from(growth['week'] as List),
      userGrowthMonth: List<int>.from(growth['month'] as List),
      userGrowthYear: List<int>.from(growth['year'] as List),
      vendorTierDistribution: tiers.map((k, v) => MapEntry(k, v as int)),
      topCategories: (json['top_categories'] as List)
          .map((c) => CategoryCount.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CategoryCount {
  final String category;
  final int count;
  const CategoryCount({required this.category, required this.count});

  factory CategoryCount.fromJson(Map<String, dynamic> json) => CategoryCount(
    category: json['category'] as String,
    count: json['count'] as int,
  );
}
