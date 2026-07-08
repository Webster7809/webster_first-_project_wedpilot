class AppRoutes {
  // ── Pre-auth ────────────────────────────────────────────────────────────
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const verifyEmail = '/verify-email';
  static const couplePlanning = '/couple-planning';
  static const vendorOnboarding = '/vendor-onboarding';

  // ── Public (no auth) ────────────────────────────────────────────────────
  static const publicInvite = '/i/:shareToken';
  static const publicGuestInvite = '/g/:inviteToken';

  // ── Shared full-screen pushes ────────────────────────────────────────────
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const help = '/help';
  static const coupleReports = '/couple/reports';

  // ── Couple ───────────────────────────────────────────────────────────────
  static const coupleDashboard = '/couple/dashboard';
  static const coupleVendors = '/couple/vendors';
  static const coupleVendorDetail = '/couple/vendors/:id';
  static const coupleBudget = '/couple/budget';
  static const coupleEditPlan = '/couple/plan-setup';
  static const coupleBudgetShare = '/couple/budget/share';
  static const coupleExpenseNew = '/couple/budget/expense/new';
  static const coupleInvitations = '/couple/invitations';
  static const coupleInvitationEditor = '/couple/invitations/editor';
  static const coupleMessages = '/couple/messages';
  static const coupleChat = '/couple/messages/:convoId';
  static const coupleChecklist = '/couple/checklist';
  static const coupleWishlist = '/couple/wishlist';
  static const coupleReviewNew = '/couple/reviews/new';
  static const coupleProfile = '/couple/profile';

  // ── Vendor ───────────────────────────────────────────────────────────────
  static const vendorDashboard = '/vendor/dashboard';
  static const vendorListings = '/vendor/listings';
  static const vendorLeads = '/vendor/leads';
  static const vendorReviews = '/vendor/reviews';
  static const vendorAccount = '/vendor/account';
  static const vendorAnalytics = '/vendor/analytics';
  static const vendorMessages = '/vendor/messages';
  static const vendorChat = '/vendor/messages/:convoId';
  static const vendorAvailability = '/vendor/availability';
  static const vendorSubscription = '/vendor/subscription';

  // ── Admin ────────────────────────────────────────────────────────────────
  static const adminDashboard = '/admin/dashboard';
  static const adminUsers = '/admin/users';
  static const adminVendors = '/admin/vendors';
  static const adminAnalytics = '/admin/analytics';
  static const adminModeration = '/admin/moderation';
  static const adminCategories = '/admin/categories';
  static const adminInvitationTemplates = '/admin/invitation-templates';

  // ── Role prefixes (used in redirect guards) ─────────────────────────────
  static const couplePrefix = '/couple';
  static const vendorPrefix = '/vendor';
  static const adminPrefix = '/admin';

  // ── Auth screens set (used in redirect guard) ───────────────────────────
  // couplePlanning/vendorOnboarding are intentionally excluded: they double as
  // the post-creation vendor-guide step (PDF share/download), which renders
  // after needsOnboarding flips to false — including them here would bounce
  // the user straight to their dashboard before that final step ever shows.
  static const authScreens = {login, register, forgotPassword, verifyEmail};
}
