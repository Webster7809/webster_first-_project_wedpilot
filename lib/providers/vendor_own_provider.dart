import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vendor_profile.dart';
import '../models/messaging.dart';
import '../models/review.dart';
import '../core/services/vendor_api_service.dart';
import '../core/state/resource.dart';
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

Set<DateTime> _parseBlockedDates(List<String> raw) => raw
    .map((s) => DateTime.tryParse(s))
    .whereType<DateTime>()
    .map((d) => DateTime(d.year, d.month, d.day))
    .toSet();

List<String> _formatBlockedDates(Set<DateTime> dates) =>
    dates.map((d) => d.toIso8601String().split('T').first).toList();

// ── Notifier ──────────────────────────────────────────────────────────────────

class VendorOwnNotifier extends StateNotifier<Resource<VendorOwnState>> {
  VendorOwnNotifier(this._ref) : super(const Resource());

  final Ref _ref;
  final VendorApiService _service = VendorApiService.instance;

  String? get _token => _ref.read(authProvider.notifier).accessToken;

  // ── Load ─────────────────────────────────────────────────────────────────────

  Future<void> loadOwnVendorData() async {
    final token = _token;
    if (token == null) {
      state = state.copyWith(status: ResourceStatus.error, errorMessage: 'Not signed in.');
      return;
    }
    state = state.copyWith(status: ResourceStatus.loading);
    try {
      final profile = await _service.fetchMyProfile(token);
      if (profile == null) {
        // Vendor hasn't completed onboarding yet — a genuinely empty state,
        // not an error.
        state = state.copyWith(status: ResourceStatus.ready, data: const VendorOwnState());
        return;
      }
      final results = await Future.wait([
        _service.fetchMyInquiries(token),
        _service.fetchMyReviews(token),
      ]);
      final data = VendorOwnState(
        profile: profile,
        services: profile.services,
        media: profile.media,
        inquiries: results[0] as List<Inquiry>,
        reviews: results[1] as List<Review>,
        blockedDates: _parseBlockedDates(profile.blockedDates),
      );
      _ref.read(authProvider.notifier).setVendorProfile(profile);
      state = state.copyWith(status: ResourceStatus.ready, data: data);
    } on VendorApiException catch (e) {
      state = state.copyWith(status: ResourceStatus.error, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        status: ResourceStatus.error,
        errorMessage: 'Could not reach the server. Please try again.',
      );
    }
  }

  // ── Profile ────────────────────────────────────────────────────────────────

  /// Creates the vendor's profile for the first time (onboarding submission).
  /// Unlike [saveProfile], this doesn't require existing state to merge with.
  Future<String?> createProfile({
    required String businessName,
    required String category,
    String? description,
    String? location,
    String? phone,
    String? whatsapp,
    String? contactEmail,
    String? address,
    String? instagramHandle,
  }) async {
    final token = _token;
    if (token == null) return 'Not signed in.';
    try {
      final saved = await _service.saveMyProfile(
        token,
        businessName: businessName,
        category: category,
        description: description,
        location: location,
        styleTags: const [],
        phone: phone,
        whatsapp: whatsapp,
        contactEmail: contactEmail,
        address: address,
        instagramHandle: instagramHandle,
      );
      _ref.read(authProvider.notifier).setVendorProfile(saved);
      state = state.copyWith(
        status: ResourceStatus.ready,
        data: VendorOwnState(profile: saved, services: saved.services, media: saved.media),
      );
      return null;
    } on VendorApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Please try again.';
    }
  }

  Future<String?> saveProfile({
    String? description,
    String? phone,
    String? website,
    String? whatsapp,
    String? contactEmail,
    String? address,
    String? instagramHandle,
    String? logoUrl,
  }) async {
    final current = state.data?.profile;
    if (current == null) return 'No vendor profile yet.';
    final token = _token;
    if (token == null) return 'Not signed in.';

    state = state.copyWith(data: state.data!.copyWith(isSaving: true));
    try {
      final saved = await _service.saveMyProfile(
        token,
        businessName: current.businessName,
        category: current.category,
        description: description ?? current.description,
        location: current.location,
        latitude: current.latitude,
        longitude: current.longitude,
        styleTags: current.styleTags,
        logoUrl: logoUrl ?? current.logoUrl,
        phone: phone ?? current.phone,
        website: website ?? current.website,
        whatsapp: whatsapp ?? current.whatsapp,
        contactEmail: contactEmail ?? current.contactEmail,
        address: address ?? current.address,
        instagramHandle: instagramHandle ?? current.instagramHandle,
      );
      _ref.read(authProvider.notifier).setVendorProfile(saved);
      state = state.copyWith(
        data: state.data!.copyWith(
          isSaving: false,
          profile: saved,
          services: saved.services,
          media: saved.media,
        ),
      );
      return null;
    } on VendorApiException catch (e) {
      state = state.copyWith(data: state.data!.copyWith(isSaving: false));
      return e.message;
    } catch (_) {
      state = state.copyWith(data: state.data!.copyWith(isSaving: false));
      return 'Could not reach the server. Please try again.';
    }
  }

  /// Uploads a new logo image and saves it as the profile's logoUrl.
  Future<String?> uploadLogo(Uint8List bytes, String filename) async {
    final token = _token;
    if (token == null) return 'Not signed in.';
    try {
      final media = await _service.uploadMedia(token, bytes: bytes, filename: filename);
      return saveProfile(logoUrl: media.url);
    } on VendorApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Please try again.';
    }
  }

  void updateNotifications(bool enabled) {
    final current = state.data;
    if (current == null) return;
    state = state.copyWith(data: current.copyWith(notificationsEnabled: enabled));
  }

  // ── Services ───────────────────────────────────────────────────────────────

  Future<String?> addService(VendorService service) async {
    final token = _token;
    if (token == null) return 'Not signed in.';
    final current = state.data;
    if (current == null) return 'No vendor profile yet.';
    try {
      final created = await _service.createService(token, service);
      state = state.copyWith(data: current.copyWith(services: [...current.services, created]));
      return null;
    } on VendorApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Please try again.';
    }
  }

  Future<String?> updateService(VendorService updated) async {
    final token = _token;
    if (token == null) return 'Not signed in.';
    final current = state.data;
    if (current == null) return 'No vendor profile yet.';
    try {
      final saved = await _service.updateService(token, updated);
      state = state.copyWith(
        data: current.copyWith(
          services: current.services.map((s) => s.id == saved.id ? saved : s).toList(),
        ),
      );
      return null;
    } on VendorApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Please try again.';
    }
  }

  Future<String?> deleteService(String id) async {
    final token = _token;
    if (token == null) return 'Not signed in.';
    final current = state.data;
    if (current == null) return 'No vendor profile yet.';
    try {
      await _service.deleteService(token, id);
      state = state.copyWith(
        data: current.copyWith(services: current.services.where((s) => s.id != id).toList()),
      );
      return null;
    } on VendorApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Please try again.';
    }
  }

  Future<String?> toggleServiceActive(String id) async {
    final current = state.data;
    if (current == null) return 'No vendor profile yet.';
    final existing = current.services.where((s) => s.id == id).firstOrNull;
    if (existing == null) return 'Service not found.';
    return updateService(existing.copyWith(isActive: !existing.isActive));
  }

  // ── Media / Portfolio ──────────────────────────────────────────────────────

  Future<String?> addMedia(Uint8List bytes, String filename, {bool isFeatured = false}) async {
    final token = _token;
    if (token == null) return 'Not signed in.';
    final current = state.data;
    if (current == null) return 'No vendor profile yet.';
    try {
      final created = await _service.uploadMedia(token, bytes: bytes, filename: filename, isFeatured: isFeatured);
      state = state.copyWith(data: current.copyWith(media: [...current.media, created]));
      return null;
    } on VendorApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Please try again.';
    }
  }

  Future<String?> deleteMedia(String id) async {
    final token = _token;
    if (token == null) return 'Not signed in.';
    final current = state.data;
    if (current == null) return 'No vendor profile yet.';
    try {
      await _service.deleteMedia(token, id);
      state = state.copyWith(data: current.copyWith(media: current.media.where((m) => m.id != id).toList()));
      return null;
    } on VendorApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Please try again.';
    }
  }

  Future<String?> toggleFeaturedMedia(String id) async {
    final token = _token;
    if (token == null) return 'Not signed in.';
    final current = state.data;
    if (current == null) return 'No vendor profile yet.';
    try {
      final updated = await _service.toggleFeaturedMedia(token, id);
      state = state.copyWith(
        data: current.copyWith(
          media: current.media.map((m) => m.id == id ? updated : m).toList(),
        ),
      );
      return null;
    } on VendorApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Please try again.';
    }
  }

  // ── Availability ───────────────────────────────────────────────────────────

  void toggleBlockedDate(DateTime day) {
    final current = state.data;
    if (current == null) return;
    final normalized = DateTime(day.year, day.month, day.day);
    final set = Set<DateTime>.of(current.blockedDates);
    if (set.contains(normalized)) {
      set.remove(normalized);
    } else {
      set.add(normalized);
    }
    state = state.copyWith(data: current.copyWith(blockedDates: set));
  }

  Future<String?> persistBlockedDates() async {
    final token = _token;
    if (token == null) return 'Not signed in.';
    final current = state.data;
    if (current == null) return 'No vendor profile yet.';
    try {
      await _service.setBlockedDates(token, _formatBlockedDates(current.blockedDates));
      return null;
    } on VendorApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Please try again.';
    }
  }

  // ── Inquiries ──────────────────────────────────────────────────────────────

  Future<String?> markInquiryStatus(String id, InquiryStatus status) async {
    final token = _token;
    if (token == null) return 'Not signed in.';
    final current = state.data;
    if (current == null) return 'No vendor profile yet.';
    try {
      final updated = await _service.updateInquiryStatus(token, id, status.name);
      state = state.copyWith(
        data: current.copyWith(
          inquiries: current.inquiries.map((i) => i.id == id ? updated : i).toList(),
        ),
      );
      return null;
    } on VendorApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Please try again.';
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final vendorOwnProvider =
    StateNotifierProvider<VendorOwnNotifier, Resource<VendorOwnState>>(
  (ref) => VendorOwnNotifier(ref),
);

final vendorOwnProfileProvider = Provider<VendorProfile?>(
  (ref) => ref.watch(vendorOwnProvider).data?.profile,
);

final vendorServicesProvider = Provider<List<VendorService>>(
  (ref) => ref.watch(vendorOwnProvider).data?.services ?? [],
);

final vendorMediaProvider = Provider<List<VendorMedia>>(
  (ref) => ref.watch(vendorOwnProvider).data?.media ?? [],
);

final vendorInquiriesProvider = Provider<List<Inquiry>>(
  (ref) => ref.watch(vendorOwnProvider).data?.inquiries ?? [],
);

final vendorReviewsProvider = Provider<List<Review>>(
  (ref) => ref.watch(vendorOwnProvider).data?.reviews ?? [],
);

final vendorBlockedDatesProvider = Provider<Set<DateTime>>(
  (ref) => ref.watch(vendorOwnProvider).data?.blockedDates ?? {},
);

/// Real revenue aggregate from confirmed expenses linked to this vendor.
/// Reads as zero until couples' expense entries are tied to a vendor id
/// (there's no vendor picker in the expense form yet) — an honest empty
/// state rather than a fabricated figure.
final vendorRevenueProvider = FutureProvider<VendorRevenue>((ref) async {
  final token = ref.watch(authProvider.notifier).accessToken;
  if (token == null) {
    return const VendorRevenue(thisMonth: 0, lastMonth: 0, yearToDate: 0);
  }
  return VendorApiService.instance.fetchMyRevenue(token);
});
