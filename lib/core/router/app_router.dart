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
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (_, _) => const EmailVerifyScreen(),
      ),

      // Couple shell
      ShellRoute(
        builder: (context, state, child) => CoupleShell(child: child),
        routes: [
          GoRoute(
            path: '/couple/dashboard',
            builder: (_, _) => const CoupleDashboardScreen(),
          ),
          GoRoute(
            path: '/couple/vendors',
            builder: (_, _) => const VendorDiscoveryScreen(),
          ),
          GoRoute(
            path: '/couple/vendors/:id',
            builder: (_, state) =>
                VendorProfileScreen(vendorId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/couple/wishlist',
            builder: (_, _) => const WishlistScreen(),
          ),
          GoRoute(
            path: '/couple/messages',
            builder: (_, _) => const CoupleMessagesScreen(),
          ),
          GoRoute(
            path: '/couple/messages/:convoId',
            builder: (_, state) =>
                ChatScreen(convoId: state.pathParameters['convoId']!),
          ),
          GoRoute(
            path: '/couple/budget',
            builder: (_, _) => const BudgetOverviewScreen(),
          ),
          GoRoute(
            path: '/couple/budget/setup',
            builder: (_, _) => const BudgetSetupWizardScreen(),
          ),
          GoRoute(
            path: '/couple/budget/expense/new',
            builder: (_, _) => const ExpenseEntryScreen(),
          ),
          GoRoute(
            path: '/couple/checklist',
            builder: (_, _) => const PlanningChecklistScreen(),
          ),
          GoRoute(
            path: '/couple/reviews/new',
            builder: (_, _) => const ReviewSubmissionScreen(),
          ),
          GoRoute(
            path: '/couple/invitations',
            builder: (_, _) => const InvitationGalleryScreen(),
          ),
          GoRoute(
            path: '/couple/invitations/editor',
            builder: (_, state) => InvitationEditorScreen(
              invitationId: state.uri.queryParameters['id'],
            ),
          ),
          GoRoute(
            path: '/couple/invitations/:id/rsvp',
            builder: (_, state) =>
                RsvpDashboardScreen(invitationId: state.pathParameters['id']!),
          ),
        ],
      ),

      // Vendor shell
      ShellRoute(
        builder: (context, state, child) => VendorShell(child: child),
        routes: [
          GoRoute(
            path: '/vendor/dashboard',
            builder: (_, _) => const VendorDashboardScreen(),
          ),
          GoRoute(
            path: '/vendor/profile',
            builder: (_, _) => const VendorProfileManagementScreen(),
          ),
          GoRoute(
            path: '/vendor/availability',
            builder: (_, _) => const AvailabilityCalendarScreen(),
          ),
          GoRoute(
            path: '/vendor/leads',
            builder: (_, _) => const LeadInboxScreen(),
          ),
          GoRoute(
            path: '/vendor/analytics',
            builder: (_, _) => const VendorAnalyticsScreen(),
          ),
          GoRoute(
            path: '/vendor/messages',
            builder: (_, _) => const VendorMessagesScreen(),
          ),
          GoRoute(
            path: '/vendor/subscription',
            builder: (_, _) => const SubscriptionScreen(),
          ),
        ],
      ),

      // Admin shell
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (_, _) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (_, _) => const UserManagementScreen(),
          ),
          GoRoute(
            path: '/admin/vendors/verification',
            builder: (_, _) => const VendorVerificationScreen(),
          ),
          GoRoute(
            path: '/admin/moderation',
            builder: (_, _) => const ContentModerationScreen(),
          ),
          GoRoute(
            path: '/admin/analytics',
            builder: (_, _) => const PlatformAnalyticsScreen(),
          ),
        ],
      ),

      // Shared routes
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/help', builder: (_, _) => const HelpScreen()),

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
