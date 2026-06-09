enum InvitationStatus { draft, published, archived }
enum AttendingStatus { yes, no, maybe }
enum SendChannel { whatsapp, email, sms, link }

class InvitationTemplate {
  final String id;
  final String name;
  final String theme;
  final String previewUrl;
  final bool isPremium;
  final bool isActive;

  const InvitationTemplate({
    required this.id,
    required this.name,
    required this.theme,
    required this.previewUrl,
    required this.isPremium,
    required this.isActive,
  });

  factory InvitationTemplate.fromJson(Map<String, dynamic> json) =>
      InvitationTemplate(
        id: json['template_id'] as String,
        name: json['name'] as String,
        theme: json['theme'] as String,
        previewUrl: json['preview_url'] as String,
        isPremium: json['is_premium'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? true,
      );
}

class Invitation {
  final String id;
  final String coupleId;
  final String templateId;
  final String title;
  final Map<String, dynamic> customData;
  final String shareToken;
  final String? shareUrl;
  final String? thumbnailUrl;
  final InvitationStatus status;
  final int viewCount;
  final DateTime createdAt;

  const Invitation({
    required this.id,
    required this.coupleId,
    required this.templateId,
    required this.title,
    required this.customData,
    required this.shareToken,
    this.shareUrl,
    this.thumbnailUrl,
    required this.status,
    this.viewCount = 0,
    required this.createdAt,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) => Invitation(
        id: json['invitation_id'] as String,
        coupleId: json['couple_id'] as String,
        templateId: json['template_id'] as String,
        title: json['title'] as String,
        customData: json['custom_data'] as Map<String, dynamic>? ?? {},
        shareToken: json['share_token'] as String,
        shareUrl: json['share_url'] as String?,
        thumbnailUrl: json['thumbnail_url'] as String?,
        status: InvitationStatus.values.byName(
            json['status'] as String? ?? 'draft'),
        viewCount: json['view_count'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class RsvpResponse {
  final String id;
  final String invitationId;
  final String? guestId;
  final String guestName;
  final AttendingStatus attending;
  final int guestCount;
  final String? mealPreference;
  final String? dietaryNotes;
  final String? message;
  final DateTime respondedAt;

  const RsvpResponse({
    required this.id,
    required this.invitationId,
    this.guestId,
    required this.guestName,
    required this.attending,
    this.guestCount = 1,
    this.mealPreference,
    this.dietaryNotes,
    this.message,
    required this.respondedAt,
  });

  factory RsvpResponse.fromJson(Map<String, dynamic> json) => RsvpResponse(
        id: json['rsvp_id'] as String,
        invitationId: json['invitation_id'] as String,
        guestId: json['guest_id'] as String?,
        guestName: json['guest_name'] as String,
        attending: AttendingStatus.values.byName(json['attending'] as String),
        guestCount: json['guest_count'] as int? ?? 1,
        mealPreference: json['meal_preference'] as String?,
        dietaryNotes: json['dietary_notes'] as String?,
        message: json['message'] as String?,
        respondedAt: DateTime.parse(json['responded_at'] as String),
      );
}

class Guest {
  final String id;
  final String coupleId;
  final String name;
  final String? phone;
  final String? email;
  final String? whatsappNumber;
  final String? relation;
  final bool isInvited;

  const Guest({
    required this.id,
    required this.coupleId,
    required this.name,
    this.phone,
    this.email,
    this.whatsappNumber,
    this.relation,
    this.isInvited = false,
  });

  factory Guest.fromJson(Map<String, dynamic> json) => Guest(
        id: json['guest_id'] as String,
        coupleId: json['couple_id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        whatsappNumber: json['whatsapp_number'] as String?,
        relation: json['relation'] as String?,
        isInvited: json['is_invited'] as bool? ?? false,
      );
}
