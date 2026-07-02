import '../core/utils/enum_utils.dart';

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
  final bool isCustomEntry;

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
    this.isCustomEntry = false,
  });

  VendorProfile copyWith({
    String? businessName,
    String? description,
    String? category,
    String? location,
    double? latitude,
    double? longitude,
    VendorTier? tier,
    VerificationStatus? verificationStatus,
    bool? isFeatured,
    List<String>? styleTags,
    String? logoUrl,
    String? phone,
    String? website,
    double? rating,
    int? reviewCount,
    double? compositeScore,
    List<VendorService>? services,
    List<VendorMedia>? media,
    bool? isCustomEntry,
  }) => VendorProfile(
        id: id,
        userId: userId,
        businessName: businessName ?? this.businessName,
        description: description ?? this.description,
        category: category ?? this.category,
        location: location ?? this.location,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        tier: tier ?? this.tier,
        verificationStatus: verificationStatus ?? this.verificationStatus,
        isFeatured: isFeatured ?? this.isFeatured,
        styleTags: styleTags ?? this.styleTags,
        logoUrl: logoUrl ?? this.logoUrl,
        phone: phone ?? this.phone,
        website: website ?? this.website,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        compositeScore: compositeScore ?? this.compositeScore,
        services: services ?? this.services,
        media: media ?? this.media,
        isCustomEntry: isCustomEntry ?? this.isCustomEntry,
      );

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
    final compositeNorm = (compositeScore / 100.0).clamp(0.0, 1.0);
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
        tier: enumByName(VendorTier.values, json['tier'] as String?, VendorTier.free),
        verificationStatus: enumByName(VerificationStatus.values, json['verification_status'] as String?, VerificationStatus.pending),
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
        isCustomEntry: json['is_custom_entry'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'vendor_id': id,
        'user_id': userId,
        'business_name': businessName,
        'description': description,
        'category': category,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'tier': tier.name,
        'verification_status': verificationStatus.name,
        'is_featured': isFeatured,
        'style_tags': styleTags,
        'logo_url': logoUrl,
        'phone': phone,
        'website': website,
        'rating': rating,
        'review_count': reviewCount,
        'composite_score': compositeScore,
        'services': services.map((s) => s.toJson()).toList(),
        'media': media.map((m) => m.toJson()).toList(),
        'is_custom_entry': isCustomEntry,
      };
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

  VendorService copyWith({
    String? title,
    String? description,
    double? priceMin,
    double? priceMax,
    String? unit,
    bool? isActive,
  }) => VendorService(
        id: id,
        vendorId: vendorId,
        title: title ?? this.title,
        description: description ?? this.description,
        priceMin: priceMin ?? this.priceMin,
        priceMax: priceMax ?? this.priceMax,
        unit: unit ?? this.unit,
        isActive: isActive ?? this.isActive,
      );

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

  Map<String, dynamic> toJson() => {
        'service_id': id,
        'vendor_id': vendorId,
        'title': title,
        'description': description,
        'price_min': priceMin,
        'price_max': priceMax,
        'unit': unit,
        'is_active': isActive,
      };
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

  VendorMedia copyWith({
    String? type,
    String? url,
    String? thumbnailUrl,
    int? sortOrder,
    bool? isFeatured,
  }) => VendorMedia(
        id: id,
        vendorId: vendorId,
        type: type ?? this.type,
        url: url ?? this.url,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        sortOrder: sortOrder ?? this.sortOrder,
        isFeatured: isFeatured ?? this.isFeatured,
      );

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

  Map<String, dynamic> toJson() => {
        'media_id': id,
        'vendor_id': vendorId,
        'type': type,
        'url': url,
        'thumbnail_url': thumbnailUrl,
        'sort_order': sortOrder,
        'is_featured': isFeatured,
      };
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
