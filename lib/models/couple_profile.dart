class CoupleProfile {
  final String id;
  final String userId;
  final String? partnerUserId;
  final DateTime? weddingDate;
  final String? location;
  final int? guestCount;
  final List<String> styleTags;
  final double? totalBudget;
  final String currency;
  final String? partnerName;
  final String? photoUrl;

  const CoupleProfile({
    required this.id,
    required this.userId,
    this.partnerUserId,
    this.weddingDate,
    this.location,
    this.guestCount,
    this.styleTags = const [],
    this.totalBudget,
    this.currency = 'USD',
    this.partnerName,
    this.photoUrl,
  });

  int get daysUntilWedding {
    if (weddingDate == null) return 0;
    return weddingDate!.difference(DateTime.now()).inDays;
  }

  bool get hasWeddingDate => weddingDate != null;
  bool get hasBudget => totalBudget != null && totalBudget! > 0;

  factory CoupleProfile.fromJson(Map<String, dynamic> json) => CoupleProfile(
        id: json['profile_id'] as String,
        userId: json['user_id'] as String,
        partnerUserId: json['partner_user_id'] as String?,
        weddingDate: json['wedding_date'] != null
            ? DateTime.parse(json['wedding_date'] as String)
            : null,
        location: json['location'] as String?,
        guestCount: json['guest_count'] as int?,
        styleTags: List<String>.from(json['style_tags'] ?? []),
        totalBudget: (json['total_budget'] as num?)?.toDouble(),
        currency: json['currency'] as String? ?? 'USD',
        partnerName: json['partner_name'] as String?,
        photoUrl: json['photo_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'profile_id': id,
        'user_id': userId,
        'partner_user_id': partnerUserId,
        'wedding_date': weddingDate?.toIso8601String(),
        'location': location,
        'guest_count': guestCount,
        'style_tags': styleTags,
        'total_budget': totalBudget,
        'currency': currency,
        'partner_name': partnerName,
        'photo_url': photoUrl,
      };
}
