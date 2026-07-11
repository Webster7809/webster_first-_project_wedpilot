import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/email_verify_screen.dart';
import '../../features/auth/screens/couple_planning_screen.dart';
import '../../features/auth/screens/vendor_onboarding_screen.dart';
import '../../features/couple/screens/couple_dashboard_screen.dart';
import '../../features/couple/screens/couple_profile_screen.dart';
import '../../features/couple/screens/expense_entry_screen.dart';
import '../../features/couple/screens/vendor_discovery_screen.dart';
import '../../features/couple/screens/vendor_profile_screen.dart';
import '../../features/couple/screens/wishlist_screen.dart';
import '../../features/couple/screens/couple_messages_screen.dart';
import '../../features/couple/screens/chat_screen.dart';
import '../../features/couple/screens/planning_checklist_screen.dart';
import '../../features/couple/screens/feedback_submission_screen.dart';
import '../../features/couple/screens/my_bookings_screen.dart';
import '../../features/vendor/screens/vendor_dashboard_screen.dart';
import '../../features/vendor/screens/vendor_listings_screen.dart';
import '../../features/vendor/screens/vendor_profile_management_screen.dart';
import '../../features/vendor/screens/availability_calendar_screen.dart';
import '../../features/vendor/screens/lead_inbox_screen.dart';
import '../../features/vendor/screens/vendor_analytics_screen.dart';
import '../../features/vendor/screens/subscription_screen.dart';
import '../../features/vendor/screens/vendor_messages_screen.dart';
import '../../features/vendor/screens/vendor_feedback_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_categories_screen.dart';
import '../../features/admin/screens/admin_invitation_templates_screen.dart';
import '../../features/admin/screens/user_management_screen.dart';
import '../../features/admin/screens/vendor_verification_screen.dart';
import '../../features/admin/screens/content_moderation_screen.dart';
import '../../features/admin/screens/platform_analytics_screen.dart';
import '../../features/invitation/screens/invitation_gallery_screen.dart';
import '../../features/invitation/screens/invitation_editor_screen.dart';
import '../../features/invitation/screens/rsvp_dashboard_screen.dart';
import '../../features/invitation/screens/public_invitation_screen.dart';
import '../../features/couple/screens/reports_screen.dart';
import '../../features/couple/screens/budget_share_screen.dart';
import '../../features/shared/screens/notifications_screen.dart';
import '../../features/shared/screens/settings_screen.dart';
import '../../features/shared/screens/help_screen.dart';
import '../../providers/auth_provider.dart';
import '../../shell/couple_shell.dart';
import '../../shell/vendor_shell.dart';
import '../../shell/admin_shell.dart';
import 'app_routes.dart';

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authProvider, (previous, next) => notifyListeners());
  }
}

String _homeForRole(AuthState auth) {
  if (auth.isCouple) return AppRoutes.coupleDashboard;
  if (auth.isVendor) return AppRoutes.vendorDashboard;
  if (auth.isAdmin) return AppRoutes.adminDashboard;
  return AppRoutes.login;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.register,
    debugLogDiagnostics: false,
    refreshListenable: notifier,

    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;

      final isAuthScreen = AppRoutes.authScreens.contains(loc);
      final isPublicInvite = loc.startsWith('/i/') || loc.startsWith('/g/');
      // Reset-password links are token-identified, not session-identified —
      // they must work whether or not the clicking device happens to still
      // be logged in as someone else, so this bypasses both the "must be
      // authenticated" and "authenticated users get bounced home" rules
      // below (unlike login/register, which intentionally bounce).
      final isPasswordReset = loc == AppRoutes.resetPassword;

      if (!auth.isAuthenticated &&
          !isAuthScreen &&
          !isPublicInvite &&
          !isPasswordReset) {
        return AppRoutes.login;
      }

      if (auth.isAuthenticated && auth.needsOnboarding) {
        final target = auth.isVendor
            ? AppRoutes.vendorOnboarding
            : AppRoutes.couplePlanning;
        return loc == target ? null : target;
      }

      if (auth.isAuthenticated && isAuthScreen) {
        return _homeForRole(auth);
      }
      if (auth.isAuthenticated && !isAuthScreen && !isPublicInvite && !isPasswordReset) {
        if (loc.startsWith(AppRoutes.couplePrefix) && !auth.isCouple) {
          return _homeForRole(auth);
        }
        if (loc.startsWith(AppRoutes.vendorPrefix) && !auth.isVendor) {
          return _homeForRole(auth);
        }
        if (loc.startsWith(AppRoutes.adminPrefix) && !auth.isAdmin) {
          return _homeForRole(auth);
        }
      }

      return null;
    },

    routes: [
      // ── Pre-auth ──────────────────────────────────────────────────────────
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (_, state) =>
            ResetPasswordScreen(token: state.uri.queryParameters['token']),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (_, _) => const EmailVerifyScreen(),
      ),
      GoRoute(
        path: AppRoutes.couplePlanning,
        builder: (_, _) => const CouplePlanningScreen(),
      ),
      GoRoute(
        path: AppRoutes.vendorOnboarding,
        builder: (_, _) => const VendorOnboardingScreen(),
      ),

      // ── Public invitation (no auth, no shell) ─────────────────────────────
      GoRoute(
        path: AppRoutes.publicInvite,
        builder: (_, state) => PublicInvitationScreen(
          shareToken: state.pathParameters['shareToken'] ?? '',
        ),
      ),

      // ── Public per-guest invitation link (no auth, no shell) ─────────────
      GoRoute(
        path: AppRoutes.publicGuestInvite,
        builder: (_, state) => PublicInvitationScreen(
          inviteToken: state.pathParameters['inviteToken'] ?? '',
        ),
      ),

      // ── Shared full-screen pushes ─────────────────────────────────────────
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(path: AppRoutes.help, builder: (_, _) => const HelpScreen()),
      GoRoute(
        path: AppRoutes.coupleReports,
        builder: (_, _) => const ReportsScreen(),
      ),

      // ── Couple full-screen pushes ─────────────────────────────────────────
      GoRoute(
        path: AppRoutes.coupleVendorDetail,
        builder: (_, state) =>
            VendorProfileScreen(vendorId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.coupleEditPlan,
        builder: (_, _) => const CouplePlanningScreen(),
      ),
      GoRoute(
        path: AppRoutes.coupleBudgetShare,
        builder: (_, _) => const BudgetShareScreen(),
      ),
      GoRoute(
        path: AppRoutes.coupleExpenseNew,
        builder: (_, _) => const ExpenseEntryScreen(),
      ),
      GoRoute(
        path: AppRoutes.coupleInvitationEditor,
        builder: (_, state) => InvitationEditorScreen(
          invitationId: state.uri.queryParameters['id'],
        ),
      ),
      GoRoute(
        path: AppRoutes.coupleMessages,
        builder: (_, _) => const CoupleMessagesScreen(),
      ),
      GoRoute(
        path: AppRoutes.coupleChat,
        builder: (_, state) =>
            ChatScreen(convoId: state.pathParameters['convoId'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.coupleChecklist,
        builder: (_, _) => const PlanningChecklistScreen(),
      ),
      GoRoute(
        path: AppRoutes.coupleWishlist,
        builder: (_, _) => const WishlistScreen(),
      ),
      GoRoute(
        path: AppRoutes.coupleFeedbackNew,
        builder: (_, state) =>
            FeedbackSubmissionScreen(initialVendorId: state.extra as String?),
      ),
      GoRoute(
        path: AppRoutes.coupleBookings,
        builder: (_, _) => const MyBookingsScreen(),
      ),

      // ── Vendor full-screen pushes ─────────────────────────────────────────
      GoRoute(
        path: AppRoutes.vendorAnalytics,
        builder: (_, _) => const VendorAnalyticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.vendorMessages,
        builder: (_, _) => const VendorMessagesScreen(),
      ),
      GoRoute(
        path: AppRoutes.vendorFeedback,
        builder: (_, _) => const VendorFeedbackScreen(),
      ),
      GoRoute(
        path: AppRoutes.vendorChat,
        builder: (_, state) =>
            ChatScreen(convoId: state.pathParameters['convoId'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.vendorAvailability,
        builder: (_, _) => const AvailabilityCalendarScreen(),
      ),
      GoRoute(
        path: AppRoutes.vendorSubscription,
        builder: (_, _) => const SubscriptionScreen(),
      ),

      // ── Admin full-screen pushes ──────────────────────────────────────────
      GoRoute(
        path: AppRoutes.adminModeration,
        builder: (_, _) => const ContentModerationScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminCategories,
        builder: (_, _) => const AdminCategoriesScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminInvitationTemplates,
        builder: (_, _) => const AdminInvitationTemplatesScreen(),
      ),

      // ══════════════════════════════════════════════════════════════════════
      // COUPLE SHELL — 5 tabs: Home, Vendors, Budget, Invite, Profile
      // ══════════════════════════════════════════════════════════════════════
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => CoupleShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.coupleDashboard,
                builder: (_, _) => const CoupleDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.coupleVendors,
                builder: (_, _) => const VendorDiscoveryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.coupleBudget,
                builder: (_, _) => const CouplePlanningScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.coupleInvitations,
                builder: (_, _) => const InvitationGalleryScreen(),
                routes: [
                  GoRoute(
                    path: ':id/rsvp',
                    builder: (_, state) => RsvpDashboardScreen(
                      invitationId: state.pathParameters['id'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.coupleProfile,
                builder: (_, _) => const CoupleProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ══════════════════════════════════════════════════════════════════════
      // VENDOR SHELL — 4 tabs: Dashboard, Listings, Inquiries, Account
      // ══════════════════════════════════════════════════════════════════════
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => VendorShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.vendorDashboard,
                builder: (_, _) => const VendorDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.vendorListings,
                builder: (_, _) => const VendorListingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.vendorLeads,
                builder: (_, _) => const LeadInboxScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.vendorAccount,
                builder: (_, _) => const VendorProfileManagementScreen(),
              ),
            ],
          ),
        ],
      ),

      // ══════════════════════════════════════════════════════════════════════
      // ADMIN SHELL — 4 tabs: Dashboard, Users, Vendors, Analytics
      // ══════════════════════════════════════════════════════════════════════
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AdminShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminDashboard,
                builder: (_, _) => const AdminDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminUsers,
                builder: (_, _) => const UserManagementScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminVendors,
                builder: (_, _) => const VendorVerificationScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminAnalytics,
                builder: (_, _) => const PlatformAnalyticsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
