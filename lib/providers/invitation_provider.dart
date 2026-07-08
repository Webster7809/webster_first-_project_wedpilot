import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invitation.dart';
import '../core/services/invitation_api_service.dart';
import '../core/services/rsvp_service.dart';
import '../core/state/resource.dart';
import 'auth_provider.dart';

export '../core/services/rsvp_service.dart' show RsvpStats;

// ── Invitation CRUD ───────────────────────────────────────────────────────────

/// Design themes/catalog — static product content, not user data, so this
/// stays a plain constant list rather than a backend-fetched resource (same
/// treatment as AppConstants.vendorCategories elsewhere in the app).
final invitationTemplatesProvider = FutureProvider<List<InvitationTemplate>>((ref) async {
  return _templates;
});

final invitationsProvider = StateNotifierProvider<InvitationNotifier, List<Invitation>>(
  (ref) => InvitationNotifier(ref),
);

class InvitationNotifier extends StateNotifier<List<Invitation>> {
  InvitationNotifier(this._ref) : super([]);

  final Ref _ref;
  ResourceStatus status = ResourceStatus.initial;

  String? get _token => _ref.read(authProvider.notifier).accessToken;

  Future<void> loadInvitations() async {
    final token = _token;
    if (token == null) return;
    status = ResourceStatus.loading;
    try {
      state = await InvitationApiService.instance.fetchInvitations(token);
      status = ResourceStatus.ready;
    } catch (_) {
      status = ResourceStatus.error;
    }
  }

  /// Returns the new invitation's id, or null if the request failed.
  Future<String?> create(String templateId, String title) async {
    final token = _token;
    if (token == null) return null;
    try {
      final invitation = await InvitationApiService.instance.createInvitation(
        token,
        templateId: templateId,
        title: title,
      );
      state = [invitation, ...state];
      return invitation.id;
    } on InvitationApiException {
      return null;
    }
  }

  Future<void> updateCustomData(String invitationId, Map<String, dynamic> data) async {
    final token = _token;
    if (token == null) return;
    try {
      final updated = await InvitationApiService.instance.updateInvitationCustomData(token, invitationId, data);
      state = state.map((inv) => inv.id == invitationId ? updated : inv).toList();
    } on InvitationApiException {
      // Edits stay local-only in the form controllers if the save fails;
      // the next successful save will re-sync everything.
    }
  }

  Future<void> publish(String invitationId) async {
    final token = _token;
    if (token == null) return;
    try {
      final updated = await InvitationApiService.instance.publishInvitation(token, invitationId);
      state = state.map((inv) => inv.id == invitationId ? updated : inv).toList();
    } on InvitationApiException {
      // Leave state as-is; caller's snackbar/error handling surfaces the failure.
    }
  }

  /// Uploads the invitation's background photo, persisting it server-side
  /// so it survives beyond this editing session. Returns the resulting
  /// `backgroundImageUrl`, or null on failure.
  Future<String?> uploadPhoto(String invitationId, Uint8List bytes, String filename) async {
    final token = _token;
    if (token == null) return null;
    try {
      final updated = await InvitationApiService.instance.uploadInvitationPhoto(
        token,
        invitationId,
        bytes: bytes,
        filename: filename,
      );
      state = state.map((inv) => inv.id == invitationId ? updated : inv).toList();
      return updated.customData['backgroundImageUrl'] as String?;
    } on InvitationApiException {
      return null;
    }
  }
}

// ── Guest + RSVP management ──────────────────────────────────────────────────

class GuestRsvpState {
  final List<Guest> guests;
  final List<RsvpResponse> responses;

  const GuestRsvpState({
    required this.guests,
    required this.responses,
  });

  RsvpStats get stats => RsvpService.calculateStats(responses, guests);

  GuestRsvpState copyWith({
    List<Guest>? guests,
    List<RsvpResponse>? responses,
  }) =>
      GuestRsvpState(
        guests: guests ?? this.guests,
        responses: responses ?? this.responses,
      );
}

class GuestRsvpNotifier extends StateNotifier<GuestRsvpState> {
  GuestRsvpNotifier(this._ref) : super(const GuestRsvpState(guests: [], responses: []));

  final Ref _ref;
  ResourceStatus status = ResourceStatus.initial;

  String? get _token => _ref.read(authProvider.notifier).accessToken;

  Future<void> load() async {
    final token = _token;
    if (token == null) return;
    status = ResourceStatus.loading;
    try {
      final results = await Future.wait([
        InvitationApiService.instance.fetchGuests(token),
        InvitationApiService.instance.fetchRsvpResponses(token),
      ]);
      state = GuestRsvpState(
        guests: results[0] as List<Guest>,
        responses: results[1] as List<RsvpResponse>,
      );
      status = ResourceStatus.ready;
    } catch (_) {
      status = ResourceStatus.error;
    }
  }

  // ── Guest CRUD ──────────────────────────────────────────────────────────────

  Future<String?> addGuest({
    required String name,
    String? email,
    String? phone,
    String? relation,
  }) async {
    final token = _token;
    if (token == null) return 'Please sign in to add guests.';
    final error = await InvitationApiService.instance.addGuest(
      token,
      name: name,
      email: email,
      phone: phone,
      relation: relation,
    );
    if (error != null) return error;
    await load();
    return null;
  }

  Future<String?> editGuest({
    required String id,
    required String name,
    String? email,
    String? phone,
    String? relation,
  }) async {
    final token = _token;
    if (token == null) return 'Please sign in to edit guests.';
    final error = await InvitationApiService.instance.editGuest(
      token,
      id: id,
      name: name,
      email: email,
      phone: phone,
      relation: relation,
    );
    if (error != null) return error;
    await load();
    return null;
  }

  Future<void> deleteGuest(String id) async {
    final token = _token;
    if (token == null) return;
    try {
      await InvitationApiService.instance.deleteGuest(token, id);
      state = state.copyWith(
        guests: state.guests.where((g) => g.id != id).toList(),
        responses: state.responses.where((r) => r.guestId != id).toList(),
      );
    } on InvitationApiException {
      // Leave state as-is on failure.
    }
  }

  Future<void> toggleInvited(String id) async {
    final token = _token;
    if (token == null) return;
    try {
      await InvitationApiService.instance.toggleGuestInvited(token, id);
      await load();
    } on InvitationApiException {
      // Leave state as-is on failure.
    }
  }

  /// Gets (lazily generating server-side) this guest's personal invite link,
  /// or null on failure. Also refreshes this guest's local state entry so
  /// `inviteUrl` is immediately available to callers.
  Future<Guest?> getGuestInviteLink({required String guestId, required String invitationId}) async {
    final token = _token;
    if (token == null) return null;
    try {
      final guest = await InvitationApiService.instance.fetchOrCreateGuestInviteLink(
        token,
        guestId: guestId,
        invitationId: invitationId,
      );
      state = state.copyWith(guests: state.guests.map((g) => g.id == guest.id ? guest : g).toList());
      return guest;
    } on InvitationApiException {
      return null;
    }
  }

  // ── RSVP management ─────────────────────────────────────────────────────────

  Future<String?> submitRsvp({
    required String guestId,
    required AttendingStatus attending,
    required int guestCount,
    String? mealPreference,
    String? dietaryNotes,
    String? message,
    String? invitationId,
  }) async {
    final token = _token;
    if (token == null) return 'Please sign in to record an RSVP.';
    final error = await InvitationApiService.instance.submitGuestRsvp(
      token,
      guestId: guestId,
      attending: attending,
      guestCount: guestCount,
      mealPreference: mealPreference,
      dietaryNotes: dietaryNotes,
      message: message,
      invitationId: invitationId,
    );
    if (error != null) return error;
    await load();
    return null;
  }

  Future<void> deleteRsvp(String rsvpId) async {
    final token = _token;
    if (token == null) return;
    try {
      await InvitationApiService.instance.deleteRsvp(token, rsvpId);
      state = state.copyWith(responses: state.responses.where((r) => r.id != rsvpId).toList());
    } on InvitationApiException {
      // Leave state as-is on failure.
    }
  }

  Future<void> updateRsvpStatus(String rsvpId, AttendingStatus newStatus) async {
    final token = _token;
    if (token == null) return;
    try {
      await InvitationApiService.instance.updateRsvpStatus(token, rsvpId, newStatus);
      await load();
    } on InvitationApiException {
      // Leave state as-is on failure.
    }
  }
}

final guestRsvpProvider =
    StateNotifierProvider<GuestRsvpNotifier, GuestRsvpState>(
  (ref) => GuestRsvpNotifier(ref),
);

/// Convenience derived provider for stats only.
final rsvpStatsProvider = Provider<RsvpStats>((ref) {
  return ref.watch(guestRsvpProvider).stats;
});

// ── Templates ─────────────────────────────────────────────────────────────────

const _templates = [
  InvitationTemplate(id: 'tpl-001', name: 'Romantic Floral', theme: 'romantic', previewUrl: '', isPremium: false, isActive: true),
  InvitationTemplate(id: 'tpl-002', name: 'Modern Minimalist', theme: 'modern', previewUrl: '', isPremium: false, isActive: true),
  InvitationTemplate(id: 'tpl-003', name: 'Royal Gold', theme: 'royal', previewUrl: '', isPremium: true, isActive: true),
  InvitationTemplate(id: 'tpl-004', name: 'Rustic Botanical', theme: 'rustic', previewUrl: '', isPremium: false, isActive: true),
  InvitationTemplate(id: 'tpl-005', name: 'Boho Chic', theme: 'boho', previewUrl: '', isPremium: true, isActive: true),
  InvitationTemplate(id: 'tpl-006', name: 'Beach Sunset', theme: 'beach', previewUrl: '', isPremium: true, isActive: true),
  InvitationTemplate(id: 'tpl-007', name: 'Celestial Night', theme: 'celestial', previewUrl: '', isPremium: true, isActive: true),
  InvitationTemplate(id: 'tpl-008', name: 'Cultural — African', theme: 'african', previewUrl: '', isPremium: true, isActive: true),
  InvitationTemplate(id: 'tpl-009', name: 'Cultural — Islamic', theme: 'islamic', previewUrl: '', isPremium: true, isActive: true),
  InvitationTemplate(id: 'tpl-010', name: 'Cultural — Indian', theme: 'indian', previewUrl: '', isPremium: true, isActive: true),
];
