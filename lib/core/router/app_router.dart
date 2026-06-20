import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/email_verify_screen.dart';
import '../../features/auth/screens/couple_planning_screen.dart';
import '../../features/auth/screens/vendor_onboarding_screen.dart';
import '../../features/couple/screens/couple_dashboard_screen.dart';
import '../../features/couple/screens/couple_profile_screen.dart';
import '../../features/couple/screens/budget_overview_screen.dart';
import '../../features/couple/screens/budget_setup_wizard_screen.dart';
import '../../features/couple/screens/expense_entry_screen.dart';
import '../../features/couple/screens/vendor_discovery_screen.dart';
import '../../features/couple/screens/vendor_profile_screen.dart';
import '../../features/couple/screens/wishlist_screen.dart';
import '../../features/couple/screens/couple_messages_screen.dart';
import '../../features/couple/screens/chat_screen.dart';
import '../../features/couple/screens/planning_checklist_screen.dart';
import '../../features/couple/screens/review_submission_screen.dart';
import '../../features/vendor/screens/vendor_dashboard_screen.dart';
import '../../features/vendor/screens/vendor_listings_screen.dart';
import '../../features/vendor/screens/vendor_profile_management_screen.dart';
import '../../features/vendor/screens/availability_calendar_screen.dart';
import '../../features/vendor/screens/lead_inbox_screen.dart';
import '../../features/vendor/screens/vendor_analytics_screen.dart';
import '../../features/vendor/screens/subscription_screen.dart';
import '../../features/vendor/screens/vendor_messages_screen.dart';
import '../../features/vendor/screens/vendor_reviews_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/user_management_screen.dart';
import '../../features/admin/screens/vendor_verification_screen.dart';
import '../../features/admin/screens/content_moderation_screen.dart';
import '../../features/admin/screens/platform_analytics_screen.dart';
import '../../features/invitation/screens/invitation_gallery_screen.dart';
import '../../features/invitation/screens/invitation_editor_screen.dart';
import '../../features/invitation/screens/rsvp_dashboard_screen.dart';
import '../../features/invitation/screens/public_invitation_screen.dart';
import '../../features/couple/screens/reports_screen.dart';
import '../../features/shared/screens/notifications_screen.dart';
import '../../features/shared/screens/settings_screen.dart';
import '../../features/shared/screens/help_screen.dart';
import '../../providers/auth_provider.dart';
import '../../shell/couple_shell.dart';
import '../../shell/vendor_shell.dart';
import '../../shell/admin_shell.dart';

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authProvider, (previous, next) => notifyListeners());
  }
}

String _homeForRole(AuthState auth) {
  if (auth.isCouple) return '/couple/dashboard';
  if (auth.isVendor) return '/vendor/dashboard';
  if (auth.isAdmin) return '/admin/dashboard';
  return '/login';
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/onboarding',
    debugLogDiagnostics: false,
    refreshListenable: notifier,

    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;

      const authScreens = {
        '/onboarding', '/login', '/register', '/forgot-password',
        '/verify-email', '/couple-planning', '/vendor-onboarding',
      };

      final isAuthScreen = authScreens.contains(loc);
      final isPublicInvite = loc.startsWith('/i/');

      if (!auth.isAuthenticated && !isAuthScreen && !isPublicInvite) {
        return '/login';
      }
      if (auth.isAuthenticated && isAuthScreen) {
        return _homeForRole(auth);
      }
      if (auth.isAuthenticated && !isAuthScreen && !isPublicInvite) {
        if (loc.startsWith('/couple') && !auth.isCouple) return _homeForRole(auth);
        if (loc.startsWith('/vendor') && !auth.isVendor) return _homeForRole(auth);
        if (loc.startsWith('/admin') && !auth.isAdmin) return _homeForRole(auth);
      }

      return null;
    },

    routes: [
      // ── Pre-auth ──────────────────────────────────────────────────────────
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: '/verify-email', builder: (_, _) => const EmailVerifyScreen()),
      GoRoute(path: '/couple-planning', builder: (_, _) => const CouplePlanningScreen()),
      GoRoute(path: '/vendor-onboarding', builder: (_, _) => const VendorOnboardingScreen()),

      // ── Public invitation (no auth, no shell) ─────────────────────────────
      GoRoute(
        path: '/i/:shareToken',
        builder: (_, state) =>
            PublicInvitationScreen(shareToken: state.pathParameters['shareToken']!),
      ),

      // ── Shared full-screen pushes ─────────────────────────────────────────
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/help', builder: (_, _) => const HelpScreen()),
      GoRoute(path: '/couple/reports', builder: (_, _) => const ReportsScreen()),

      // ── Couple full-screen pushes ─────────────────────────────────────────
      GoRoute(
        path: '/couple/vendors/:id',
        builder: (_, state) =>
            VendorProfileScreen(vendorId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/couple/budget/setup', builder: (_, _) => const BudgetSetupWizardScreen()),
      GoRoute(path: '/couple/budget/expense/new', builder: (_, _) => const ExpenseEntryScreen()),
      GoRoute(
        path: '/couple/invitations/editor',
        builder: (_, state) =>
            InvitationEditorScreen(invitationId: state.uri.queryParameters['id']),
      ),
      GoRoute(path: '/couple/messages', builder: (_, _) => const CoupleMessagesScreen()),
      GoRoute(
        path: '/couple/messages/:convoId',
        builder: (_, state) => ChatScreen(convoId: state.pathParameters['convoId']!),
      ),
      GoRoute(path: '/couple/checklist', builder: (_, _) => const PlanningChecklistScreen()),
      GoRoute(path: '/couple/wishlist', builder: (_, _) => const WishlistScreen()),
      GoRoute(path: '/couple/reviews/new', builder: (_, _) => const ReviewSubmissionScreen()),

      // ── Vendor full-screen pushes ─────────────────────────────────────────
      GoRoute(path: '/vendor/reviews', builder: (_, _) => const VendorReviewsScreen()),
      GoRoute(path: '/vendor/messages', builder: (_, _) => const VendorMessagesScreen()),
      GoRoute(
        path: '/vendor/messages/:convoId',
        builder: (_, state) => ChatScreen(convoId: state.pathParameters['convoId']!),
      ),
      GoRoute(path: '/vendor/availability', builder: (_, _) => const AvailabilityCalendarScreen()),
      GoRoute(path: '/vendor/subscription', builder: (_, _) => const SubscriptionScreen()),

      // ── Admin full-screen pushes ──────────────────────────────────────────
      GoRoute(path: '/admin/moderation', builder: (_, _) => const ContentModerationScreen()),

      // ══════════════════════════════════════════════════════════════════════
      // COUPLE SHELL — 5 tabs: Home, Vendors, Budget, Invite, Profile
      // ══════════════════════════════════════════════════════════════════════
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => CoupleShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/couple/dashboard', builder: (_, _) => const CoupleDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/couple/vendors', builder: (_, _) => const VendorDiscoveryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/couple/budget', builder: (_, _) => const BudgetOverviewScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/couple/invitations',
              builder: (_, _) => const InvitationGalleryScreen(),
              routes: [
                GoRoute(
                  path: ':id/rsvp',
                  builder: (_, state) =>
                      RsvpDashboardScreen(invitationId: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/couple/profile', builder: (_, _) => const CoupleProfileScreen()),
          ]),
        ],
      ),

      // ══════════════════════════════════════════════════════════════════════
      // VENDOR SHELL — 5 tabs: Dashboard, Listings, Inquiries, Reviews, Account
      // ══════════════════════════════════════════════════════════════════════
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => VendorShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/vendor/dashboard', builder: (_, _) => const VendorDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/vendor/listings', builder: (_, _) => const VendorListingsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/vendor/leads', builder: (_, _) => const LeadInboxScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/vendor/analytics', builder: (_, _) => const VendorAnalyticsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/vendor/profile', builder: (_, _) => const VendorProfileManagementScreen()),
          ]),
        ],
      ),

      // ══════════════════════════════════════════════════════════════════════
      // ADMIN SHELL — 4 tabs: Dashboard, Users, Vendors, Analytics
      // ══════════════════════════════════════════════════════════════════════
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AdminShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/admin/dashboard', builder: (_, _) => const AdminDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/admin/users', builder: (_, _) => const UserManagementScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/admin/vendors', builder: (_, _) => const VendorVerificationScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/admin/analytics', builder: (_, _) => const PlatformAnalyticsScreen()),
          ]),
        ],
      ),
    ],
  );
});
