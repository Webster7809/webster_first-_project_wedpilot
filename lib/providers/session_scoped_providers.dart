import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_provider.dart';
import 'booking_provider.dart';
import 'budget_provider.dart';
import 'invitation_provider.dart';
import 'messaging_provider.dart';
import 'notification_provider.dart';
import 'report_provider.dart';
import 'task_provider.dart';
import 'vendor_own_provider.dart';
import 'vendor_provider.dart';
import 'vendor_wizard_provider.dart';

/// Every provider holding data that belongs to *one signed-in account*.
///
/// None of these auto-dispose, so without an explicit reset they keep their
/// cached data across a logout. Signing into a second account on the same
/// device then renders the first account's bookings, budget, invitations and
/// profile — one user's data inside another user's session.
///
/// [invalidateSessionScopedProviders] is called on both logout and login:
/// logout so nothing survives to be seen, and login because a session can be
/// replaced without an explicit logout (an expired refresh token bounces
/// straight to the login screen).
///
/// `test/session_reset_test.dart` fails if a provider is added to
/// `lib/providers/` and not listed here or explicitly exempted.
final List<ProviderOrFamily> kSessionScopedProviders = [
  // Couple
  myBookingsProvider,
  rateableVendorsProvider,
  activeRequestsByVendorProvider,
  budgetProvider,
  taskProvider,
  invitationsProvider,
  wishlistProvider,
  wishlistedVendorsProvider,
  weddingPlanPdfBytesProvider,

  // Vendor
  vendorOwnProvider,
  vendorRevenueProvider,

  // Admin
  adminOverviewProvider,
  adminAllVendorsProvider,
  adminPendingVendorsProvider,
  adminUsersProvider,
  adminFeedbackProvider,
  adminFlaggedImagesProvider,
  adminFlaggedMessagesProvider,
  adminAnalyticsProvider,

  // Shared, but scoped to the signed-in user
  conversationsProvider,
  notificationsProvider,
  reportProvider,
  recommendedVendorsProvider,
];

/// Drops every cached per-account provider. Call whenever the signed-in
/// identity changes.
///
/// Goes through [Ref.container] rather than calling `ref.invalidate(...)`
/// directly. Several entries here (myBookingsProvider, budgetProvider,
/// taskProvider, notificationsProvider, vendorOwnProvider, ...) call
/// `ref.watch(authProvider.notifier)` themselves to read the access token, so
/// each has authProvider as a dependency-graph ancestor. `ref.invalidate`
/// walks that ancestor graph (`ProviderElementBase._debugAssertCanDependOn`)
/// before invalidating, and — called from AuthNotifier's own login/register
/// method, so the calling `Ref`'s origin already *is* authProvider — always
/// finds authProvider among the target's ancestors and throws
/// CircularDependencyError, regardless of timing (deferring the call with
/// `Future.microtask` does not help: the graph shape doesn't change, only
/// when it gets walked). This reproduced on every fresh login/register but
/// never on session restore or logout with no watchers mounted, since only a
/// provider that has actually been read establishes the ancestor edge, so it
/// depended on which screens happened to be live.
///
/// Reading a persistent notifier via `.notifier` (not its state) specifically
/// to avoid rebuilding on every state change, while still wanting an
/// occasional manual invalidate from that same notifier, is an accepted
/// Riverpod pattern — it just isn't one `ref.invalidate`'s conservative
/// assertion can tell apart from a real cycle. There is no actual loop here:
/// the invalidated providers only read the notifier reference, they never
/// call back into it. `ProviderContainer.invalidate` (reachable via
/// `ref.container`) performs the identical invalidation without that
/// assertion — see ProviderElementBase.invalidate in riverpod's
/// framework/element.dart, which is a thin `assert(...); _container.invalidate(...)`
/// wrapper around exactly this container method.
void invalidateSessionScopedProviders(Ref ref) {
  for (final provider in kSessionScopedProviders) {
    ref.container.invalidate(provider);
  }
}
