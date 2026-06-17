enum VerificationStatus { pending, verified, rejected }
enum VendorTier { free, pro, premium }

/// Broad price classification used by the AI recommendation engine.
enum VendorPriceTier { high, mid, low }

class VendorProfile {
  final String id;
  final String userId;
  final String businessName;
  final String? description;
  final String category;
  final String? location;
  final double? latitude;
  final double? longitude;
  final VendorTier tier;
  final VerificationStatus verificationStatus;
  final bool isFeatured;
  final List<String> styleTags;
  final String? logoUrl;
  final String? phone;
  final String? website;
  final double? rating;
  final int reviewCount;
  final double compositeScore;
  final List<VendorService> services;
  final List<VendorMedia> media;

  const VendorProfile({
    required this.id,
    required this.userId,
    required this.businessName,
    this.description,
    required this.category,
    this.location,
    this.latitude,
    this.longitude,
    required this.tier,
    required this.verificationStatus,
    this.isFeatured = false,
    this.styleTags = const [],
    this.logoUrl,
    this.phone,
    this.website,
    this.rating,
    this.reviewCount = 0,
    this.compositeScore = 0,
    this.services = const [],
    this.media = const [],
  });

  bool get isVerified => verificationStatus == VerificationStatus.verified;

  /// Derived from [tier]: premium → high, pro → mid, free → low.
  VendorPriceTier get priceTier => switch (tier) {
    VendorTier.premium => VendorPriceTier.high,
    VendorTier.pro => VendorPriceTier.mid,
    VendorTier.free => VendorPriceTier.low,
  };

  /// Composite 0–1 score combining rating, composite score, and review volume.
  double get performanceScore {
    final ratingNorm = (rating ?? 0) / 5.0;
    final compositeNorm = compositeScore / 100.0;
    final reviewNorm = (reviewCount / 200.0).clamp(0.0, 1.0);
    return ratingNorm * 0.5 + compositeNorm * 0.35 + reviewNorm * 0.15;
  }

  double get priceMin {
    if (services.isEmpty) return 0;
    return services.map((s) => s.priceMin).reduce((a, b) => a < b ? a : b);
  }

  double get priceMax {
    if (services.isEmpty) return 0;
    return services.map((s) => s.priceMax).reduce((a, b) => a > b ? a : b);
  }

  factory VendorProfile.fromJson(Map<String, dynamic> json) => VendorProfile(
        id: json['vendor_id'] as String,
        userId: json['user_id'] as String,
        businessName: json['business_name'] as String,
        description: json['description'] as String?,
        category: json['category'] as String,
        location: json['location'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        tier: VendorTier.values.byName(json['tier'] as String? ?? 'free'),
        verificationStatus: VerificationStatus.values.byName(
            json['verification_status'] as String? ?? 'pending'),
        isFeatured: json['is_featured'] as bool? ?? false,
        styleTags: List<String>.from(json['style_tags'] ?? []),
        logoUrl: json['logo_url'] as String?,
        phone: json['phone'] as String?,
        website: json['website'] as String?,
        rating: (json['rating'] as num?)?.toDouble(),
        reviewCount: json['review_count'] as int? ?? 0,
        compositeScore: (json['composite_score'] as num?)?.toDouble() ?? 0,
        services: (json['services'] as List<dynamic>? ?? [])
            .map((s) => VendorService.fromJson(s as Map<String, dynamic>))
            .toList(),
        media: (json['media'] as List<dynamic>? ?? [])
            .map((m) => VendorMedia.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}

class VendorService {
  final String id;
  final String vendorId;
  final String title;
  final String? description;
  final double priceMin;
  final double priceMax;
  final String unit;
  final bool isActive;

  const VendorService({
    required this.id,
    required this.vendorId,
    required this.title,
    this.description,
    required this.priceMin,
    required this.priceMax,
    required this.unit,
    this.isActive = true,
  });

  factory VendorService.fromJson(Map<String, dynamic> json) => VendorService(
        id: json['service_id'] as String,
        vendorId: json['vendor_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        priceMin: (json['price_min'] as num).toDouble(),
        priceMax: (json['price_max'] as num).toDouble(),
        unit: json['unit'] as String? ?? 'package',
        isActive: json['is_active'] as bool? ?? true,
      );
}

class VendorMedia {
  final String id;
  final String vendorId;
  final String type;
  final String url;
  final String? thumbnailUrl;
  final int sortOrder;
  final bool isFeatured;

  const VendorMedia({
    required this.id,
    required this.vendorId,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.sortOrder = 0,
    this.isFeatured = false,
  });

  bool get isVideo => type == 'video';

  factory VendorMedia.fromJson(Map<String, dynamic> json) => VendorMedia(
        id: json['media_id'] as String,
        vendorId: json['vendor_id'] as String,
        type: json['type'] as String,
        url: json['url'] as String,
        thumbnailUrl: json['thumbnail_url'] as String?,
        sortOrder: json['sort_order'] as int? ?? 0,
        isFeatured: json['is_featured'] as bool? ?? false,
      );
}

class VendorMatch {
  final String vendorId;
  final VendorProfile vendor;
  final double finalScore;
  final double reputationScore;
  final double budgetScore;
  final double locationScore;
  final double availabilityScore;
  final String? reasoning;
  final int rankInCategory;
  final int totalInCategory;

  const VendorMatch({
    required this.vendorId,
    required this.vendor,
    required this.finalScore,
    required this.reputationScore,
    required this.budgetScore,
    required this.locationScore,
    required this.availabilityScore,
    this.reasoning,
    required this.rankInCategory,
    required this.totalInCategory,
  });
}
