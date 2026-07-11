import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';

import '../../models/invitation.dart';

const int _backendPort = 3000;
// Set this to your machine's LAN IP (e.g. '192.168.1.20') when testing a
// shared invitation link on a separate physical device, since 'localhost'
// on that device would refer to itself, not this computer.
const String? _lanHost = null;

String get _baseUrl {
  if (_lanHost != null) return 'http://$_lanHost:$_backendPort';
  if (kIsWeb) return 'http://localhost:$_backendPort';
  if (Platform.isAndroid) return 'http://10.0.2.2:$_backendPort';
  return 'http://localhost:$_backendPort';
}

/// Resolves a stored relative upload path (e.g. '/uploads/invitations/x.jpg')
/// to an absolute URL. Already-absolute URLs are returned unchanged.
String resolveInvitationMediaUrl(String urlOrPath) =>
    urlOrPath.startsWith('http') ? urlOrPath : '$_baseUrl$urlOrPath';

class InvitationApiException implements Exception {
  final String message;
  const InvitationApiException(this.message);
}

class InvitationApiService {
  InvitationApiService._();
  static final InvitationApiService instance = InvitationApiService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));

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
  }) async {
    try {
      await _dio.post(
        '/api/guests',
        data: {'name': name, 'email': email, 'phone': phone, 'relation': relation},
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
  }) async {
    try {
      await _dio.patch(
        '/api/guests/$id',
        data: {'name': name, 'email': email, 'phone': phone, 'relation': relation},
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

  // ── Public, unauthenticated guest-facing endpoints ────────────────────────────

  /// Returns `null` if no published invitation exists for this token (404 — expected).
  Future<Invitation?> fetchPublicInvitation(String shareToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/invitations/public/$shareToken');
      return Invitation.fromJson(response.data?['invitation'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw InvitationApiException(_extractError(e));
    }
  }

  Future<void> submitPublicRsvp(
    String shareToken, {
    required String name,
    String? email,
    required AttendingStatus attending,
    required int guestCount,
    String? message,
  }) async {
    try {
      await _dio.post(
        '/api/invitations/public/$shareToken/rsvp',
        data: {
          'name': name,
          'email': email,
          'attending': attending.name,
          'guestCount': guestCount,
          'message': message,
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

  /// Submits an RSVP through a guest's personal invite link. Throws
  /// [InvitationApiException] with a 409 message if this guest has already
  /// responded through this link.
  Future<void> submitGuestInviteRsvp(
    String inviteToken, {
    required AttendingStatus attending,
    required int guestCount,
    String? message,
  }) async {
    try {
      await _dio.post(
        '/api/invitations/public/guest/$inviteToken/rsvp',
        data: {
          'attending': attending.name,
          'guestCount': guestCount,
          'message': message,
        },
      );
    } on DioException catch (e) {
      throw InvitationApiException(_extractError(e));
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return 'Could not reach the server. Please try again.';
  }
}
