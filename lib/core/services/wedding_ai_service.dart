import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';

import '../../models/vendor_profile.dart' show ReasoningStep, SelectionBasis;

// All AI calls (OpenRouter-backed) go through the Node/Express backend at [_baseUrl].
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

class WeddingAiException implements Exception {
  final String message;
  const WeddingAiException(this.message);
}

class WeddingPlanResult {
  final String planSummary;
  final Map<String, double> budgetAdvice;
  final Map<String, String> budgetReasoning;

  const WeddingPlanResult({
    required this.planSummary,
    required this.budgetAdvice,
    required this.budgetReasoning,
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
  final int feedbackCount;
  final String priceTier;
  final double priceMin;
  final double priceMax;
  final double reputationScore;
  final double locationScore;
  final double valueScore;
  final bool isBookedOnWeddingDate;

  const VendorMatchCandidate({
    required this.vendorId,
    required this.businessName,
    this.location,
    this.styleTags = const [],
    this.rating,
    this.feedbackCount = 0,
    required this.priceTier,
    required this.priceMin,
    required this.priceMax,
    required this.reputationScore,
    required this.locationScore,
    required this.valueScore,
    this.isBookedOnWeddingDate = false,
  });

  Map<String, dynamic> toJson() => {
        'vendorId': vendorId,
        'businessName': businessName,
        'location': location,
        'styleTags': styleTags,
        'rating': rating,
        'feedbackCount': feedbackCount,
        'priceTier': priceTier,
        'priceMin': priceMin,
        'priceMax': priceMax,
        'reputationScore': reputationScore,
        'locationScore': locationScore,
        'valueScore': valueScore,
        'isBookedOnWeddingDate': isBookedOnWeddingDate,
      };
}

/// The AI's single top pick for one vendor category.
class VendorMatchSuggestion {
  final String vendorId;
  final double confidence;
  final List<ReasoningStep> reasoningSteps;
  final bool fitsBudget;
  final double? budgetDeltaPercent;
  final SelectionBasis selectionBasis;
  final String? noteToCouple;

  const VendorMatchSuggestion({
    required this.vendorId,
    required this.confidence,
    required this.reasoningSteps,
    this.fitsBudget = true,
    this.budgetDeltaPercent,
    this.selectionBasis = SelectionBasis.exactBudgetMatch,
    this.noteToCouple,
  });

  /// Flattened text for contexts that only accept one plain string (e.g. PDF export).
  String get reasoning => reasoningSteps.map((s) => '${s.label}: ${s.text}').join(' ');

  factory VendorMatchSuggestion.fromJson(Map<String, dynamic> json) {
    final rawSteps = (json['reasoningSteps'] as List<dynamic>?) ?? const [];
    // Every step's text goes through the same leak guard as planSummary/
    // budgetReasoning below — this path used to skip it entirely, so a
    // model that spilled raw JSON/meta-commentary into a "Style match" or
    // "Verdict" step (the only two the backend leaves as free-form prose;
    // everything else is grounded from real data) would reach the couple
    // verbatim instead of being trimmed at the leak boundary.
    final steps = rawSteps
        .whereType<Map<String, dynamic>>()
        .map((s) => ReasoningStep(
              label: s['label'] as String? ?? '',
              text: WeddingAiService._stripJsonLeak((s['text'] as String?) ?? ''),
            ))
        .where((s) => s.text.isNotEmpty)
        .toList();
    final rawNote = json['noteToCouple'] as String?;
    return VendorMatchSuggestion(
      vendorId: json['vendorId'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      // Falls back to a single legacy-shaped step if the model ever returns
      // the old flat 'reasoning' string instead of 'reasoningSteps'.
      reasoningSteps: steps.isNotEmpty
          ? steps
          : [
              ReasoningStep(
                label: ReasoningStep.verdict,
                text: WeddingAiService._stripJsonLeak(json['reasoning'] as String? ?? ''),
              ),
            ],
      fitsBudget: json['fitsBudget'] as bool? ?? true,
      budgetDeltaPercent: (json['budgetDeltaPercent'] as num?)?.toDouble(),
      selectionBasis: json['selectionBasis'] == 'wedding_class_best_fit'
          ? SelectionBasis.weddingClassBestFit
          : SelectionBasis.exactBudgetMatch,
      noteToCouple: (rawNote == null || rawNote.isEmpty)
          ? null
          : WeddingAiService._stripJsonLeak(rawNote),
    );
  }
}

class WeddingAiService {
  WeddingAiService._();
  static final WeddingAiService instance = WeddingAiService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 90),
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
  }) async {
    try {
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
        },
      );

      final data = response.data ?? {};

      final budgetRaw = (data['budgetAdvice'] as Map<String, dynamic>?) ?? {};
      final budgetReasoningRaw = (data['budgetReasoning'] as Map<String, dynamic>?) ?? {};

      return WeddingPlanResult(
        planSummary: _stripJsonLeak((data['planSummary'] as String?) ?? ''),
        budgetAdvice: budgetRaw.map((k, v) => MapEntry(k, (v as num).toDouble())),
        budgetReasoning: budgetReasoningRaw
            .map((k, v) => MapEntry(k, _stripJsonLeak(v.toString()))),
      );
    } on DioException catch (e) {
      throw WeddingAiException(_friendlyError(e));
    }
  }

  // Mirror of the backend's stripLeak guard, kept client-side because a
  // deployed backend may predate it: a free-tier model occasionally spills the
  // rest of its JSON into a prose field (quoting keys with ASCII, curly, or
  // CJK corner quotes — '「budgetAdvice": {'). Prose fields are single
  // paragraphs, so a blank line, an embedded '"Key": {' pattern, or a bare
  // schema key name is always a leak — nothing past it is ever rendered.
  static final RegExp _leakMarker = RegExp(
    r'''\n\s*\n|["'“”‘’「」『』][A-Za-z][A-Za-z ]{0,30}["'“”‘’「」『』]\s*:\s*[{\[]|\b(?:planSummary|budgetAdvice|budgetReasoning|reasoningSteps|vendorId|budgetFitSuggestionType|budgetDeltaPercent|fitsBudget|selectionBasis|noteToCouple)\b|\b(?:let me|i'll (?:rewrite|redo|compose|output|produce|correct)|as an ai|as a language model|i am an ai|the json (?:value|output|now)|proper escaping|stray characters|note:)\b''',
    caseSensitive: false,
  );

  static String _stripJsonLeak(String text) {
    final match = _leakMarker.firstMatch(text);
    if (match == null) return text.trim();
    return text
        .substring(0, match.start)
        .trim()
        .replaceFirst(RegExp(r'''["'“”‘’「」『』{,:]+$'''), '')
        .trim();
  }

  /// Asks the AI to pick and justify one top vendor per category.
  /// Returns a map of category name -> its top-pick suggestion.
  Future<Map<String, VendorMatchSuggestion>> matchVendors({
    required String budgetClass,
    String? location,
    List<String> styles = const [],
    required Map<String, List<VendorMatchCandidate>> categorized,
    // The couple's allocated spend per category (e.g. 'Venue': 5000), derived
    // from their total wedding budget. Absent categories mean no known cap.
    Map<String, double> categoryBudgets = const {},
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/vendor-match',
        data: {
          'budgetClass': budgetClass,
          'location': location,
          'styles': styles,
          'categoryBudgets': categoryBudgets,
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
    } on DioException catch (e) {
      throw WeddingAiException(_friendlyError(e));
    }
  }

  /// Shows the AI service's own words verbatim whenever the backend forwarded
  /// one (see `askAI`'s upstreamMessage extraction in `backend/server.js`) —
  /// the couple sees exactly what OpenRouter said (e.g. its real rate-limit
  /// wording), not a paraphrase written here. Only falls back to a generic
  /// message when there's genuinely no error text to show at all, i.e. the
  /// backend itself couldn't be reached (connection refused/timeout — the
  /// request never even reached OpenRouter, so there are no "AI's words" to
  /// surface).
  String _friendlyError(DioException e) {
    final data = e.response?.data;
    final raw = (data is Map && data['error'] is String)
        ? (data['error'] as String).trim()
        : '';
    if (raw.isNotEmpty) return raw;
    return "Couldn't reach WedPilot AI right now. Please try again.";
  }
}
