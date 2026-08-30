import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../../models/invitation.dart';
import 'api_error.dart';
import 'authenticated_dio.dart';

/// Resolves a stored relative upload path (e.g. '/uploads/invitations/x.jpg')
/// to an absolute URL. Already-absolute URLs are returned unchanged.
String resolveInvitationMediaUrl(String urlOrPath) =>
    urlOrPath.startsWith('http') ? urlOrPath : '${ApiConfig.baseUrl}$urlOrPath';

class InvitationApiException implements Exception {
  final String message;
  const InvitationApiException(this.message);
}

class InvitationApiService {
  InvitationApiService._();
  static final InvitationApiService instance = InvitationApiService._();

  final Dio _dio = buildApiDio();

  Options _auth(String accessToken) =>
      Options(headers: {'Authorization': 'Bearer $accessToken'});

  // ── Guests ───────────────────────────────────────────────────────────────────

  Future<List<Guest>> fetchGuests(String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/guests', options: _auth(accessToken));
      final list = (response.data?['guests'] as List?) ?? [];
      return list.map((g) => Guest.fromJson(g as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  /// Returns the validation/server error message, or null on success.
  Future<String?> addGuest(
    String accessToken, {
    required String name,
    String? email,
    String? phone,
    String? relation,
    String? invitationId,
    int? maxPartySize,
  }) async {
    try {
      await _dio.post(
        '/api/guests',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'relation': relation,
          'invitationId': invitationId,
          'maxPartySize': maxPartySize,
        },
        options: _auth(accessToken),
      );
      return null;
    } on DioException catch (e) {
      return _extractError(e);
    }
  }

  Future<String?> editGuest(
    String accessToken, {
    required String id,
    required String name,
    String? email,
    String? phone,
    String? relation,
    int? maxPartySize,
  }) async {
    try {
      await _dio.patch(
        '/api/guests/$id',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'relation': relation,
          'maxPartySize': maxPartySize,
        },
        options: _auth(accessToken),
      );
      return null;
    } on DioException catch (e) {
      return _extractError(e);
    }
  }

  Future<void> deleteGuest(String accessToken, String id) async {
    try {
      await _dio.delete('/api/guests/$id', options: _auth(accessToken));
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  Future<void> toggleGuestInvited(String accessToken, String id) async {
    try {
      await _dio.patch('/api/guests/$id/toggle-invited', options: _auth(accessToken));
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  /// Gets (lazily generating server-side) this guest's personal, single-use
  /// invite link for [invitationId].
  Future<Guest> fetchOrCreateGuestInviteLink(
    String accessToken, {
    required String guestId,
    required String invitationId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/guests/$guestId/invite-link',
        data: {'invitationId': invitationId},
        options: _auth(accessToken),
      );
      return Guest.fromJson(response.data?['guest'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  // ── Door check-in ────────────────────────────────────────────────────────────

  /// Verifies [cardNumber] against this couple's own guest list and marks
  /// that guest checked in. Throws [InvitationApiException] with the
  /// server's message on failure — no match (404), or already checked in
  /// (409, whose message already names the guest and time).
  Future<Guest> checkInGuestByCardNumber(String accessToken, String cardNumber) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/guests/checkin',
        data: {'cardNumber': cardNumber},
        options: _auth(accessToken),
      );
      return Guest.fromJson(response.data?['guest'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  Future<Guest> toggleGuestCheckin(String accessToken, String id) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/guests/$id/toggle-checkin',
        options: _auth(accessToken),
      );
      return Guest.fromJson(response.data?['guest'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  // ── RSVP responses (couple-side) ──────────────────────────────────────────────

  Future<List<RsvpResponse>> fetchRsvpResponses(String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/guests/responses', options: _auth(accessToken));
      final list = (response.data?['responses'] as List?) ?? [];
      return list.map((r) => RsvpResponse.fromJson(r as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  /// Returns the validation/server error message, or null on success. The
  /// guest's name isn't sent — the server already knows it via [guestId]
  /// and is the single source of truth for it.
  Future<String?> submitGuestRsvp(
    String accessToken, {
    required String guestId,
    required AttendingStatus attending,
    required int guestCount,
    String? mealPreference,
    String? dietaryNotes,
    String? message,
    String? invitationId,
  }) async {
    try {
      await _dio.post(
        '/api/guests/$guestId/rsvp',
        data: {
          'attending': attending.name,
          'guestCount': guestCount,
          'mealPreference': mealPreference,
          'dietaryNotes': dietaryNotes,
          'message': message,
          'invitationId': invitationId,
        },
        options: _auth(accessToken),
      );
      return null;
    } on DioException catch (e) {
      return _extractError(e);
    }
  }

  Future<void> deleteRsvp(String accessToken, String rsvpId) async {
    try {
      await _dio.delete('/api/guests/responses/$rsvpId', options: _auth(accessToken));
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  Future<void> updateRsvpStatus(String accessToken, String rsvpId, AttendingStatus attending) async {
    try {
      await _dio.patch(
        '/api/guests/responses/$rsvpId',
        data: {'attending': attending.name},
        options: _auth(accessToken),
      );
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  /// Couple-initiated edits only — see [RsvpHistoryEntry].
  Future<List<RsvpHistoryEntry>> fetchRsvpHistory(String accessToken, String rsvpId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/guests/responses/$rsvpId/history',
        options: _auth(accessToken),
      );
      final list = (response.data?['history'] as List?) ?? [];
      return list.map((h) => RsvpHistoryEntry.fromJson(h as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  // ── Invitations (couple-side) ─────────────────────────────────────────────────

  Future<List<Invitation>> fetchInvitations(String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/invitations', options: _auth(accessToken));
      final list = (response.data?['invitations'] as List?) ?? [];
      return list.map((i) => Invitation.fromJson(i as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  Future<Invitation> createInvitation(String accessToken, {required String templateId, required String title}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/invitations',
        data: {'template_id': templateId, 'title': title},
        options: _auth(accessToken),
      );
      return Invitation.fromJson(response.data?['invitation'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  Future<Invitation> updateInvitationCustomData(
    String accessToken,
    String invitationId,
    Map<String, dynamic> customData,
  ) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/invitations/$invitationId',
        data: {'custom_data': customData},
        options: _auth(accessToken),
      );
      return Invitation.fromJson(response.data?['invitation'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  Future<Invitation> publishInvitation(String accessToken, String invitationId) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/invitations/$invitationId/publish',
        options: _auth(accessToken),
      );
      return Invitation.fromJson(response.data?['invitation'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  Future<void> deleteInvitation(String accessToken, String invitationId) async {
    try {
      await _dio.delete('/api/invitations/$invitationId', options: _auth(accessToken));
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  Future<Invitation> uploadInvitationPhoto(
    String accessToken,
    String invitationId, {
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/invitations/$invitationId/photo',
        data: form,
        options: _auth(accessToken),
      );
      return Invitation.fromJson(response.data?['invitation'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  // ── Meal options (couple-side) ────────────────────────────────────────────────

  Future<List<MealOption>> fetchMealOptions(String accessToken, String invitationId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/invitations/$invitationId/meal-options',
        options: _auth(accessToken),
      );
      final list = (response.data?['meal_options'] as List?) ?? [];
      return list.map((o) => MealOption.fromJson(o as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  Future<MealOption> addMealOption(String accessToken, String invitationId, String label) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/invitations/$invitationId/meal-options',
        data: {'label': label},
        options: _auth(accessToken),
      );
      return MealOption.fromJson(response.data?['meal_option'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  Future<MealOption> editMealOption(String accessToken, String optionId, String label) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/invitations/meal-options/$optionId',
        data: {'label': label},
        options: _auth(accessToken),
      );
      return MealOption.fromJson(response.data?['meal_option'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  Future<void> deleteMealOption(String accessToken, String optionId) async {
    try {
      await _dio.delete('/api/invitations/meal-options/$optionId', options: _auth(accessToken));
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  // ── Custom RSVP questions (couple-side) ───────────────────────────────────────

  Future<List<RsvpQuestion>> fetchRsvpQuestions(String accessToken, String invitationId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/invitations/$invitationId/rsvp-questions',
        options: _auth(accessToken),
      );
      final list = (response.data?['rsvp_questions'] as List?) ?? [];
      return list.map((q) => RsvpQuestion.fromJson(q as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  Future<RsvpQuestion> addRsvpQuestion(
    String accessToken,
    String invitationId, {
    required String questionText,
    required RsvpQuestionType type,
    List<String>? options,
    bool isRequired = false,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/invitations/$invitationId/rsvp-questions',
        data: {
          'questionText': questionText,
          'type': questionTypeToWire(type),
          'options': options,
          'isRequired': isRequired,
        },
        options: _auth(accessToken),
      );
      return RsvpQuestion.fromJson(response.data?['rsvp_question'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  Future<RsvpQuestion> editRsvpQuestion(
    String accessToken,
    String questionId, {
    required String questionText,
    required RsvpQuestionType type,
    List<String>? options,
    bool isRequired = false,
    bool isEnabled = true,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/invitations/rsvp-questions/$questionId',
        data: {
          'questionText': questionText,
          'type': questionTypeToWire(type),
          'options': options,
          'isRequired': isRequired,
          'isEnabled': isEnabled,
        },
        options: _auth(accessToken),
      );
      return RsvpQuestion.fromJson(response.data?['rsvp_question'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  Future<RsvpQuestion> toggleRsvpQuestionEnabled(String accessToken, String questionId, bool isEnabled) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/invitations/rsvp-questions/$questionId',
        data: {'isEnabled': isEnabled},
        options: _auth(accessToken),
      );
      return RsvpQuestion.fromJson(response.data?['rsvp_question'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  /// Throws [InvitationApiException] with a 409 message ("guests have
  /// already answered...") when the question has any answers — the caller
  /// should fall back to [toggleRsvpQuestionEnabled] instead.
  Future<void> deleteRsvpQuestion(String accessToken, String questionId) async {
    try {
      await _dio.delete('/api/invitations/rsvp-questions/$questionId', options: _auth(accessToken));
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  // ── Public, unauthenticated guest-facing endpoints ────────────────────────────

  /// Returns `null` if no published invitation exists for this token (404 — expected).
  Future<PublicInvitationView?> fetchPublicInvitation(String shareToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/invitations/public/$shareToken');
      return PublicInvitationView.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw InvitationApiException(_extractError(e));
    }
  }

  /// Submits an RSVP through the shared broadcast link. [name] is matched
  /// against the couple's own guest list — a name that isn't on it is
  /// rejected with a 403 rather than added, so forwarding the link can't grow
  /// the headcount. Single-use per name: a guest who has already answered
  /// gets a 409. Both arrive as an [InvitationApiException].
  ///
  /// Party size is deliberately not a parameter: it comes from the guest
  /// record the name resolves to, and the server ignores any count sent here.
  Future<void> submitPublicRsvp(
    String shareToken, {
    required String name,
    String? email,
    required AttendingStatus attending,
    String? mealPreference,
    String? dietaryNotes,
    String? message,
    List<RsvpAnswerInput>? answers,
  }) async {
    try {
      await _dio.post(
        '/api/invitations/public/$shareToken/rsvp',
        data: {
          'name': name,
          'email': email,
          'attending': attending.name,
          'mealPreference': mealPreference,
          'dietaryNotes': dietaryNotes,
          'message': message,
          'answers': answers?.map((a) => a.toJson()).toList(),
        },
      );
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  /// Returns `null` if no such invite token resolves to a published
  /// invitation (404 — expected, e.g. a deleted guest or unpublished design).
  Future<GuestInvitation?> fetchGuestInvitation(String inviteToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/invitations/public/guest/$inviteToken');
      return GuestInvitation.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw InvitationApiException(_extractError(e));
    }
  }

  /// Submits an RSVP through a guest's personal invite link. Single-use: the
  /// server rejects this with a 409 (surfaced as [InvitationApiException])
  /// if the guest has already responded through this link before.
  Future<void> submitGuestInviteRsvp(
    String inviteToken, {
    required AttendingStatus attending,
    required int guestCount,
    String? mealPreference,
    String? dietaryNotes,
    String? message,
    List<RsvpAnswerInput>? answers,
  }) async {
    try {
      await _dio.post(
        '/api/invitations/public/guest/$inviteToken/rsvp',
        data: {
          'attending': attending.name,
          'guestCount': guestCount,
          'mealPreference': mealPreference,
          'dietaryNotes': dietaryNotes,
          'message': message,
          'answers': answers?.map((a) => a.toJson()).toList(),
        },
      );
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  String _extractError(DioException e) => describeDioError(e);
}
