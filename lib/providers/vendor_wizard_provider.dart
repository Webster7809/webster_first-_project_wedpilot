import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/vendor_profile.dart';
import '../core/services/vendor_pdf_service.dart';
import 'auth_provider.dart';
import 'budget_provider.dart';
import 'vendor_ai_provider.dart';

// ── Custom (couple-added) vendors ───────────────────────────────────────────

final customVendorsProvider =
    StateNotifierProvider<CustomVendorsNotifier, List<VendorProfile>>(
  (ref) => CustomVendorsNotifier(),
);

class CustomVendorsNotifier extends StateNotifier<List<VendorProfile>> {
  CustomVendorsNotifier() : super(const []);

  VendorProfile add({
    required String businessName,
    required String category,
    String? phone,
    String? location,
    String? notes,
  }) {
    final vendor = VendorProfile(
      id: 'custom-${const Uuid().v4()}',
      userId: 'couple-added',
      businessName: businessName,
      description: notes,
      category: category,
      location: location,
      tier: VendorTier.free,
      verificationStatus: VerificationStatus.pending,
      phone: phone,
      isCustomEntry: true,
    );
    state = [...state, vendor];
    return vendor;
  }

  void remove(String vendorId) {
    state = state.where((v) => v.id != vendorId).toList();
  }
}

// ── AI-curated plan ──────────────────────────────────────────────────────────

/// The AI's single best-ranked vendor for each requested category.
final aiTopMatchesProvider = Provider<List<VendorMatch>>((ref) {
  final matches = ref.watch(aiRecommendedVendorsProvider).valueOrNull ?? [];
  return matches.where((m) => m.rankInCategory == 1).toList();
});

/// Final vendor list for the plan: AI's top pick per category plus any
/// vendors the couple added themselves (e.g. for categories AI found none for).
final finalChosenVendorsProvider = Provider<List<VendorProfile>>((ref) {
  final aiPicks = ref.watch(aiTopMatchesProvider).map((m) => m.vendor).toList();
  final custom = ref.watch(customVendorsProvider);
  return [...aiPicks, ...custom];
});

// ── PDF generation ───────────────────────────────────────────────────────────

final weddingPlanPdfBytesProvider = FutureProvider<Uint8List>((ref) async {
  final couple = ref.watch(coupleProfileProvider);
  final vendors = ref.watch(finalChosenVendorsProvider);
  final aiMatches = ref.watch(aiRecommendedVendorsProvider).valueOrNull ?? [];
  final budget = ref.watch(budgetProvider).budget;

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
