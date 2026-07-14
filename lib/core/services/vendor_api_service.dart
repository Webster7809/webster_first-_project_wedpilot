import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';

import '../../models/vendor_profile.dart';
import '../../models/vendor_feedback.dart';
import '../../models/messaging.dart' show Inquiry;

// Flutter never touches the database directly.
// All calls go through the Node/Express backend at [_baseUrl].
// Change [_backendPort] or [_lanHost] when deploying to production.
const int _backendPort = 3000;

// Set this to your machine's LAN IP (e.g. '192.168.1.20') when testing on a
// physical device, since 'localhost' on the device refers to the device itself.
const String? _lanHost = null;

String get _baseUrl {
  if (_lanHost != null) return 'http://$_lanHost:$_backendPort';
  if (kIsWeb) return 'http://localhost:$_backendPort';
  if (Platform.isAndroid) return 'http://10.0.2.2:$_backendPort'; // Android emulator → host localhost
  return 'http://localhost:$_backendPort'; // iOS simulator, desktop
}

/// Resolves a stored relative upload path (e.g. '/uploads/vendors/x.jpg') to
/// an absolute URL. Already-absolute URLs are returned unchanged.
String resolveMediaUrl(String urlOrPath) =>
    urlOrPath.startsWith('http') ? urlOrPath : '$_baseUrl$urlOrPath';

class VendorApiException implements Exception {
  final String message;
  const VendorApiException(this.message);
}

class VendorRevenue {
  final double thisMonth;
  final double lastMonth;
  final double yearToDate;
  const VendorRevenue({required this.thisMonth, required this.lastMonth, required this.yearToDate});
}

class VendorApiService {
  VendorApiService._();
  static final VendorApiService instance = VendorApiService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));

  Options _auth(String accessToken) =>
      Options(headers: {'Authorization': 'Bearer $accessToken'});

  // ── Directory ────────────────────────────────────────────────────────────────

  Future<List<VendorProfile>> fetchVendors(
    String accessToken, {
    String? category,
    String? location,
    String? search,
    double? priceMin,
    double? priceMax,
    bool? verifiedOnly,
    int? limit,
    int? offset,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/vendors',
        queryParameters: {
          'category': ?category,
          'location': ?location,
          'search': ?search,
          'price_min': ?priceMin,
          'price_max': ?priceMax,
          if (verifiedOnly == true) 'verified': 'true',
          'limit': ?limit,
          'offset': ?offset,
        },
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return (data['vendors'] as List<dynamic>? ?? [])
          .map((v) => VendorProfile.fromJson(v as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw VendorApiException(_extractError(e));
    }
  }

  /// Pages through the *entire* directory instead of just the first 20
  /// results — [fetchVendors] alone silently caps at the backend's default
  /// page size (see routes/vendors.js), so any caller that needs to reason
  /// about the whole vendor pool (e.g. the wedding-plan AI matcher, which
  /// must see every category's vendors to score them) has to go through this
  /// instead, or it silently starves whichever categories fall past page 1.
  Future<List<VendorProfile>> fetchAllVendors(
    String accessToken, {
    String? category,
    String? location,
    bool? verifiedOnly,
  }) async {
    const pageSize = 100; // backend's hard cap, see routes/vendors.js
    final all = <VendorProfile>[];
    var offset = 0;
    while (true) {
      final page = await fetchVendors(
        accessToken,
        category: category,
        location: location,
        verifiedOnly: verifiedOnly,
        limit: pageSize,
        offset: offset,
      );
      all.addAll(page);
      if (page.length < pageSize) break;
      offset += pageSize;
    }
    return all;
  }

  Future<VendorProfile> fetchVendorDetail(String accessToken, String vendorId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/vendors/$vendorId',
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return VendorProfile.fromJson(data['vendor'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw VendorApiException(_extractError(e));
    }
  }

  // ── Own profile ──────────────────────────────────────────────────────────────

  /// Returns `null` if the vendor hasn't saved a profile yet (404 — expected).
  Future<VendorProfile?> fetchMyProfile(String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/vendors/me',
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return VendorProfile.fromJson(data['vendor'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw VendorApiException(_extractError(e));
    }
  }

  Future<VendorProfile> saveMyProfile(
    String accessToken, {
    required String businessName,
    required String category,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? styleTags,
    String? logoUrl,
    String? phone,
    String? website,
    String? whatsapp,
    String? contactEmail,
    String? address,
    String? instagramHandle,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/vendors/me',
        data: {
          'business_name': businessName,
          'category': category,
          'description': description,
          'location': location,
          'latitude': latitude,
          'longitude': longitude,
          'style_tags': styleTags,
          'logo_url': logoUrl,
          'phone': phone,
          'website': website,
          'whatsapp': whatsapp,
          'contact_email': contactEmail,
          'address': address,
          'instagram_handle': instagramHandle,
        },
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return VendorProfile.fromJson(data['vendor'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw VendorApiException(_extractError(e));
    }
  }

  Future<VendorProfile> removeLogo(String accessToken) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/api/vendors/me/logo',
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return VendorProfile.fromJson(data['vendor'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw VendorApiException(_extractError(e));
    }
  }

  // ── Services ─────────────────────────────────────────────────────────────────

  Future<VendorService> createService(String accessToken, VendorService service) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/vendors/me/services',
        data: {
          'title': service.title,
          'description': service.description,
          'price_min': service.priceMin,
          'price_max': service.priceMax,
          'unit': service.unit,
        },
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return VendorService.fromJson(data['service'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw VendorApiException(_extractError(e));
    }
  }

  Future<VendorService> updateService(String accessToken, VendorService service) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/vendors/me/services/${service.id}',
        data: {
          'title': service.title,
          'description': service.description,
          'price_min': service.priceMin,
          'price_max': service.priceMax,
          'unit': service.unit,
          'is_active': service.isActive,
        },
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return VendorService.fromJson(data['service'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw VendorApiException(_extractError(e));
    }
  }

  Future<void> deleteService(String accessToken, String serviceId) async {
    try {
      await _dio.delete('/api/vendors/me/services/$serviceId', options: _auth(accessToken));
    } on DioException catch (e) {
      throw VendorApiException(_extractError(e));
    }
  }

  // ── Media ────────────────────────────────────────────────────────────────────

  Future<VendorMedia> uploadMedia(
    String accessToken, {
    required Uint8List bytes,
    required String filename,
    bool isFeatured = false,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
        'is_featured': isFeatured,
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/vendors/me/media',
        data: form,
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return VendorMedia.fromJson(data['media'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw VendorApiException(_extractError(e));
    }
  }

  Future<void> deleteMedia(String accessToken, String mediaId) async {
    try {
      await _dio.delete('/api/vendors/me/media/$mediaId', options: _auth(accessToken));
    } on DioException catch (e) {
      throw VendorApiException(_extractError(e));
    }
  }

  Future<VendorMedia> toggleFeaturedMedia(String accessToken, String mediaId) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/vendors/me/media/$mediaId/featured',
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return VendorMedia.fromJson(data['media'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw VendorApiException(_extractError(e));
    }
  }

  // ── Blocked dates ────────────────────────────────────────────────────────────

  Future<List<String>> setBlockedDates(String accessToken, List<String> dates) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/vendors/me/blocked-dates',
        data: {'dates': dates},
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return List<String>.from(data['blocked_dates'] ?? []);
    } on DioException catch (e) {
      throw VendorApiException(_extractError(e));
    }
  }

  // ── Inquiries ────────────────────────────────────────────────────────────────

  Future<List<Inquiry>> fetchMyInquiries(String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/vendors/me/inquiries',
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return (data['inquiries'] as List<dynamic>? ?? [])
          .map((i) => Inquiry.fromJson(i as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw VendorApiException(_extractError(e));
    }
  }

  Future<Inquiry> updateInquiryStatus(
    String accessToken,
    String inquiryId,
    String status, {
    String? declineReason,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/vendors/me/inquiries/$inquiryId',
        data: {
          'status': status,
          'decline_reason': ?declineReason,
        },
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return Inquiry.fromJson(data['inquiry'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw VendorApiException(_extractError(e));
    }
  }

  Future<Inquiry> markServiceDone(String accessToken, String inquiryId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/vendors/me/inquiries/$inquiryId/service-done',
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return Inquiry.fromJson(data['inquiry'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw VendorApiException(_extractError(e));
    }
  }

  /// The couple-facing counterpart to [fetchMyInquiries] — their own sent
  /// booking requests, with status/decline-reason/rating eligibility.
  Future<List<Inquiry>> fetchMyBookings(String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/vendors/inquiries/mine',
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return (data['inquiries'] as List<dynamic>? ?? [])
          .map((i) => Inquiry.fromJson(i as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw VendorApiException(_extractError(e));
    }
  }

  Future<Inquiry> sendInquiry(
    String accessToken,
    String vendorId, {
    required String message,
    double? budgetRangeMin,
    double? budgetRangeMax,
    DateTime? weddingDate,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/vendors/$vendorId/inquiries',
        data: {
          'message': message,
          'budget_range_min': budgetRangeMin,
          'budget_range_max': budgetRangeMax,
          'wedding_date': weddingDate?.toIso8601String(),
        },
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return Inquiry.fromJson(data['inquiry'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw VendorApiException(_extractError(e));
    }
  }

  // ── Feedback (private) ──────────────────────────────────────────────────────

  /// Restricted server-side to the vendor's own feedback or an admin — used
  /// both by the vendor's private dashboard (with its own vendor id) and any
  /// future admin drill-in.
  Future<List<VendorFeedback>> fetchVendorFeedback(String accessToken, String vendorId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/vendors/$vendorId/feedback',
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return (data['feedback'] as List<dynamic>? ?? [])
          .map((f) => VendorFeedback.fromJson(f as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw VendorApiException(_extractError(e));
    }
  }

  Future<void> reportMedia(
    String accessToken,
    String mediaId, {
    required String reason,
  }) async {
    try {
      await _dio.post(
        '/api/vendors/media/$mediaId/report',
        data: {'reason': reason},
        options: _auth(accessToken),
      );
    } on DioException catch (e) {
      throw VendorApiException(_extractError(e));
    }
  }

  Future<VendorFeedback> submitFeedback(
    String accessToken,
    String vendorId, {
    required int starRating,
    String? comment,
    OnTimeAnswer? onTime,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/vendors/$vendorId/feedback',
        data: {
          'star_rating': starRating,
          'comment': comment,
          'on_time': onTime == null ? null : onTimeToWire(onTime),
        },
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return VendorFeedback.fromJson(data['feedback'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw VendorApiException(_extractError(e));
    }
  }

  // ── Revenue ──────────────────────────────────────────────────────────────────

  Future<VendorRevenue> fetchMyRevenue(String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/vendors/me/revenue',
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return VendorRevenue(
        thisMonth: (data['this_month'] as num? ?? 0).toDouble(),
        lastMonth: (data['last_month'] as num? ?? 0).toDouble(),
        yearToDate: (data['year_to_date'] as num? ?? 0).toDouble(),
      );
    } on DioException catch (e) {
      throw VendorApiException(_extractError(e));
    }
  }

  // ── Wishlist ─────────────────────────────────────────────────────────────────

  Future<List<String>> fetchWishlist(String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/wishlist',
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return List<String>.from(data['vendor_ids'] ?? []);
    } on DioException catch (e) {
      throw VendorApiException(_extractError(e));
    }
  }

  Future<void> addToWishlist(String accessToken, String vendorId) async {
    try {
      await _dio.post('/api/wishlist', data: {'vendor_id': vendorId}, options: _auth(accessToken));
    } on DioException catch (e) {
      throw VendorApiException(_extractError(e));
    }
  }

  Future<void> removeFromWishlist(String accessToken, String vendorId) async {
    try {
      await _dio.delete('/api/wishlist/$vendorId', options: _auth(accessToken));
    } on DioException catch (e) {
      throw VendorApiException(_extractError(e));
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return 'Could not reach the server. Please try again.';
  }
}
