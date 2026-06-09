import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invitation.dart';

final invitationTemplatesProvider = FutureProvider<List<InvitationTemplate>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 400));
  return _mockTemplates;
});

final invitationsProvider = StateNotifierProvider<InvitationNotifier, List<Invitation>>(
  (ref) => InvitationNotifier(),
);

class InvitationNotifier extends StateNotifier<List<Invitation>> {
  InvitationNotifier() : super([]);

  void create(String templateId, String title) {
    final inv = Invitation(
      id: 'inv-${DateTime.now().millisecondsSinceEpoch}',
      coupleId: 'profile-001',
      templateId: templateId,
      title: title,
      customData: {},
      shareToken: 'tok-${DateTime.now().millisecondsSinceEpoch}',
      status: InvitationStatus.draft,
      createdAt: DateTime.now(),
    );
    state = [...state, inv];
  }

  void publish(String invitationId) {
    state = state.map((inv) {
      if (inv.id == invitationId) {
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
      }
      return inv;
    }).toList();
  }
}

final rsvpResponsesProvider = FutureProvider.family<List<RsvpResponse>, String>(
  (ref, invitationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockRsvps;
  },
);

final _mockTemplates = [
  InvitationTemplate(
    id: 'tpl-001',
    name: 'Romantic Floral',
    theme: 'romantic',
    previewUrl: '',
    isPremium: false,
    isActive: true,
  ),
  InvitationTemplate(
    id: 'tpl-002',
    name: 'Modern Minimalist',
    theme: 'modern',
    previewUrl: '',
    isPremium: false,
    isActive: true,
  ),
  InvitationTemplate(
    id: 'tpl-003',
    name: 'Royal Gold',
    theme: 'royal',
    previewUrl: '',
    isPremium: true,
    isActive: true,
  ),
  InvitationTemplate(
    id: 'tpl-004',
    name: 'Rustic Botanical',
    theme: 'rustic',
    previewUrl: '',
    isPremium: false,
    isActive: true,
  ),
  InvitationTemplate(
    id: 'tpl-005',
    name: 'Boho Chic',
    theme: 'boho',
    previewUrl: '',
    isPremium: true,
    isActive: true,
  ),
  InvitationTemplate(
    id: 'tpl-006',
    name: 'Beach Sunset',
    theme: 'beach',
    previewUrl: '',
    isPremium: true,
    isActive: true,
  ),
  InvitationTemplate(
    id: 'tpl-007',
    name: 'Celestial Night',
    theme: 'celestial',
    previewUrl: '',
    isPremium: true,
    isActive: true,
  ),
  InvitationTemplate(
    id: 'tpl-008',
    name: 'Cultural — African',
    theme: 'african',
    previewUrl: '',
    isPremium: true,
    isActive: true,
  ),
  InvitationTemplate(
    id: 'tpl-009',
    name: 'Cultural — Islamic',
    theme: 'islamic',
    previewUrl: '',
    isPremium: true,
    isActive: true,
  ),
  InvitationTemplate(
    id: 'tpl-010',
    name: 'Cultural — Indian',
    theme: 'indian',
    previewUrl: '',
    isPremium: true,
    isActive: true,
  ),
];

final _mockRsvps = [
  RsvpResponse(
    id: 'rsvp-001',
    invitationId: 'inv-001',
    guestName: 'Sarah & Tom Williams',
    attending: AttendingStatus.yes,
    guestCount: 2,
    mealPreference: 'Chicken',
    respondedAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  RsvpResponse(
    id: 'rsvp-002',
    invitationId: 'inv-001',
    guestName: 'Michael Chen',
    attending: AttendingStatus.yes,
    guestCount: 1,
    mealPreference: 'Vegetarian',
    respondedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  RsvpResponse(
    id: 'rsvp-003',
    invitationId: 'inv-001',
    guestName: 'Lisa Park',
    attending: AttendingStatus.no,
    guestCount: 0,
    message: 'So sorry, we have a prior commitment!',
    respondedAt: DateTime.now().subtract(const Duration(hours: 12)),
  ),
];
