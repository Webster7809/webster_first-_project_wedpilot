/// Whether the vendor arrived on time — captured on the private feedback
/// form since nothing else in the data model tracks vendor punctuality.
enum OnTimeAnswer { yes, no, notApplicable }

String onTimeToWire(OnTimeAnswer value) => switch (value) {
      OnTimeAnswer.yes => 'yes',
      OnTimeAnswer.no => 'no',
      OnTimeAnswer.notApplicable => 'not_applicable',
    };

OnTimeAnswer? onTimeFromWire(String? value) => switch (value) {
      'yes' => OnTimeAnswer.yes,
      'no' => OnTimeAnswer.no,
      'not_applicable' => OnTimeAnswer.notApplicable,
      _ => null,
    };

/// A couple's private post-booking feedback for a vendor. Never shown to
/// other couples — only the vendor who owns it and admins can read it
/// (enforced server-side). Only the aggregate CRS/badges derived from this
/// are ever public; see [VendorProfile]'s badge fields.
class VendorFeedback {
  final String id;
  final String coupleId;
  final String vendorId;
  final String inquiryId;
  final String? coupleName;
  final int starRating;
  final String? comment;
  final OnTimeAnswer? onTime;
  final bool isFlagged;
  final String? flagReason;
  final DateTime createdAt;

  const VendorFeedback({
    required this.id,
    required this.coupleId,
    required this.vendorId,
    required this.inquiryId,
    this.coupleName,
    required this.starRating,
    this.comment,
    this.onTime,
    this.isFlagged = false,
    this.flagReason,
    required this.createdAt,
  });

  factory VendorFeedback.fromJson(Map<String, dynamic> json) => VendorFeedback(
        id: json['feedback_id'] as String,
        coupleId: json['couple_id'] as String,
        vendorId: json['vendor_id'] as String,
        inquiryId: json['inquiry_id'] as String,
        coupleName: json['couple_name'] as String?,
        starRating: json['star_rating'] as int,
        comment: json['comment'] as String?,
        onTime: onTimeFromWire(json['on_time'] as String?),
        isFlagged: json['is_flagged'] as bool? ?? false,
        flagReason: json['flag_reason'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'feedback_id': id,
        'couple_id': coupleId,
        'vendor_id': vendorId,
        'inquiry_id': inquiryId,
        'couple_name': coupleName,
        'star_rating': starRating,
        'comment': comment,
        'on_time': onTime == null ? null : onTimeToWire(onTime!),
        'is_flagged': isFlagged,
        'flag_reason': flagReason,
        'created_at': createdAt.toIso8601String(),
      };
}
