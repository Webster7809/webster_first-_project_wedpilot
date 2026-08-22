import '../../models/invitation.dart';

class RsvpService {
  RsvpService._();

  // ── Validation ───────────────────────────────────────────────────────────────

  static String? validateGuest({
    required String name,
    String? email,
    String? phone,
  }) {
    if (name.trim().isEmpty) return 'Guest name is required.';
    if (name.trim().length < 2) return 'Name must be at least 2 characters.';
    if (email != null && email.trim().isNotEmpty) {
      final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
      if (!ok) return 'Enter a valid email address.';
    }
    if (phone != null && phone.trim().isNotEmpty && phone.trim().length < 7) {
      return 'Enter a valid phone number (at least 7 digits).';
    }
    return null;
  }

  static String? validateRsvp({
    required String guestName,
    required int guestCount,
    required AttendingStatus attending,
  }) {
    if (guestName.trim().isEmpty) return 'Guest name is required.';
    if (attending == AttendingStatus.yes && guestCount < 1) {
      return 'Attending guest count must be at least 1.';
    }
    if (guestCount > 20) return 'Guest count seems unrealistically high (max 20).';
    if (guestCount < 0) return 'Guest count cannot be negative.';
    return null;
  }

  // ── Stats ────────────────────────────────────────────────────────────────────

  static RsvpStats calculateStats(
    List<RsvpResponse> responses,
    List<Guest> guests,
  ) {
    final attending = responses.where((r) => r.attending == AttendingStatus.yes).toList();
    final declined = responses.where((r) => r.attending == AttendingStatus.no).toList();
    final maybe = responses.where((r) => r.attending == AttendingStatus.maybe).toList();

    final respondedGuestIds =
        responses.map((r) => r.guestId).whereType<String>().toSet();
    final totalInvited = guests.where((g) => g.isInvited).length;
    final pending = guests
        .where((g) => g.isInvited && !respondedGuestIds.contains(g.id))
        .length;

    final totalAttending =
        attending.fold<int>(0, (sum, r) => sum + r.guestCount);

    // guest_count is intentionally zeroed on a decline (see RsvpResponse),
    // so "how many would have attended" comes from the invitation's own
    // party-size cap instead — 1 when there is none, same default an
    // uncapped ad-hoc guest gets everywhere else.
    final guestById = {for (final g in guests) g.id: g};
    final totalDeclining = declined.fold<int>(
      0,
      (sum, r) => sum + (guestById[r.guestId]?.maxPartySize ?? 1),
    );

    final mealCounts = <String, int>{};
    for (final r in attending) {
      final meal = r.mealPreference;
      if (meal != null && meal.isNotEmpty) {
        mealCounts[meal] = (mealCounts[meal] ?? 0) + r.guestCount;
      }
    }

    // Per-question tally for choice-type custom questions only (yes/no,
    // single choice, multi choice) — free text/number answers don't group
    // into meaningful counts the way a fixed option set does.
    final questionTallies = <String, Map<String, int>>{};
    for (final r in attending) {
      for (final a in r.answers) {
        final label = a.questionText;
        if (label == null) continue;
        if (a.type != RsvpQuestionType.yesNo &&
            a.type != RsvpQuestionType.singleChoice &&
            a.type != RsvpQuestionType.multiChoice) {
          continue;
        }
        final selections = a.answerJson.isNotEmpty
            ? a.answerJson
            : (a.answerText != null && a.answerText!.isNotEmpty ? [a.answerText!] : const <String>[]);
        if (selections.isEmpty) continue;
        final tally = questionTallies.putIfAbsent(label, () => {});
        for (final selection in selections) {
          tally[selection] = (tally[selection] ?? 0) + r.guestCount;
        }
      }
    }

    final responseCount = attending.length + declined.length + maybe.length;
    final responseRate =
        totalInvited > 0 ? responseCount / totalInvited * 100 : 0.0;
    final acceptanceRate = (attending.length + declined.length) > 0
        ? attending.length / (attending.length + declined.length) * 100
        : 0.0;

    return RsvpStats(
      attending: attending.length,
      declined: declined.length,
      maybe: maybe.length,
      pending: pending,
      totalAttending: totalAttending,
      totalInvited: totalInvited,
      totalGuests: guests.length,
      totalDeclining: totalDeclining,
      mealCounts: mealCounts,
      questionTallies: questionTallies,
      responseRate: responseRate,
      acceptanceRate: acceptanceRate,
    );
  }
}

// ── Data class ───────────────────────────────────────────────────────────────

class RsvpStats {
  final int attending;
  final int declined;
  final int maybe;
  final int pending;
  final int totalAttending;
  final int totalInvited;
  final int totalGuests;

  /// People who would have attended a declined invitation — guest_count is
  /// zeroed on decline, so this comes from party-size caps instead. Used
  /// only to explain why "attending + declining" can be less than invited.
  final int totalDeclining;
  final Map<String, int> mealCounts;

  /// Question text -> {answer label: guest count}, for choice-type custom
  /// questions only (yes/no, single choice, multi choice).
  final Map<String, Map<String, int>> questionTallies;
  final double responseRate;
  final double acceptanceRate;

  const RsvpStats({
    required this.attending,
    required this.declined,
    required this.maybe,
    required this.pending,
    required this.totalAttending,
    required this.totalInvited,
    required this.totalGuests,
    this.totalDeclining = 0,
    required this.mealCounts,
    this.questionTallies = const {},
    required this.responseRate,
    required this.acceptanceRate,
  });

  int get responded => attending + declined + maybe;
  bool get allResponded => pending == 0 && totalInvited > 0;
}
