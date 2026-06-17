import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invitation.dart';
import '../core/services/rsvp_service.dart';

export '../core/services/rsvp_service.dart' show RsvpStats;

// ── Invitation CRUD ───────────────────────────────────────────────────────────

final invitationTemplatesProvider = FutureProvider<List<InvitationTemplate>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 400));
  return _mockTemplates;
});

final invitationsProvider = StateNotifierProvider<InvitationNotifier, List<Invitation>>(
  (ref) => InvitationNotifier(),
);

class InvitationNotifier extends StateNotifier<List<Invitation>> {
  InvitationNotifier() : super([]);

  String create(String templateId, String title) {
    final id = 'inv-${DateTime.now().millisecondsSinceEpoch}';
    state = [
      ...state,
      Invitation(
        id: id,
        coupleId: 'profile-001',
        templateId: templateId,
        title: title,
        customData: const {},
        shareToken: 'tok-${DateTime.now().millisecondsSinceEpoch}',
        status: InvitationStatus.draft,
        createdAt: DateTime.now(),
      ),
    ];
    return id;
  }

  void updateCustomData(String invitationId, Map<String, dynamic> data) {
    state = state.map((inv) {
      if (inv.id != invitationId) return inv;
      return Invitation(
        id: inv.id,
        coupleId: inv.coupleId,
        templateId: inv.templateId,
        title: data['coupleName'] as String? ?? inv.title,
        customData: {...inv.customData, ...data},
        shareToken: inv.shareToken,
        shareUrl: inv.shareUrl,
        thumbnailUrl: inv.thumbnailUrl,
        status: inv.status,
        viewCount: inv.viewCount,
        createdAt: inv.createdAt,
      );
    }).toList();
  }

  void publish(String invitationId) {
    state = state.map((inv) {
      if (inv.id != invitationId) return inv;
      return Invitation(
        id: inv.id,
        coupleId: inv.coupleId,
        templateId: inv.templateId,
        title: inv.title,
        customData: inv.customData,
        shareToken: inv.shareToken,
        shareUrl: 'https://wedpilot.app/i/${inv.shareToken}',
        thumbnailUrl: inv.thumbnailUrl,
        status: InvitationStatus.published,
        viewCount: inv.viewCount,
        createdAt: inv.createdAt,
      );
    }).toList();
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
  GuestRsvpNotifier()
      : super(GuestRsvpState(
          guests: _seedGuests,
          responses: _seedResponses,
        ));

  // ── Guest CRUD ──────────────────────────────────────────────────────────────

  String? addGuest({
    required String name,
    String? email,
    String? phone,
    String? relation,
  }) {
    final error = RsvpService.validateGuest(name: name, email: email, phone: phone);
    if (error != null) return error;

    final duplicate = state.guests.any(
      (g) => g.name.trim().toLowerCase() == name.trim().toLowerCase(),
    );
    if (duplicate) return 'A guest named "$name" already exists.';

    final id = 'guest-${DateTime.now().millisecondsSinceEpoch}';
    state = state.copyWith(
      guests: [
        ...state.guests,
        Guest(
          id: id,
          coupleId: 'profile-001',
          name: name.trim(),
          email: email?.trim().isEmpty == true ? null : email?.trim(),
          phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
          relation: relation?.trim().isEmpty == true ? null : relation?.trim(),
          isInvited: true,
        ),
      ],
    );
    return null;
  }

  String? editGuest({
    required String id,
    required String name,
    String? email,
    String? phone,
    String? relation,
  }) {
    final error = RsvpService.validateGuest(name: name, email: email, phone: phone);
    if (error != null) return error;

    final duplicate = state.guests.any(
      (g) =>
          g.id != id &&
          g.name.trim().toLowerCase() == name.trim().toLowerCase(),
    );
    if (duplicate) return 'Another guest named "$name" already exists.';

    state = state.copyWith(
      guests: state.guests.map((g) {
        if (g.id != id) return g;
        return Guest(
          id: g.id,
          coupleId: g.coupleId,
          name: name.trim(),
          email: email?.trim().isEmpty == true ? null : email?.trim(),
          phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
          relation: relation?.trim().isEmpty == true ? null : relation?.trim(),
          isInvited: g.isInvited,
        );
      }).toList(),
    );
    return null;
  }

  void deleteGuest(String id) {
    state = state.copyWith(
      guests: state.guests.where((g) => g.id != id).toList(),
      responses: state.responses.where((r) => r.guestId != id).toList(),
    );
  }

  void toggleInvited(String id) {
    state = state.copyWith(
      guests: state.guests.map((g) {
        if (g.id != id) return g;
        return Guest(
          id: g.id,
          coupleId: g.coupleId,
          name: g.name,
          email: g.email,
          phone: g.phone,
          relation: g.relation,
          isInvited: !g.isInvited,
        );
      }).toList(),
    );
  }

  // ── RSVP management ─────────────────────────────────────────────────────────

  String? submitRsvp({
    required String guestId,
    required String guestName,
    required AttendingStatus attending,
    required int guestCount,
    String? mealPreference,
    String? dietaryNotes,
    String? message,
  }) {
    final error = RsvpService.validateRsvp(
      guestName: guestName,
      guestCount: guestCount,
      attending: attending,
    );
    if (error != null) return error;

    // Replace any existing response for this guest
    final existing = state.responses.indexWhere((r) => r.guestId == guestId);
    final rsvp = RsvpResponse(
      id: existing >= 0
          ? state.responses[existing].id
          : 'rsvp-${DateTime.now().millisecondsSinceEpoch}',
      invitationId: 'inv-001',
      guestId: guestId,
      guestName: guestName,
      attending: attending,
      guestCount: attending == AttendingStatus.no ? 0 : guestCount,
      mealPreference: mealPreference?.trim().isEmpty == true ? null : mealPreference,
      dietaryNotes: dietaryNotes?.trim().isEmpty == true ? null : dietaryNotes,
      message: message?.trim().isEmpty == true ? null : message,
      respondedAt: DateTime.now(),
    );

    final updatedResponses = [...state.responses];
    if (existing >= 0) {
      updatedResponses[existing] = rsvp;
    } else {
      updatedResponses.add(rsvp);
    }

    state = state.copyWith(responses: updatedResponses);
    return null;
  }

  void deleteRsvp(String rsvpId) {
    state = state.copyWith(
      responses: state.responses.where((r) => r.id != rsvpId).toList(),
    );
  }

  void updateRsvpStatus(String rsvpId, AttendingStatus newStatus) {
    state = state.copyWith(
      responses: state.responses.map((r) {
        if (r.id != rsvpId) return r;
        return RsvpResponse(
          id: r.id,
          invitationId: r.invitationId,
          guestId: r.guestId,
          guestName: r.guestName,
          attending: newStatus,
          guestCount: newStatus == AttendingStatus.no ? 0 : r.guestCount,
          mealPreference: r.mealPreference,
          dietaryNotes: r.dietaryNotes,
          message: r.message,
          respondedAt: DateTime.now(),
        );
      }).toList(),
    );
  }
}

final guestRsvpProvider =
    StateNotifierProvider<GuestRsvpNotifier, GuestRsvpState>(
  (ref) => GuestRsvpNotifier(),
);

/// Convenience derived provider for stats only.
final rsvpStatsProvider = Provider<RsvpStats>((ref) {
  return ref.watch(guestRsvpProvider).stats;
});

/// Kept for backward compatibility with existing code that watches it.
final rsvpResponsesProvider = FutureProvider.family<List<RsvpResponse>, String>(
  (ref, invitationId) async {
    return ref.watch(guestRsvpProvider).responses;
  },
);

// ── Seed data ─────────────────────────────────────────────────────────────────

final _seedGuests = [
  const Guest(
    id: 'guest-001', coupleId: 'profile-001',
    name: 'Sarah Williams', email: 'sarah@example.com',
    phone: '+1 555-0101', relation: 'Friend', isInvited: true,
  ),
  const Guest(
    id: 'guest-002', coupleId: 'profile-001',
    name: 'Tom Williams', email: 'tom@example.com',
    phone: '+1 555-0102', relation: 'Friend', isInvited: true,
  ),
  const Guest(
    id: 'guest-003', coupleId: 'profile-001',
    name: 'Michael Chen', email: 'mchen@example.com',
    relation: 'Colleague', isInvited: true,
  ),
  const Guest(
    id: 'guest-004', coupleId: 'profile-001',
    name: 'Lisa Park', email: 'lisa.park@example.com',
    relation: 'Family', isInvited: true,
  ),
  const Guest(
    id: 'guest-005', coupleId: 'profile-001',
    name: 'John Davis', phone: '+1 555-0105',
    relation: 'Family', isInvited: true,
  ),
  const Guest(
    id: 'guest-006', coupleId: 'profile-001',
    name: 'Emma Wilson', email: 'emma.w@example.com',
    relation: 'Friend', isInvited: true,
  ),
];

final _seedResponses = [
  RsvpResponse(
    id: 'rsvp-001', invitationId: 'inv-001',
    guestId: 'guest-001', guestName: 'Sarah Williams',
    attending: AttendingStatus.yes, guestCount: 2,
    mealPreference: 'Chicken',
    respondedAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  RsvpResponse(
    id: 'rsvp-002', invitationId: 'inv-001',
    guestId: 'guest-002', guestName: 'Tom Williams',
    attending: AttendingStatus.yes, guestCount: 1,
    mealPreference: 'Beef',
    respondedAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  RsvpResponse(
    id: 'rsvp-003', invitationId: 'inv-001',
    guestId: 'guest-003', guestName: 'Michael Chen',
    attending: AttendingStatus.yes, guestCount: 1,
    mealPreference: 'Vegetarian',
    respondedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  RsvpResponse(
    id: 'rsvp-004', invitationId: 'inv-001',
    guestId: 'guest-004', guestName: 'Lisa Park',
    attending: AttendingStatus.no, guestCount: 0,
    message: 'So sorry, we have a prior commitment!',
    respondedAt: DateTime.now().subtract(const Duration(hours: 12)),
  ),
];

// ── Templates ─────────────────────────────────────────────────────────────────

const _mockTemplates = [
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
