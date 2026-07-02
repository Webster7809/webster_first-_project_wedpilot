import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vendor_profile.dart';
import '../models/messaging.dart';
import '../models/review.dart';
import 'auth_provider.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class VendorOwnState {
  final VendorProfile? profile;
  final List<VendorService> services;
  final List<VendorMedia> media;
  final List<Inquiry> inquiries;
  final List<Review> reviews;
  final Set<DateTime> blockedDates;
  final bool notificationsEnabled;
  final bool isSaving;

  const VendorOwnState({
    this.profile,
    this.services = const [],
    this.media = const [],
    this.inquiries = const [],
    this.reviews = const [],
    this.blockedDates = const {},
    this.notificationsEnabled = true,
    this.isSaving = false,
  });

  VendorOwnState copyWith({
    VendorProfile? profile,
    List<VendorService>? services,
    List<VendorMedia>? media,
    List<Inquiry>? inquiries,
    List<Review>? reviews,
    Set<DateTime>? blockedDates,
    bool? notificationsEnabled,
    bool? isSaving,
  }) => VendorOwnState(
        profile: profile ?? this.profile,
        services: services ?? this.services,
        media: media ?? this.media,
        inquiries: inquiries ?? this.inquiries,
        reviews: reviews ?? this.reviews,
        blockedDates: blockedDates ?? this.blockedDates,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        isSaving: isSaving ?? this.isSaving,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class VendorOwnNotifier extends StateNotifier<VendorOwnState> {
  VendorOwnNotifier(this._ref) : super(const VendorOwnState()) {
    final profile = _ref.read(vendorProfileProvider);
    if (profile != null) {
      state = VendorOwnState(
        profile: profile,
        services: List.of(profile.services),
        media: List.of(profile.media),
        inquiries: _mockInquiries(profile.id),
        reviews: _mockReviews(profile.id),
        notificationsEnabled: true,
      );
    }
  }

  final Ref _ref;

  // ── Profile ────────────────────────────────────────────────────────────────

  Future<void> saveProfile({
    String? description,
    String? phone,
    String? website,
    String? logoUrl,
  }) async {
    if (state.profile == null) return;
    state = state.copyWith(isSaving: true);
    await Future.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(
      isSaving: false,
      profile: state.profile!.copyWith(
        description: description,
        phone: phone,
        website: website,
        logoUrl: logoUrl,
      ),
    );
  }

  void updateNotifications(bool enabled) =>
      state = state.copyWith(notificationsEnabled: enabled);

  // ── Services ───────────────────────────────────────────────────────────────

  void addService(VendorService service) {
    final updated = [...state.services, service];
    state = state.copyWith(
      services: updated,
      profile: state.profile?.copyWith(services: updated),
    );
  }

  void updateService(VendorService updated) {
    final list = state.services.map((s) => s.id == updated.id ? updated : s).toList();
    state = state.copyWith(
      services: list,
      profile: state.profile?.copyWith(services: list),
    );
  }

  void deleteService(String id) {
    final list = state.services.where((s) => s.id != id).toList();
    state = state.copyWith(
      services: list,
      profile: state.profile?.copyWith(services: list),
    );
  }

  void toggleServiceActive(String id) {
    final list = state.services
        .map((s) => s.id == id ? s.copyWith(isActive: !s.isActive) : s)
        .toList();
    state = state.copyWith(
      services: list,
      profile: state.profile?.copyWith(services: list),
    );
  }

  // ── Media / Portfolio ──────────────────────────────────────────────────────

  void addMedia(VendorMedia item) {
    final list = [...state.media, item];
    state = state.copyWith(
      media: list,
      profile: state.profile?.copyWith(media: list),
    );
  }

  void deleteMedia(String id) {
    final list = state.media.where((m) => m.id != id).toList();
    state = state.copyWith(
      media: list,
      profile: state.profile?.copyWith(media: list),
    );
  }

  void toggleFeaturedMedia(String id) {
    final list = state.media
        .map((m) => m.copyWith(isFeatured: m.id == id))
        .toList();
    state = state.copyWith(
      media: list,
      profile: state.profile?.copyWith(media: list),
    );
  }

  // ── Availability ───────────────────────────────────────────────────────────

  void toggleBlockedDate(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    final set = Set<DateTime>.of(state.blockedDates);
    if (set.contains(normalized)) {
      set.remove(normalized);
    } else {
      set.add(normalized);
    }
    state = state.copyWith(blockedDates: set);
  }

  void persistBlockedDates() {
    // No-op — data already in state. Replace with real API call when backend is ready.
  }

  // ── Inquiries ──────────────────────────────────────────────────────────────

  void markInquiryStatus(String id, InquiryStatus status) {
    state = state.copyWith(
      inquiries: state.inquiries
          .map((i) => i.id == id ? _inquiryWithStatus(i, status) : i)
          .toList(),
    );
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final vendorOwnProvider =
    StateNotifierProvider<VendorOwnNotifier, VendorOwnState>(
  (ref) => VendorOwnNotifier(ref),
);

final vendorServicesProvider = Provider<List<VendorService>>(
  (ref) => ref.watch(vendorOwnProvider).services,
);

final vendorMediaProvider = Provider<List<VendorMedia>>(
  (ref) => ref.watch(vendorOwnProvider).media,
);

final vendorInquiriesProvider = Provider<List<Inquiry>>(
  (ref) => ref.watch(vendorOwnProvider).inquiries,
);

final vendorReviewsProvider = Provider<List<Review>>(
  (ref) => ref.watch(vendorOwnProvider).reviews,
);

final vendorBlockedDatesProvider = Provider<Set<DateTime>>(
  (ref) => ref.watch(vendorOwnProvider).blockedDates,
);

// ── Helpers ───────────────────────────────────────────────────────────────────

Inquiry _inquiryWithStatus(Inquiry i, InquiryStatus status) => Inquiry(
      id: i.id,
      coupleId: i.coupleId,
      vendorId: i.vendorId,
      coupleName: i.coupleName,
      vendorName: i.vendorName,
      status: status,
      budgetRangeMin: i.budgetRangeMin,
      budgetRangeMax: i.budgetRangeMax,
      weddingDate: i.weddingDate,
      message: i.message,
      respondedAt: i.respondedAt,
      createdAt: i.createdAt,
    );

// ── Mock seed data ─────────────────────────────────────────────────────────────

List<Inquiry> _mockInquiries(String vendorId) => [
      Inquiry(
        id: 'inq-001',
        coupleId: 'profile-001',
        vendorId: vendorId,
        coupleName: 'Chanda & Mutale',
        status: InquiryStatus.newInquiry,
        budgetRangeMin: 20000,
        budgetRangeMax: 35000,
        weddingDate: DateTime(2027, 8, 14),
        message: 'Hi! We love your garden venue and would like to inquire about availability for our wedding.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Inquiry(
        id: 'inq-002',
        coupleId: 'profile-002',
        vendorId: vendorId,
        coupleName: 'Nkemba & Lweendo',
        status: InquiryStatus.newInquiry,
        budgetRangeMin: 25000,
        budgetRangeMax: 40000,
        weddingDate: DateTime(2027, 11, 22),
        message: 'We are planning a garden wedding for about 200 guests. Is your venue available?',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      Inquiry(
        id: 'inq-003',
        coupleId: 'profile-003',
        vendorId: vendorId,
        coupleName: 'Tawonga & Bupe',
        status: InquiryStatus.responded,
        budgetRangeMin: 15000,
        budgetRangeMax: 28000,
        weddingDate: DateTime(2027, 4, 10),
        message: 'Do you offer indoor and garden combo packages? Our guest count is around 150.',
        respondedAt: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Inquiry(
        id: 'inq-004',
        coupleId: 'profile-004',
        vendorId: vendorId,
        coupleName: 'Monde & Kafula',
        status: InquiryStatus.booked,
        budgetRangeMin: 30000,
        budgetRangeMax: 45000,
        weddingDate: DateTime(2027, 2, 14),
        message: 'We would like to book the open air garden for Valentine\'s Day. Please confirm.',
        respondedAt: DateTime.now().subtract(const Duration(days: 3)),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Inquiry(
        id: 'inq-005',
        coupleId: 'profile-005',
        vendorId: vendorId,
        coupleName: 'Mirriam & Chisomo',
        status: InquiryStatus.viewed,
        weddingDate: DateTime(2027, 9, 5),
        message: 'Can we schedule a site visit? We are very interested in your venue.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

List<Review> _mockReviews(String vendorId) => [
      Review(
        id: 'rev-001',
        coupleId: 'profile-001',
        vendorId: vendorId,
        coupleName: 'Thandiwe & Chisomo',
        rating: 5,
        title: 'Absolutely stunning venue!',
        body: 'Mukuba Gardens exceeded all our expectations. The garden setting was magical and the staff were incredibly attentive throughout our entire wedding day. Every guest complimented the venue.',
        status: ReviewStatus.approved,
        publishedAt: DateTime.now().subtract(const Duration(days: 14)),
        createdAt: DateTime.now().subtract(const Duration(days: 16)),
      ),
      Review(
        id: 'rev-002',
        coupleId: 'profile-002',
        vendorId: vendorId,
        coupleName: 'Bupe & Mwila',
        rating: 5,
        title: 'Perfect for a garden wedding',
        body: 'We had 250 guests and the venue handled everything seamlessly. The open air package gave us the outdoor feel we wanted while keeping everyone comfortable.',
        status: ReviewStatus.approved,
        publishedAt: DateTime.now().subtract(const Duration(days: 30)),
        createdAt: DateTime.now().subtract(const Duration(days: 32)),
      ),
      Review(
        id: 'rev-003',
        coupleId: 'profile-003',
        vendorId: vendorId,
        coupleName: 'Natasha & Kelvin',
        rating: 5,
        title: 'Highly recommend!',
        body: 'From the first site visit to our wedding day, the team was professional and warm. The garden looks even better in person than in photos.',
        status: ReviewStatus.approved,
        publishedAt: DateTime.now().subtract(const Duration(days: 45)),
        createdAt: DateTime.now().subtract(const Duration(days: 47)),
      ),
      Review(
        id: 'rev-004',
        coupleId: 'profile-004',
        vendorId: vendorId,
        coupleName: 'Grace & Luckson',
        rating: 4,
        title: 'Beautiful venue, minor hiccups',
        body: 'The venue itself is gorgeous and the team very helpful. We had a slight delay during setup but it was resolved quickly. Overall a wonderful experience.',
        status: ReviewStatus.approved,
        publishedAt: DateTime.now().subtract(const Duration(days: 60)),
        createdAt: DateTime.now().subtract(const Duration(days: 62)),
      ),
      Review(
        id: 'rev-005',
        coupleId: 'profile-005',
        vendorId: vendorId,
        coupleName: 'Loveness & Dickson',
        rating: 5,
        title: 'Dream wedding achieved!',
        body: 'I cannot speak highly enough of Mukuba Gardens. Our guests are still talking about how beautiful the venue was. Worth every kwacha.',
        status: ReviewStatus.approved,
        publishedAt: DateTime.now().subtract(const Duration(days: 90)),
        createdAt: DateTime.now().subtract(const Duration(days: 92)),
      ),
    ];
