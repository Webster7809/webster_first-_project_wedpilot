import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';

// Flutter never touches the Gemini API key.
// All AI calls go through the Node/Express backend at [_baseUrl].
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

class GeminiPlanResult {
  final String planSummary;
  final Map<String, double> budgetAdvice;
  final Map<String, String> vendorReasonings;

  const GeminiPlanResult({
    required this.planSummary,
    required this.budgetAdvice,
    required this.vendorReasonings,
  });
}

class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));

  Future<GeminiPlanResult> generateWeddingPlan({
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

    return GeminiPlanResult(
      planSummary: (data['planSummary'] as String?) ?? '',
      budgetAdvice: budgetRaw.map((k, v) => MapEntry(k, (v as num).toDouble())),
      vendorReasonings: reasoningRaw.map((k, v) => MapEntry(k, v.toString())),
    );
  }
}
