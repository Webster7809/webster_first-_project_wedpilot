import '../core/utils/enum_utils.dart';
import '../core/utils/json_utils.dart';
import 'budget_class.dart';

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
  final String? whatsapp;
  final String? contactEmail;
  final String? address;
  final String? instagramHandle;
  final List<String> blockedDates;
  final double? rating;
  final int feedbackCount;
  final double compositeScore;
  // ── Public CRS badges (see backend services/vendorStats.js) ──────────────
  final double? respondsInMinutes;
  final int weddingsCompleted;
  final double? onTimeRate;
  final double? recommendRate;
  final List<VendorService> services;
  final List<VendorMedia> media;

  /// Wedding-class packages this vendor has registered (see [VendorPackage]).
  final List<VendorPackage> packages;
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
    this.whatsapp,
    this.contactEmail,
    this.address,
    this.instagramHandle,
    this.blockedDates = const [],
    this.rating,
    this.feedbackCount = 0,
    this.compositeScore = 0,
    this.respondsInMinutes,
    this.weddingsCompleted = 0,
    this.onTimeRate,
    this.recommendRate,
    this.services = const [],
    this.media = const [],
    this.packages = const [],
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
    String? whatsapp,
    String? contactEmail,
    String? address,
    String? instagramHandle,
    List<String>? blockedDates,
    double? rating,
    int? feedbackCount,
    double? compositeScore,
    double? respondsInMinutes,
    int? weddingsCompleted,
    double? onTimeRate,
    double? recommendRate,
    List<VendorService>? services,
    List<VendorMedia>? media,
    List<VendorPackage>? packages,
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
        whatsapp: whatsapp ?? this.whatsapp,
        contactEmail: contactEmail ?? this.contactEmail,
        address: address ?? this.address,
        instagramHandle: instagramHandle ?? this.instagramHandle,
        blockedDates: blockedDates ?? this.blockedDates,
        rating: rating ?? this.rating,
        feedbackCount: feedbackCount ?? this.feedbackCount,
        compositeScore: compositeScore ?? this.compositeScore,
        respondsInMinutes: respondsInMinutes ?? this.respondsInMinutes,
        weddingsCompleted: weddingsCompleted ?? this.weddingsCompleted,
        onTimeRate: onTimeRate ?? this.onTimeRate,
        recommendRate: recommendRate ?? this.recommendRate,
        services: services ?? this.services,
        media: media ?? this.media,
        packages: packages ?? this.packages,
        isCustomEntry: isCustomEntry ?? this.isCustomEntry,
      );

  bool get isVerified => verificationStatus == VerificationStatus.verified;

  /// Derived from [tier]: premium → high, pro → mid, free → low.
  VendorPriceTier get priceTier => switch (tier) {
    VendorTier.premium => VendorPriceTier.high,
    VendorTier.pro => VendorPriceTier.mid,
    VendorTier.free => VendorPriceTier.low,
  };

  /// Composite 0–1 score combining rating, composite score, and feedback volume.
  double get performanceScore {
    final ratingNorm = (rating ?? 0) / 5.0;
    final compositeNorm = (compositeScore / 100.0).clamp(0.0, 1.0);
    final feedbackNorm = (feedbackCount / 200.0).clamp(0.0, 1.0);
    return ratingNorm * 0.5 + compositeNorm * 0.35 + feedbackNorm * 0.15;
  }

  double get priceMin {
    if (services.isEmpty) return 0;
    return services.map((s) => s.priceMin).reduce((a, b) => a < b ? a : b);
  }

  double get priceMax {
    if (services.isEmpty) return 0;
    return services.map((s) => s.priceMax).reduce((a, b) => a > b ? a : b);
  }

  /// The price a couple should realistically budget for this vendor under a
  /// given wedding class — must always match whatever package price the
  /// couple is actually shown for that class (see couple_planning_screen.dart's
  /// `_PlanVendorCard`/`wantedTier` selection, mirrored here) or the budget
  /// ledger silently tracks a different number than the one on screen. High
  /// Class books the registered luxury package price when one is set,
  /// Flexible the registered starter package price, both falling back to the
  /// vendor's price range (top for High Class, minimum otherwise) when no
  /// matching package is registered. Budget-Friendly never has a package by
  /// design, so it always budgets from the vendor's minimum price.
  double priceForClass(BudgetClass bc) {
    final wantedTier = switch (bc) {
      BudgetClass.highClass => VendorPackageTier.luxury,
      BudgetClass.flexible => VendorPackageTier.starter,
      BudgetClass.budgetFriendly => null,
    };
    if (wantedTier != null) {
      for (final p in packages) {
        if (p.tier == wantedTier && p.inclusions.isNotEmpty && (p.price ?? 0) > 0) {
          return p.price!;
        }
      }
    }
    if (bc == BudgetClass.highClass) return priceMax > 0 ? priceMax : priceMin;
    return priceMin;
  }

  /// Whether this vendor has a registered service that can seat [guestCount].
  /// A vendor with no services yet, or whose services never stated a
  /// capacity (only possible for legacy pre-migration rows — see
  /// [VendorService.maxGuests]), is never excluded by this: unknown capacity
  /// is treated as neutral, the same way an unpriced vendor is neither
  /// "cheap" nor "expensive" elsewhere in matching (see _valueScore).
  bool canServeGuestCount(int guestCount) =>
      services.isEmpty ||
      services.any((s) => s.maxGuests == null || s.maxGuests! >= guestCount);

  /// The largest stated guest capacity across this vendor's listings, for
  /// display only (e.g. "Can serve up to: N guests"). Null when the vendor
  /// has no services yet, or none of them have stated a capacity.
  int? get maxGuestCapacity {
    final stated = services.map((s) => s.maxGuests).whereType<int>();
    return stated.isEmpty ? null : stated.reduce((a, b) => a > b ? a : b);
  }

  factory VendorProfile.fromJson(Map<String, dynamic> json) => VendorProfile(
        id: requireString(json, 'vendor_id'),
        userId: requireString(json, 'user_id'),
        businessName: requireString(json, 'business_name'),
        description: json['description'] as String?,
        category: requireString(json, 'category'),
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
        whatsapp: json['whatsapp'] as String?,
        contactEmail: json['contact_email'] as String?,
        address: json['address'] as String?,
        instagramHandle: json['instagram_handle'] as String?,
        blockedDates: List<String>.from(json['blocked_dates'] ?? []),
        rating: (json['rating'] as num?)?.toDouble(),
        feedbackCount: json['feedback_count'] as int? ?? 0,
        compositeScore: (json['composite_score'] as num?)?.toDouble() ?? 0,
        respondsInMinutes: (json['responds_in_minutes'] as num?)?.toDouble(),
        weddingsCompleted: json['weddings_completed'] as int? ?? 0,
        onTimeRate: (json['on_time_rate'] as num?)?.toDouble(),
        recommendRate: (json['recommend_rate'] as num?)?.toDouble(),
        services: (json['services'] as List<dynamic>? ?? [])
            .map((s) => VendorService.fromJson(s as Map<String, dynamic>))
            .toList(),
        media: (json['media'] as List<dynamic>? ?? [])
            .map((m) => VendorMedia.fromJson(m as Map<String, dynamic>))
            .toList(),
        packages: (json['packages'] as List<dynamic>? ?? [])
            .map((p) => VendorPackage.fromJson(p as Map<String, dynamic>))
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
        'whatsapp': whatsapp,
        'contact_email': contactEmail,
        'address': address,
        'instagram_handle': instagramHandle,
        'blocked_dates': blockedDates,
        'rating': rating,
        'feedback_count': feedbackCount,
        'composite_score': compositeScore,
        'responds_in_minutes': respondsInMinutes,
        'weddings_completed': weddingsCompleted,
        'on_time_rate': onTimeRate,
        'recommend_rate': recommendRate,
        'services': services.map((s) => s.toJson()).toList(),
        'media': media.map((m) => m.toJson()).toList(),
        'packages': packages.map((p) => p.toJson()).toList(),
        'is_custom_entry': isCustomEntry,
      };
}

/// Which wedding-class experience a registered package is pitched at.
/// Luxury packages count toward High Class qualification; starter packages
/// toward Flexible (see `VendorClassService`).
enum VendorPackageTier { luxury, starter }

/// A bundled offering the vendor registers themselves — what a couple gets
/// on top of the base service when matched through a wedding class. Distinct
/// from [VendorService] (the priced listing): a package describes the
/// experience inclusions, not the base price.
class VendorPackage {
  final String id;
  final VendorPackageTier tier;
  final String title;
  final List<String> inclusions;
  final double? price;

  const VendorPackage({
    required this.id,
    required this.tier,
    required this.title,
    required this.inclusions,
    this.price,
  });

  VendorPackage copyWith({
    VendorPackageTier? tier,
    String? title,
    List<String>? inclusions,
    double? price,
  }) =>
      VendorPackage(
        id: id,
        tier: tier ?? this.tier,
        title: title ?? this.title,
        inclusions: inclusions ?? this.inclusions,
        price: price ?? this.price,
      );

  factory VendorPackage.fromJson(Map<String, dynamic> json) => VendorPackage(
        id: json['package_id'] as String? ?? '',
        tier: enumByName(VendorPackageTier.values, json['tier'] as String?,
            VendorPackageTier.starter),
        title: json['title'] as String? ?? '',
        inclusions: List<String>.from(json['inclusions'] ?? []),
        price: (json['price'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'package_id': id,
        'tier': tier.name,
        'title': title,
        'inclusions': inclusions,
        'price': price,
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

  /// Maximum guests this package can serve — mandatory on every listing
  /// across every category (see _ServiceFormSheet). Nullable purely to model
  /// legacy rows created before this field was required (see
  /// backend/scripts/backfillGuestCapacity.js); matching treats a null here
  /// as neutral, not a rejection, so an un-migrated row is never wrongly
  /// excluded.
  final int? maxGuests;

  const VendorService({
    required this.id,
    required this.vendorId,
    required this.title,
    this.description,
    required this.priceMin,
    required this.priceMax,
    required this.unit,
    this.isActive = true,
    this.maxGuests,
  });

  VendorService copyWith({
    String? title,
    String? description,
    double? priceMin,
    double? priceMax,
    String? unit,
    bool? isActive,
    int? maxGuests,
  }) => VendorService(
        id: id,
        vendorId: vendorId,
        title: title ?? this.title,
        description: description ?? this.description,
        priceMin: priceMin ?? this.priceMin,
        priceMax: priceMax ?? this.priceMax,
        unit: unit ?? this.unit,
        isActive: isActive ?? this.isActive,
        maxGuests: maxGuests ?? this.maxGuests,
      );

  factory VendorService.fromJson(Map<String, dynamic> json) => VendorService(
        id: requireString(json, 'service_id'),
        vendorId: requireString(json, 'vendor_id'),
        title: requireString(json, 'title'),
        description: json['description'] as String?,
        priceMin: requireNum(json, 'price_min').toDouble(),
        priceMax: requireNum(json, 'price_max').toDouble(),
        unit: json['unit'] as String? ?? 'package',
        isActive: json['is_active'] as bool? ?? true,
        maxGuests: (json['max_guests'] as num?)?.toInt(),
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
        'max_guests': maxGuests,
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
        id: requireString(json, 'media_id'),
        vendorId: requireString(json, 'vendor_id'),
        type: requireString(json, 'type'),
        url: requireString(json, 'url'),
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

/// One named slot of the AI's justification for a vendor pick — mirrors how
/// Claude Code labels each step of its work instead of a single run-on
/// explanation. [label] is always one of [ReasoningStep.knownLabels].
class ReasoningStep {
  final String label;
  final String text;

  const ReasoningStep({required this.label, required this.text});

  static const budgetFit = 'Budget fit';
  static const reputation = 'Reputation';
  static const availability = 'Availability';
  static const styleMatch = 'Style match';
  static const verdict = 'Verdict';
  static const knownLabels = [budgetFit, reputation, availability, styleMatch, verdict];

  factory ReasoningStep.fromJson(Map<String, dynamic> json) => ReasoningStep(
        label: json['label'] as String? ?? '',
        text: json['text'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'label': label, 'text': text};
}

/// Why a vendor was picked for its category: matched the couple's stated
/// budget exactly, was the best available fit for their wedding class once
/// nothing in the category fit their allocated budget, or was the sole
/// vendor left once every other option in the category was priced out of
/// range (see [VendorMatch.isBudgetUnrealistic]).
enum SelectionBasis { exactBudgetMatch, weddingClassBestFit, onlyAffordableOption }

class VendorMatch {
  final String vendorId;
  final VendorProfile vendor;
  final double finalScore;
  final double reputationScore;
  final double budgetScore;
  final double locationScore;
  final double availabilityScore;
  final String? reasoning;
  final List<ReasoningStep> reasoningSteps;
  final int rankInCategory;
  final int totalInCategory;
  final bool fitsBudget;
  final double? budgetDeltaPercent;
  final SelectionBasis selectionBasis;
  final String? noteToCouple;

  /// True when literally no vendor in this category is priced at or under
  /// the couple's allocated budget — i.e. the amount they entered isn't
  /// just tight, it can't fit any real option. The pick shown is still the
  /// closest available vendor, but the couple should be told the budget
  /// itself needs raising, not just that this one pick is "over".
  final bool isBudgetUnrealistic;

  const VendorMatch({
    required this.vendorId,
    required this.vendor,
    required this.finalScore,
    required this.reputationScore,
    required this.budgetScore,
    required this.locationScore,
    required this.availabilityScore,
    this.reasoning,
    this.reasoningSteps = const [],
    required this.rankInCategory,
    required this.totalInCategory,
    this.fitsBudget = true,
    this.budgetDeltaPercent,
    this.selectionBasis = SelectionBasis.exactBudgetMatch,
    this.noteToCouple,
    this.isBudgetUnrealistic = false,
  });

  VendorMatch copyWith({
    int? rankInCategory,
    bool? fitsBudget,
    double? budgetDeltaPercent,
    SelectionBasis? selectionBasis,
    String? noteToCouple,
    bool? isBudgetUnrealistic,
    List<ReasoningStep>? reasoningSteps,
  }) =>
      VendorMatch(
        vendorId: vendorId,
        vendor: vendor,
        finalScore: finalScore,
        reputationScore: reputationScore,
        budgetScore: budgetScore,
        locationScore: locationScore,
        availabilityScore: availabilityScore,
        reasoning: reasoning,
        reasoningSteps: reasoningSteps ?? this.reasoningSteps,
        rankInCategory: rankInCategory ?? this.rankInCategory,
        totalInCategory: totalInCategory,
        fitsBudget: fitsBudget ?? this.fitsBudget,
        budgetDeltaPercent: budgetDeltaPercent ?? this.budgetDeltaPercent,
        selectionBasis: selectionBasis ?? this.selectionBasis,
        noteToCouple: noteToCouple ?? this.noteToCouple,
        isBudgetUnrealistic: isBudgetUnrealistic ?? this.isBudgetUnrealistic,
      );
}
