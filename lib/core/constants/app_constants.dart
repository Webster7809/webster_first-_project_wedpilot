class AppConstants {
  AppConstants._();

  static const String appName = 'Wedpilot';
  static const String baseUrl = 'https://api.wedpilot.app/api/v1';

  static const List<String> vendorCategories = [
    'Venue',
    'Catering',
    'Photography',
    'Videography',
    'Floristry',
    'Music',
    'Cake',
    'Hair & Makeup',
    'Transport',
    'Officiant',
    'Stationery',
    'Accommodation',
  ];

  static const List<String> vendorCategoryIcons = [
    '🏛️', '🍽️', '📷', '🎬', '💐', '🎵',
    '🎂', '💄', '🚗', '💒', '✉️', '🏨',
  ];

  static const List<String> weddingStyles = [
    'Romantic', 'Modern', 'Rustic', 'Royal', 'Boho',
    'Beach', 'Garden', 'Vintage', 'Minimalist', 'Cultural',
  ];

  static const Map<String, double> defaultBudgetAllocation = {
    'Venue': 0.30,
    'Catering': 0.25,
    'Photography': 0.10,
    'Videography': 0.06,
    'Floristry': 0.07,
    'Music': 0.05,
    'Cake': 0.02,
    'Hair & Makeup': 0.03,
    'Transport': 0.02,
    'Officiant': 0.02,
    'Stationery': 0.02,
    'Accommodation': 0.06,
  };

  static const Map<String, String> budgetAIJustifications = {
    'Venue': 'Venues typically account for 28–32% of total wedding budgets.',
    'Catering': 'Catering costs scale with guest count, usually 20–28%.',
    'Photography': 'Professional photographers typically cost 10–12% of budget.',
    'Videography': 'Videography usually runs 5–8% of total budget.',
    'Floristry': 'Floral arrangements typically account for 6–8%.',
    'Music': 'Live bands or DJs usually cost 4–6% of total budget.',
    'Cake': 'Wedding cakes typically account for 1.5–2.5%.',
    'Hair & Makeup': 'Beauty services typically run 2–4%.',
    'Transport': 'Transportation usually accounts for 1.5–2.5%.',
    'Officiant': 'Officiant fees typically range 1–3%.',
    'Stationery': 'Invitations and stationery usually run 1.5–2.5%.',
    'Accommodation': 'Guest accommodation blocks typically account for 5–7%.',
  };

  static const List<String> planningChecklistPhases = [
    '12+ Months Before',
    '9–12 Months Before',
    '6–9 Months Before',
    '3–6 Months Before',
    '1–3 Months Before',
    '1 Month Before',
    'Week Of',
    'Day Of',
  ];

  static const int accessTokenExpiryMinutes = 15;
  static const int refreshTokenExpiryDays = 30;
  static const int maxPortfolioImages = 50;
  static const int maxPortfolioVideos = 5;
  static const int maxReviewPhotos = 5;
  static const int maxFileUploadMB = 10;
  static const int rsvpReminderCooldownSeconds = 60;
}
