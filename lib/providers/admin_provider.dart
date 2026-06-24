import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class AdminVendor {
  final String id;
  final String name;
  final String category;
  final String submitted;
  final int docs;
  final String email;
  final String phone;
  final String location;

  const AdminVendor({
    required this.id,
    required this.name,
    required this.category,
    required this.submitted,
    required this.docs,
    required this.email,
    required this.phone,
    required this.location,
  });
}

class AdminUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String joined;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.joined,
  });

  bool get isSuspended => status == 'suspended';

  AdminUser copyWith({String? status}) => AdminUser(
        id: id,
        name: name,
        email: email,
        role: role,
        status: status ?? this.status,
        joined: joined,
      );
}

class FlaggedReview {
  final String id;
  final String vendor;
  final int rating;
  final String text;
  final String flagReason;

  const FlaggedReview({
    required this.id,
    required this.vendor,
    required this.rating,
    required this.text,
    required this.flagReason,
  });
}

class FlaggedImage {
  final String id;
  final String vendor;
  final String category;
  final String flagReason;

  const FlaggedImage({
    required this.id,
    required this.vendor,
    required this.category,
    required this.flagReason,
  });
}

class FlaggedMessage {
  final String id;
  final String sender;
  final String recipient;
  final String excerpt;
  final String flagReason;

  const FlaggedMessage({
    required this.id,
    required this.sender,
    required this.recipient,
    required this.excerpt,
    required this.flagReason,
  });
}

// ── State ─────────────────────────────────────────────────────────────────────

class AdminState {
  final List<AdminVendor> pendingVendors;
  final List<AdminUser> users;
  final List<FlaggedReview> flaggedReviews;
  final List<FlaggedImage> flaggedImages;
  final List<FlaggedMessage> flaggedMessages;

  const AdminState({
    required this.pendingVendors,
    required this.users,
    required this.flaggedReviews,
    required this.flaggedImages,
    required this.flaggedMessages,
  });

  int get totalFlaggedItems =>
      flaggedReviews.length + flaggedImages.length + flaggedMessages.length;

  AdminState copyWith({
    List<AdminVendor>? pendingVendors,
    List<AdminUser>? users,
    List<FlaggedReview>? flaggedReviews,
    List<FlaggedImage>? flaggedImages,
    List<FlaggedMessage>? flaggedMessages,
  }) =>
      AdminState(
        pendingVendors: pendingVendors ?? this.pendingVendors,
        users: users ?? this.users,
        flaggedReviews: flaggedReviews ?? this.flaggedReviews,
        flaggedImages: flaggedImages ?? this.flaggedImages,
        flaggedMessages: flaggedMessages ?? this.flaggedMessages,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AdminNotifier extends StateNotifier<AdminState> {
  AdminNotifier() : super(_initialAdminState);

  void approveVendor(String id) => state = state.copyWith(
        pendingVendors: state.pendingVendors.where((v) => v.id != id).toList(),
      );

  void rejectVendor(String id) => state = state.copyWith(
        pendingVendors: state.pendingVendors.where((v) => v.id != id).toList(),
      );

  void toggleSuspendUser(String id) => state = state.copyWith(
        users: state.users
            .map((u) => u.id == id
                ? u.copyWith(status: u.isSuspended ? 'active' : 'suspended')
                : u)
            .toList(),
      );

  void deleteUser(String id) => state = state.copyWith(
        users: state.users.where((u) => u.id != id).toList(),
      );

  void approveReview(String id) => state = state.copyWith(
        flaggedReviews:
            state.flaggedReviews.where((r) => r.id != id).toList(),
      );

  void rejectReview(String id) => state = state.copyWith(
        flaggedReviews:
            state.flaggedReviews.where((r) => r.id != id).toList(),
      );

  void approveImage(String id) => state = state.copyWith(
        flaggedImages:
            state.flaggedImages.where((img) => img.id != id).toList(),
      );

  void rejectImage(String id) => state = state.copyWith(
        flaggedImages:
            state.flaggedImages.where((img) => img.id != id).toList(),
      );

  void approveMessage(String id) => state = state.copyWith(
        flaggedMessages:
            state.flaggedMessages.where((m) => m.id != id).toList(),
      );

  void rejectMessage(String id) => state = state.copyWith(
        flaggedMessages:
            state.flaggedMessages.where((m) => m.id != id).toList(),
      );
}

final adminProvider =
    StateNotifierProvider<AdminNotifier, AdminState>((ref) => AdminNotifier());

// ── Seed data ─────────────────────────────────────────────────────────────────

const _initialAdminState = AdminState(
  pendingVendors: [
    AdminVendor(
      id: 'v1',
      name: 'Kalulushi Hall',
      category: 'Venue',
      submitted: '2h ago',
      docs: 3,
      email: 'info@kalululushihall.co.zm',
      phone: '+260 97 123 4567',
      location: 'Kalulushi',
    ),
    AdminVendor(
      id: 'v2',
      name: 'Bemba Bridal Wear',
      category: 'Attire',
      submitted: '5h ago',
      docs: 2,
      email: 'hello@bembabridalwear.co.zm',
      phone: '+260 96 234 5678',
      location: 'Lusaka',
    ),
    AdminVendor(
      id: 'v3',
      name: 'Twin Palms Transport',
      category: 'Transport',
      submitted: '1 day ago',
      docs: 4,
      email: 'info@twinpalms.co.zm',
      phone: '+260 95 345 6789',
      location: 'Ndola',
    ),
  ],
  users: [
    AdminUser(
      id: 'u1',
      name: 'Alex & Jordan',
      email: 'alex@example.com',
      role: 'couple',
      status: 'active',
      joined: '2 days ago',
    ),
    AdminUser(
      id: 'u2',
      name: 'Blossom Photography',
      email: 'blossom@example.com',
      role: 'vendor',
      status: 'active',
      joined: '1 week ago',
    ),
    AdminUser(
      id: 'u3',
      name: 'Emma & Noah',
      email: 'emma@example.com',
      role: 'couple',
      status: 'active',
      joined: '3 days ago',
    ),
    AdminUser(
      id: 'u4',
      name: 'Garden Venue',
      email: 'garden@example.com',
      role: 'vendor',
      status: 'suspended',
      joined: '1 month ago',
    ),
    AdminUser(
      id: 'u5',
      name: 'Sarah Mitchell',
      email: 'sarah@example.com',
      role: 'admin',
      status: 'active',
      joined: '6 months ago',
    ),
  ],
  flaggedReviews: [
    FlaggedReview(
      id: 'r1',
      vendor: 'Blossom Photography',
      rating: 1,
      text: 'Terrible service, would not recommend to anyone.',
      flagReason: 'Spam',
    ),
    FlaggedReview(
      id: 'r2',
      vendor: 'The Garden Venue',
      rating: 2,
      text: 'They canceled on us last minute with no refund.',
      flagReason: 'Dispute',
    ),
  ],
  flaggedImages: [
    FlaggedImage(
      id: 'i1',
      vendor: 'Sunrise Events',
      category: 'Venue',
      flagReason: 'Inappropriate content',
    ),
    FlaggedImage(
      id: 'i2',
      vendor: 'Petal Dreams',
      category: 'Floristry',
      flagReason: 'Copyright violation',
    ),
    FlaggedImage(
      id: 'i3',
      vendor: 'Cake by Sofia',
      category: 'Cake',
      flagReason: 'Low quality',
    ),
  ],
  flaggedMessages: [
    FlaggedMessage(
      id: 'm1',
      sender: 'user_123',
      recipient: 'Blossom Photography',
      excerpt: 'This message contains prohibited content keywords.',
      flagReason: 'Prohibited keywords',
    ),
  ],
);
