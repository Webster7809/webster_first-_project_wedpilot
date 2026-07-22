import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vendor_profile.dart';
import '../core/services/vendor_pdf_service.dart';
import 'auth_provider.dart';
import 'budget_provider.dart';
import 'vendor_ai_provider.dart';

// ── AI-curated plan ──────────────────────────────────────────────────────────

/// The AI's single best-ranked vendor for each requested category.
final aiTopMatchesProvider = Provider<List<VendorMatch>>((ref) {
  final matches = ref.watch(aiRecommendedVendorsProvider).valueOrNull ?? [];
  return matches.where((m) => m.rankInCategory == 1).toList();
});

/// Final vendor list for the plan: the AI's top pick per category.
final finalChosenVendorsProvider = Provider<List<VendorProfile>>((ref) {
  return ref.watch(aiTopMatchesProvider).map((m) => m.vendor).toList();
});

// ── PDF generation ───────────────────────────────────────────────────────────

final weddingPlanPdfBytesProvider = FutureProvider<Uint8List>((ref) async {
  final couple = ref.watch(coupleProfileProvider);
  final vendors = ref.watch(finalChosenVendorsProvider);
  final aiMatches = ref.watch(aiRecommendedVendorsProvider).valueOrNull ?? [];
  final budget = ref.watch(budgetProvider).data;

  final reasoningByVendorId = <String, String>{
    for (final m in aiMatches)
      if (m.reasoning != null) m.vendorId: m.reasoning!,
  };

  return VendorPdfService.buildWeddingPlanPdf(
    couple: couple,
    budget: budget,
    vendors: vendors,
    reasoningByVendorId: reasoningByVendorId,
  );
});
