import '../core/utils/enum_utils.dart';

enum InvitationStatus { draft, published, archived }
enum AttendingStatus { yes, no, maybe }

/// Mirrors the backend's plain-string `type` on `rsvp_questions` — kept as a
/// string set there (not a DB enum) because it's expected to grow; the enum
/// here just gives the Flutter side exhaustive-switch safety today.
enum RsvpQuestionType { yesNo, singleChoice, multiChoice, shortText, longText, number }

RsvpQuestionType _questionTypeFromWire(String? value) => switch (value) {
      'yes_no' => RsvpQuestionType.yesNo,
      'single_choice' => RsvpQuestionType.singleChoice,
      'multi_choice' => RsvpQuestionType.multiChoice,
      'short_text' => RsvpQuestionType.shortText,
      'long_text' => RsvpQuestionType.longText,
      'number' => RsvpQuestionType.number,
      _ => RsvpQuestionType.shortText,
    };

String questionTypeToWire(RsvpQuestionType type) => switch (type) {
      RsvpQuestionType.yesNo => 'yes_no',
      RsvpQuestionType.singleChoice => 'single_choice',
      RsvpQuestionType.multiChoice => 'multi_choice',
      RsvpQuestionType.shortText => 'short_text',
      RsvpQuestionType.longText => 'long_text',
      RsvpQuestionType.number => 'number',
    };

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

  Map<String, dynamic> toJson() => {
        'template_id': id,
        'name': name,
        'theme': theme,
        'preview_url': previewUrl,
        'is_premium': isPremium,
        'is_active': isActive,
      };
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
        status: enumByName(InvitationStatus.values, json['status'] as String?, InvitationStatus.draft),
        viewCount: json['view_count'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'invitation_id': id,
        'couple_id': coupleId,
        'template_id': templateId,
        'title': title,
        'custom_data': customData,
        'share_token': shareToken,
        'share_url': shareUrl,
        'thumbnail_url': thumbnailUrl,
        'status': status.name,
        'view_count': viewCount,
        'created_at': createdAt.toIso8601String(),
      };
}

/// Wraps a broadcast-link (/i/:shareToken) fetch — the invitation plus its
/// couple-configured meal choices, mirroring what the personal-link fetch
/// (GuestInvitation) already carries.
class PublicInvitationView {
  final Invitation invitation;
  final List<MealOption> mealOptions;
  final List<RsvpQuestion> rsvpQuestions;

  /// The couple's optional total headcount cap for this card (from
  /// custom_data.maxGuests server-side) — null means uncapped.
  final int? maxGuests;

  /// Combined guest_count of every non-declined RSVP on this invitation so
  /// far (personal links and this shared link together). Only populated by
  /// the server when [maxGuests] is set — a null here with a non-null
  /// [maxGuests] shouldn't happen, but is treated as "unknown, not full".
  final int? confirmedGuestCount;

  const PublicInvitationView({
    required this.invitation,
    this.mealOptions = const [],
    this.rsvpQuestions = const [],
    this.maxGuests,
    this.confirmedGuestCount,
  });

  /// Whether the shared link should stop accepting new RSVPs. Personal
  /// (/g/:inviteToken) links are unaffected by this — see
  /// GuestInvitation, which carries no such flag.
  bool get isFull =>
      maxGuests != null && confirmedGuestCount != null && confirmedGuestCount! >= maxGuests!;

  factory PublicInvitationView.fromJson(Map<String, dynamic> json) {
    final options = (json['meal_options'] as List?) ?? const [];
    final questions = (json['rsvp_questions'] as List?) ?? const [];
    return PublicInvitationView(
      invitation: Invitation.fromJson(json['invitation'] as Map<String, dynamic>),
      mealOptions: options.map((o) => MealOption.fromJson(o as Map<String, dynamic>)).toList(),
      rsvpQuestions: questions.map((q) => RsvpQuestion.fromJson(q as Map<String, dynamic>)).toList(),
      maxGuests: json['max_guests'] as int?,
      confirmedGuestCount: json['confirmed_guest_count'] as int?,
    );
  }
}

class RsvpResponse {
  final String id;
  final String? invitationId;
  final String? guestId;
  final String guestName;
  final AttendingStatus attending;
  final int guestCount;
  final String? mealPreference;
  final String? dietaryNotes;
  final String? message;
  final DateTime respondedAt;
  final List<RsvpAnswer> answers;

  const RsvpResponse({
    required this.id,
    this.invitationId,
    this.guestId,
    required this.guestName,
    required this.attending,
    this.guestCount = 1,
    this.mealPreference,
    this.dietaryNotes,
    this.message,
    required this.respondedAt,
    this.answers = const [],
  });

  factory RsvpResponse.fromJson(Map<String, dynamic> json) {
    final answers = (json['answers'] as List?) ?? const [];
    return RsvpResponse(
      id: json['rsvp_id'] as String,
      invitationId: json['invitation_id'] as String?,
      guestId: json['guest_id'] as String?,
      guestName: json['guest_name'] as String,
      attending: enumByName(AttendingStatus.values, json['attending'] as String?, AttendingStatus.maybe),
      guestCount: json['guest_count'] as int? ?? 1,
      mealPreference: json['meal_preference'] as String?,
      dietaryNotes: json['dietary_notes'] as String?,
      message: json['message'] as String?,
      respondedAt: DateTime.parse(json['responded_at'] as String),
      answers: answers.map((a) => RsvpAnswer.fromJson(a as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'rsvp_id': id,
        'invitation_id': invitationId,
        'guest_id': guestId,
        'guest_name': guestName,
        'attending': attending.name,
        'guest_count': guestCount,
        'meal_preference': mealPreference,
        'dietary_notes': dietaryNotes,
        'message': message,
        'responded_at': respondedAt.toIso8601String(),
      };
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
  final String? inviteToken;
  final String? inviteUrl;

  /// Short code printed/written on this guest's physical invitation —
  /// checked against the system at the door, since a forwarded link alone
  /// can't confirm who's actually holding it. Assigned by the server on
  /// creation, so it's only ever null for data from before this existed.
  final String? cardNumber;

  /// Upper bound on how many people this one invitation covers (a family/
  /// group RSVP) — null means uncapped. Enforced server-side on every RSVP
  /// submission; see backend/routes/guests.js and invitations.js.
  final int? maxPartySize;
  final bool checkedIn;
  final DateTime? checkedInAt;

  const Guest({
    required this.id,
    required this.coupleId,
    required this.name,
    this.phone,
    this.email,
    this.whatsappNumber,
    this.relation,
    this.isInvited = false,
    this.inviteToken,
    this.inviteUrl,
    this.cardNumber,
    this.maxPartySize,
    this.checkedIn = false,
    this.checkedInAt,
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
        inviteToken: json['invite_token'] as String?,
        inviteUrl: json['invite_url'] as String?,
        cardNumber: json['card_number'] as String?,
        maxPartySize: json['max_party_size'] as int?,
        checkedIn: json['checked_in'] as bool? ?? false,
        checkedInAt: json['checked_in_at'] != null
            ? DateTime.parse(json['checked_in_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'guest_id': id,
        'couple_id': coupleId,
        'name': name,
        'phone': phone,
        'email': email,
        'whatsapp_number': whatsappNumber,
        'relation': relation,
        'is_invited': isInvited,
        'invite_token': inviteToken,
        'invite_url': inviteUrl,
        'card_number': cardNumber,
        'max_party_size': maxPartySize,
        'checked_in': checkedIn,
        'checked_in_at': checkedInAt?.toIso8601String(),
      };
}

class GuestInvitation {
  final Invitation invitation;
  final String guestName;

  /// Upper bound on how many people this guest's invitation covers — null
  /// means uncapped. Bounds the guest-count stepper on the public RSVP form.
  final int? maxPartySize;
  final bool alreadyResponded;
  final AttendingStatus? respondedAttending;
  final int? respondedGuestCount;
  final String? respondedMealPreference;
  final String? respondedDietaryNotes;
  final String? respondedMessage;
  final List<MealOption> mealOptions;
  final List<RsvpQuestion> rsvpQuestions;
  final List<RsvpAnswer> respondedAnswers;

  const GuestInvitation({
    required this.invitation,
    required this.guestName,
    this.maxPartySize,
    required this.alreadyResponded,
    this.respondedAttending,
    this.respondedGuestCount,
    this.respondedMealPreference,
    this.respondedDietaryNotes,
    this.respondedMessage,
    this.mealOptions = const [],
    this.rsvpQuestions = const [],
    this.respondedAnswers = const [],
  });

  factory GuestInvitation.fromJson(Map<String, dynamic> json) {
    final existing = json['existing_response'] as Map<String, dynamic>?;
    final guest = json['guest'] as Map<String, dynamic>;
    final options = (json['meal_options'] as List?) ?? const [];
    final questions = (json['rsvp_questions'] as List?) ?? const [];
    final existingAnswers = (existing?['answers'] as List?) ?? const [];
    return GuestInvitation(
      invitation: Invitation.fromJson(json['invitation'] as Map<String, dynamic>),
      guestName: guest['name'] as String,
      maxPartySize: guest['max_party_size'] as int?,
      alreadyResponded: json['already_responded'] as bool? ?? false,
      respondedAttending: existing != null
          ? enumByName(AttendingStatus.values, existing['attending'] as String?, AttendingStatus.maybe)
          : null,
      respondedGuestCount: existing?['guest_count'] as int?,
      respondedMealPreference: existing?['meal_preference'] as String?,
      respondedDietaryNotes: existing?['dietary_notes'] as String?,
      respondedMessage: existing?['message'] as String?,
      mealOptions: options.map((o) => MealOption.fromJson(o as Map<String, dynamic>)).toList(),
      rsvpQuestions: questions.map((q) => RsvpQuestion.fromJson(q as Map<String, dynamic>)).toList(),
      respondedAnswers: existingAnswers.map((a) => RsvpAnswer.fromJson(a as Map<String, dynamic>)).toList(),
    );
  }
}

/// A couple-configurable meal choice shown on the public RSVP form. No
/// relation to RsvpResponse.mealPreference (free text) beyond supplying the
/// choices — see backend/routes/invitations.js.
class MealOption {
  final String id;
  final String invitationId;
  final String label;
  final int sortOrder;

  const MealOption({
    required this.id,
    required this.invitationId,
    required this.label,
    this.sortOrder = 0,
  });

  factory MealOption.fromJson(Map<String, dynamic> json) => MealOption(
        id: json['option_id'] as String,
        invitationId: json['invitation_id'] as String,
        label: json['label'] as String,
        sortOrder: json['sort_order'] as int? ?? 0,
      );
}

/// One couple-initiated edit to an RSVP (manual guest-list entry or a status
/// correction) — never a guest's own self-edit through their link. See
/// backend/routes/guests.js and migrations/016_rsvp_history.js.
class RsvpHistoryEntry {
  final String id;
  final AttendingStatus? previousStatus;
  final AttendingStatus newStatus;
  final int? previousGuestCount;
  final int newGuestCount;
  final DateTime changedAt;

  const RsvpHistoryEntry({
    required this.id,
    this.previousStatus,
    required this.newStatus,
    this.previousGuestCount,
    required this.newGuestCount,
    required this.changedAt,
  });

  factory RsvpHistoryEntry.fromJson(Map<String, dynamic> json) => RsvpHistoryEntry(
        id: json['history_id'] as String,
        previousStatus: json['previous_status'] != null
            ? enumByName(AttendingStatus.values, json['previous_status'] as String?, AttendingStatus.maybe)
            : null,
        newStatus: enumByName(AttendingStatus.values, json['new_status'] as String?, AttendingStatus.maybe),
        previousGuestCount: json['previous_guest_count'] as int?,
        newGuestCount: json['new_guest_count'] as int? ?? 0,
        changedAt: DateTime.parse(json['changed_at'] as String),
      );
}

/// A couple-configurable custom RSVP question, scoped to one invitation —
/// see backend/routes/invitations.js and migrations/015_rsvp_questions.js.
class RsvpQuestion {
  final String id;
  final String invitationId;
  final String questionText;
  final RsvpQuestionType type;

  /// Choice labels for [RsvpQuestionType.singleChoice]/[multiChoice]; empty
  /// for every other type.
  final List<String> options;
  final bool isRequired;
  final bool isEnabled;
  final int sortOrder;

  const RsvpQuestion({
    required this.id,
    required this.invitationId,
    required this.questionText,
    required this.type,
    this.options = const [],
    this.isRequired = false,
    this.isEnabled = true,
    this.sortOrder = 0,
  });

  factory RsvpQuestion.fromJson(Map<String, dynamic> json) {
    final options = (json['options'] as List?) ?? const [];
    return RsvpQuestion(
      id: json['question_id'] as String,
      invitationId: json['invitation_id'] as String,
      questionText: json['question_text'] as String,
      type: _questionTypeFromWire(json['type'] as String?),
      options: options.map((o) => o as String).toList(),
      isRequired: json['is_required'] as bool? ?? false,
      isEnabled: json['is_enabled'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}

/// One answer the guest-facing form is about to submit alongside an RSVP —
/// the write-side counterpart of [RsvpAnswer], which is what comes back.
class RsvpAnswerInput {
  final String questionId;
  final String? answerText;
  final List<String>? answerJson;

  const RsvpAnswerInput({required this.questionId, this.answerText, this.answerJson});

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'answerText': answerText,
        'answerJson': answerJson,
      };
}

/// One guest's answer to one [RsvpQuestion]. [answerText] covers every type
/// except [RsvpQuestionType.multiChoice], which uses [answerJson] (the
/// selected option labels) instead.
class RsvpAnswer {
  final String questionId;
  final String? questionText;
  final RsvpQuestionType? type;
  final String? answerText;
  final List<String> answerJson;

  const RsvpAnswer({
    required this.questionId,
    this.questionText,
    this.type,
    this.answerText,
    this.answerJson = const [],
  });

  factory RsvpAnswer.fromJson(Map<String, dynamic> json) {
    final selected = (json['answer_json'] as List?) ?? const [];
    return RsvpAnswer(
      questionId: json['question_id'] as String,
      questionText: json['question_text'] as String?,
      type: json['type'] != null ? _questionTypeFromWire(json['type'] as String?) : null,
      answerText: json['answer_text'] as String?,
      answerJson: selected.map((o) => o as String).toList(),
    );
  }
}
