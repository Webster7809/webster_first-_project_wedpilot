import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/email_verify_screen.dart';
import '../../features/couple/screens/couple_dashboard_screen.dart';
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
import '../../features/vendor/screens/vendor_profile_management_screen.dart';
import '../../features/vendor/screens/availability_calendar_screen.dart';
import '../../features/vendor/screens/lead_inbox_screen.dart';
import '../../features/vendor/screens/vendor_analytics_screen.dart';
import '../../features/vendor/screens/subscription_screen.dart';
import '../../features/vendor/screens/vendor_messages_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/user_management_screen.dart';
import '../../features/admin/screens/vendor_verification_screen.dart';
import '../../features/admin/screens/content_moderation_screen.dart';
import '../../features/admin/screens/platform_analytics_screen.dart';
import '../../features/invitation/screens/invitation_gallery_screen.dart';
import '../../features/invitation/screens/invitation_editor_screen.dart';
import '../../features/invitation/screens/rsvp_dashboard_screen.dart';
import '../../features/invitation/screens/public_invitation_screen.dart';
import '../../features/shared/screens/notifications_screen.dart';
import '../../features/shared/screens/settings_screen.dart';
import '../../features/shared/screens/help_screen.dart';
import '../../shell/couple_shell.dart';
import '../../shell/vendor_shell.dart';
import '../../shell/admin_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/verify-email', builder: (_, __) => const EmailVerifyScreen()),

      // Couple shell
      ShellRoute(
        builder: (context, state, child) => CoupleShell(child: child),
        routes: [
          GoRoute(
            path: '/couple/dashboard',
            builder: (_, __) => const CoupleDashboardScreen(),
          ),
          GoRoute(
            path: '/couple/vendors',
            builder: (_, __) => const VendorDiscoveryScreen(),
          ),
          GoRoute(
            path: '/couple/vendors/:id',
            builder: (_, state) => VendorProfileScreen(vendorId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/couple/wishlist',
            builder: (_, __) => const WishlistScreen(),
          ),
          GoRoute(
            path: '/couple/messages',
            builder: (_, __) => const CoupleMessagesScreen(),
          ),
          GoRoute(
            path: '/couple/messages/:convoId',
            builder: (_, state) => ChatScreen(convoId: state.pathParameters['convoId']!),
          ),
          GoRoute(
            path: '/couple/budget',
            builder: (_, __) => const BudgetOverviewScreen(),
          ),
          GoRoute(
            path: '/couple/budget/setup',
            builder: (_, __) => const BudgetSetupWizardScreen(),
          ),
          GoRoute(
            path: '/couple/budget/expense/new',
            builder: (_, __) => const ExpenseEntryScreen(),
          ),
          GoRoute(
            path: '/couple/checklist',
            builder: (_, __) => const PlanningChecklistScreen(),
          ),
          GoRoute(
            path: '/couple/reviews/new',
            builder: (_, __) => const ReviewSubmissionScreen(),
          ),
          GoRoute(
            path: '/couple/invitations',
            builder: (_, __) => const InvitationGalleryScreen(),
          ),
          GoRoute(
            path: '/couple/invitations/editor',
            builder: (_, state) => InvitationEditorScreen(
              invitationId: state.uri.queryParameters['id'],
            ),
          ),
          GoRoute(
            path: '/couple/invitations/:id/rsvp',
            builder: (_, state) => RsvpDashboardScreen(
              invitationId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // Vendor shell
      ShellRoute(
        builder: (context, state, child) => VendorShell(child: child),
        routes: [
          GoRoute(
            path: '/vendor/dashboard',
            builder: (_, __) => const VendorDashboardScreen(),
          ),
          GoRoute(
            path: '/vendor/profile',
            builder: (_, __) => const VendorProfileManagementScreen(),
          ),
          GoRoute(
            path: '/vendor/availability',
            builder: (_, __) => const AvailabilityCalendarScreen(),
          ),
          GoRoute(
            path: '/vendor/leads',
            builder: (_, __) => const LeadInboxScreen(),
          ),
          GoRoute(
            path: '/vendor/analytics',
            builder: (_, __) => const VendorAnalyticsScreen(),
          ),
          GoRoute(
            path: '/vendor/messages',
            builder: (_, __) => const VendorMessagesScreen(),
          ),
          GoRoute(
            path: '/vendor/subscription',
            builder: (_, __) => const SubscriptionScreen(),
          ),
        ],
      ),

      // Admin shell
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (_, __) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (_, __) => const UserManagementScreen(),
          ),
          GoRoute(
            path: '/admin/vendors/verification',
            builder: (_, __) => const VendorVerificationScreen(),
          ),
          GoRoute(
            path: '/admin/moderation',
            builder: (_, __) => const ContentModerationScreen(),
          ),
          GoRoute(
            path: '/admin/analytics',
            builder: (_, __) => const PlatformAnalyticsScreen(),
          ),
        ],
      ),

      // Shared routes
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/help', builder: (_, __) => const HelpScreen()),

      // Public invitation page
      GoRoute(
        path: '/i/:shareToken',
        builder: (_, state) => PublicInvitationScreen(
          shareToken: state.pathParameters['shareToken']!,
        ),
      ),
    ],
  );
});
