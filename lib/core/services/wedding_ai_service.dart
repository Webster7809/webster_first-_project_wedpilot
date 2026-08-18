import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:dio/dio.dart';

import 'authenticated_dio.dart';
import '../utils/json_utils.dart';
import '../../models/vendor_profile.dart' show ReasoningStep, SelectionBasis;

// All AI calls (OpenRouter-backed) go through the Node/Express backend.
// Flutter never touches the LLM API key.

class WeddingAiException implements Exception {
  final String message;
  const WeddingAiException(this.message);
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
    // Every step's text goes through the same leak guard as noteToCouple
    // below — this path used to skip it entirely, so a
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
      vendorId: requireString(json, 'vendorId'),
      confidence: requireNum(json, 'confidence').toDouble(),
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

  // buildApiDio, not a bare Dio: /api/vendor-match now requires a bearer
  // token, so this call needs the same transparent 401-refresh-and-retry
  // every other authenticated service gets. The receive timeout is raised
  // over that helper's default because an AI completion legitimately takes
  // far longer than a database read.
  final Dio _dio = buildApiDio()
    ..options.receiveTimeout = const Duration(seconds: 90);

  // Every AI call funnels through this queue so two calls fired close
  // together never hit the backend concurrently — the free-tier model
  // backing OPENROUTER_MODEL can't serve two requests on the same key at
  // once: the second one gets its connection killed outright rather than
  // queued, which surfaces here as a bare "terminated" network error instead
  // of a real AI response.
  Future<void> _queue = Future.value();

  // `flutter_test` runs every `testWidgets` body in its own zone. A Future
  // created and completed entirely inside one test's zone stops notifying
  // `.then()` listeners registered from a *later* test's zone once the
  // owning test has finished — confirmed by instrumentation: the completer
  // settles normally, but a fresh listener attached from the next test never
  // fires, even though a brand-new Future created in that next test's own
  // zone behaves normally. Since [instance] is a real singleton, [_queue]
  // otherwise carries a test-1-zoned Future into test 2, permanently
  // starving every call queued behind it. Not reachable in production (the
  // app runs in one continuous zone) — test-only escape hatch.
  @visibleForTesting
  void resetQueueForTests() => _queue = Future.value();

  Future<T> _serialized<T>(Future<T> Function() action) {
    final previous = _queue;
    final done = Completer<void>();
    _queue = done.future;
    return previous.then((_) => action()).whenComplete(done.complete);
  }

  // Mirror of the backend's stripLeak guard, kept client-side because a
  // deployed backend may predate it: a free-tier model occasionally spills the
  // rest of its JSON into a prose field (quoting keys with ASCII, curly, or
  // CJK corner quotes — '「reasoningSteps": {'). Prose fields are single
  // paragraphs, so a blank line, an embedded '"Key": {' pattern, or a bare
  // schema key name is always a leak — nothing past it is ever rendered.
  static final RegExp _leakMarker = RegExp(
    r'''\n\s*\n|["'“”‘’「」『』][A-Za-z][A-Za-z ]{0,30}["'“”‘’「」『』]\s*:\s*[{\[]|\b(?:reasoningSteps|vendorId|budgetFitSuggestionType|budgetDeltaPercent|fitsBudget|selectionBasis|noteToCouple)\b|\b(?:let me|i'll (?:rewrite|redo|compose|output|produce|correct)|as an ai|as a language model|i am an ai|the json (?:value|output|now)|proper escaping|stray characters|note:)\b''',
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

  /// Asks the AI to write human-friendly justification for a vendor pick
  /// already decided by the deterministic local scoring engine (see
  /// `_AiEngine.recommend` in vendor_ai_provider.dart) — the AI never
  /// chooses between candidates here, only explains the one it's given.
  /// Returns a map of category name -> its explained pick.
  Future<Map<String, VendorMatchSuggestion>> explainVendorMatches({
    required String budgetClass,
    String? location,
    List<String> styles = const [],
    required Map<String, VendorMatchCandidate> picks,
    // The couple's allocated spend per category (e.g. 'Venue': 5000), derived
    // from their total wedding budget. Absent categories mean no known cap.
    Map<String, double> categoryBudgets = const {},
    // Required: the endpoint burns OpenRouter quota on our key, so it is no
    // longer open to unauthenticated callers.
    required String accessToken,
  }) => _serialized(() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/vendor-match',
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
        data: {
          'budgetClass': budgetClass,
          'location': location,
          'styles': styles,
          'categoryBudgets': categoryBudgets,
          'picks': picks.map((cat, c) => MapEntry(cat, c.toJson())),
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
    } on FormatException catch (_) {
      throw const WeddingAiException('WedPilot AI returned an unexpected response. Please try again.');
    } on TypeError catch (_) {
      throw const WeddingAiException('WedPilot AI returned an unexpected response. Please try again.');
    }
  });

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
