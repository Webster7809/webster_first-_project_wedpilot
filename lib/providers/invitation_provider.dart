import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invitation.dart';
import '../core/services/invitation_api_service.dart';
import '../core/services/rsvp_service.dart';
import '../core/state/resource.dart';
import 'auth_provider.dart';
import 'booking_provider.dart' show bookedVendorsProvider;

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

  /// Returns the server error message, or null on success.
  Future<String?> delete(String invitationId) async {
    final token = _token;
    if (token == null) return 'Please sign in to delete invitations.';
    try {
      await InvitationApiService.instance.deleteInvitation(token, invitationId);
      state = state.where((inv) => inv.id != invitationId).toList();
      return null;
    } on InvitationApiException catch (e) {
      return e.message;
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
    String? invitationId,
    int? maxPartySize,
  }) async {
    final token = _token;
    if (token == null) return 'Please sign in to add guests.';
    final error = await InvitationApiService.instance.addGuest(
      token,
      name: name,
      email: email,
      phone: phone,
      relation: relation,
      invitationId: invitationId,
      maxPartySize: maxPartySize,
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
    int? maxPartySize,
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
      maxPartySize: maxPartySize,
    );
    if (error != null) return error;
    await load();
    return null;
  }

  /// Returns the server error message, or null on success.
  Future<String?> deleteGuest(String id) async {
    final token = _token;
    if (token == null) return 'Please sign in to remove guests.';
    try {
      await InvitationApiService.instance.deleteGuest(token, id);
      state = state.copyWith(
        guests: state.guests.where((g) => g.id != id).toList(),
        responses: state.responses.where((r) => r.guestId != id).toList(),
      );
      return null;
    } on InvitationApiException catch (e) {
      return e.message;
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

  // ── Door check-in ────────────────────────────────────────────────────────────

  /// Verifies [cardNumber] and marks the matching guest checked in. Returns
  /// the guest on success, or an error message on failure (not found /
  /// already checked in) — a record instead of throwing, since the check-in
  /// screen needs to show the failure reason inline, not via a snackbar.
  Future<(Guest?, String?)> checkInGuest(String cardNumber) async {
    final token = _token;
    if (token == null) return (null, 'Please sign in to check in guests.');
    try {
      final guest = await InvitationApiService.instance.checkInGuestByCardNumber(token, cardNumber);
      state = state.copyWith(guests: state.guests.map((g) => g.id == guest.id ? guest : g).toList());
      return (guest, null);
    } on InvitationApiException catch (e) {
      return (null, e.message);
    }
  }

  Future<void> toggleCheckin(String id) async {
    final token = _token;
    if (token == null) return;
    try {
      final guest = await InvitationApiService.instance.toggleGuestCheckin(token, id);
      state = state.copyWith(guests: state.guests.map((g) => g.id == guest.id ? guest : g).toList());
    } on InvitationApiException {
      // Leave state as-is on failure.
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

  /// Couple-initiated edits only — see [RsvpHistoryEntry]. Returns an empty
  /// list on failure rather than throwing, since this only backs an optional
  /// "View history" affordance, not a primary flow.
  Future<List<RsvpHistoryEntry>> fetchRsvpHistory(String rsvpId) async {
    final token = _token;
    if (token == null) return const [];
    try {
      return await InvitationApiService.instance.fetchRsvpHistory(token, rsvpId);
    } on InvitationApiException {
      return const [];
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

/// The guest count vendor-capacity checks and matching should actually use:
/// the real confirmed RSVP total once any exist, falling back to the
/// couple's manually-entered onboarding estimate (CoupleProfile.guestCount)
/// otherwise. Real RSVP data is ground truth the moment it exists — the
/// manual estimate was always just a placeholder for it, entered before any
/// guest had actually responded.
final effectiveGuestCountProvider = Provider<int?>((ref) {
  final totalAttending = ref.watch(rsvpStatsProvider).totalAttending;
  if (totalAttending > 0) return totalAttending;
  return ref.watch(coupleProfileProvider)?.guestCount;
});

/// Whether/why a guest-based catering estimate can be shown. [cannotCalculate]
/// covers both "no single per-person listing" and "more than one booked
/// caterer" — either way, guessing which price applies would be a fake
/// number, which the couple's own RSVP data must never produce.
enum CateringEstimateStatus { noBookedCaterer, cannotCalculate, available }

class CateringEstimate {
  final CateringEstimateStatus status;
  final String? vendorName;
  final double? priceMin;
  final double? priceMax;
  final int confirmedGuests;
  final double? estimatedTotal;

  const CateringEstimate({
    required this.status,
    this.vendorName,
    this.priceMin,
    this.priceMax,
    required this.confirmedGuests,
    this.estimatedTotal,
  });
}

/// Guest-based catering estimate — see spec's budget-integration
/// requirement. Deliberately narrow: only computes when the couple's booked
/// Catering vendor has exactly one active per-person-priced listing, so this
/// never presents a guessed number as real. Never mutates Budget.categories;
/// purely a read-only insight derived live from already-fetched data.
final cateringEstimateProvider = Provider<CateringEstimate?>((ref) {
  final vendors = ref.watch(bookedVendorsProvider).valueOrNull;
  if (vendors == null) return null;

  final caterers = vendors.where((v) => v.category == 'Catering').toList();
  if (caterers.isEmpty) return null;

  final confirmedGuests = ref.watch(rsvpStatsProvider).totalAttending;

  if (caterers.length > 1) {
    return CateringEstimate(
      status: CateringEstimateStatus.cannotCalculate,
      confirmedGuests: confirmedGuests,
    );
  }

  final caterer = caterers.single;
  final personServices =
      caterer.services.where((s) => s.isActive && s.unit == 'person').toList();
  if (personServices.length != 1) {
    return CateringEstimate(
      status: CateringEstimateStatus.cannotCalculate,
      vendorName: caterer.businessName,
      confirmedGuests: confirmedGuests,
    );
  }

  final service = personServices.single;
  final pricePerGuest = (service.priceMin + service.priceMax) / 2;
  return CateringEstimate(
    status: CateringEstimateStatus.available,
    vendorName: caterer.businessName,
    priceMin: service.priceMin,
    priceMax: service.priceMax,
    confirmedGuests: confirmedGuests,
    estimatedTotal: pricePerGuest * confirmedGuests,
  );
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
