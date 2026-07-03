import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';

// All AI calls (Groq-backed) go through the Node/Express backend at [_baseUrl].
// Flutter never touches the LLM API key.
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

class WeddingPlanResult {
  final String planSummary;
  final Map<String, double> budgetAdvice;
  final Map<String, String> vendorReasonings;

  const WeddingPlanResult({
    required this.planSummary,
    required this.budgetAdvice,
    required this.vendorReasonings,
  });
}

/// A vendor candidate sent to the AI matcher, carrying precomputed 0-1
/// signal scores (reputation/location/value) as grounding for its judgement.
class VendorMatchCandidate {
  final String vendorId;
  final String businessName;
  final String? location;
  final List<String> styleTags;
  final double? rating;
  final int reviewCount;
  final String priceTier;
  final double priceMin;
  final double priceMax;
  final double reputationScore;
  final double locationScore;
  final double valueScore;

  const VendorMatchCandidate({
    required this.vendorId,
    required this.businessName,
    this.location,
    this.styleTags = const [],
    this.rating,
    this.reviewCount = 0,
    required this.priceTier,
    required this.priceMin,
    required this.priceMax,
    required this.reputationScore,
    required this.locationScore,
    required this.valueScore,
  });

  Map<String, dynamic> toJson() => {
        'vendorId': vendorId,
        'businessName': businessName,
        'location': location,
        'styleTags': styleTags,
        'rating': rating,
        'reviewCount': reviewCount,
        'priceTier': priceTier,
        'priceMin': priceMin,
        'priceMax': priceMax,
        'reputationScore': reputationScore,
        'locationScore': locationScore,
        'valueScore': valueScore,
      };
}

/// The AI's single top pick for one vendor category.
class VendorMatchSuggestion {
  final String vendorId;
  final double confidence;
  final String reasoning;

  const VendorMatchSuggestion({
    required this.vendorId,
    required this.confidence,
    required this.reasoning,
  });

  factory VendorMatchSuggestion.fromJson(Map<String, dynamic> json) =>
      VendorMatchSuggestion(
        vendorId: json['vendorId'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        reasoning: json['reasoning'] as String? ?? '',
      );
}

class WeddingAiService {
  WeddingAiService._();
  static final WeddingAiService instance = WeddingAiService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));

  Future<WeddingPlanResult> generateWeddingPlan({
    required double totalBudget,
    required String currency,
    required String weddingType,
    required String weddingClass,
    required int guestCount,
    required String location,
    required DateTime? weddingDate,
    required List<String> styles,
    required List<String> categories,
    required Map<String, String> topVendorNames,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/wedding-plan',
      data: {
        'totalBudget': totalBudget,
        'currency': currency,
        'weddingType': weddingType,
        'weddingClass': weddingClass,
        'guestCount': guestCount,
        'location': location,
        'weddingDate': weddingDate?.toIso8601String(),
        'styles': styles,
        'categories': categories,
        'topVendorNames': topVendorNames,
      },
    );

    final data = response.data ?? {};

    final budgetRaw = (data['budgetAdvice'] as Map<String, dynamic>?) ?? {};
    final reasoningRaw = (data['vendorReasonings'] as Map<String, dynamic>?) ?? {};

    return WeddingPlanResult(
      planSummary: (data['planSummary'] as String?) ?? '',
      budgetAdvice: budgetRaw.map((k, v) => MapEntry(k, (v as num).toDouble())),
      vendorReasonings: reasoningRaw.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  /// Asks the AI to pick and justify one top vendor per category.
  /// Returns a map of category name -> its top-pick suggestion.
  Future<Map<String, VendorMatchSuggestion>> matchVendors({
    required String budgetClass,
    String? location,
    List<String> styles = const [],
    required Map<String, List<VendorMatchCandidate>> categorized,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/vendor-match',
      data: {
        'budgetClass': budgetClass,
        'location': location,
        'styles': styles,
        'categories': categorized.map(
          (cat, list) => MapEntry(cat, list.map((c) => c.toJson()).toList()),
        ),
      },
    );

    final catsRaw = (response.data?['categories'] as Map<String, dynamic>?) ?? {};
    return catsRaw.map(
      (cat, value) => MapEntry(
        cat,
        VendorMatchSuggestion.fromJson(value as Map<String, dynamic>),
      ),
    );
  }
}
