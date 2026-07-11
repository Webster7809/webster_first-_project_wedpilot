class AppConstants {
  AppConstants._();

  static const String appName = 'WedPilot';
  static const String currency = 'ZMW';
  static const String baseUrl = 'https://api.wedpilot.app/api/v1';

  static const List<String> vendorCategories = [
    'Venue',
    'Catering',
    'Photography',
    'Decor & flowers',
    'DJ & MC',
    'Transport',
    'Wedding attire',
    'Cake & sweets',
  ];

  static const List<String> vendorCategoryIcons = [
    '🏛️', '🍽️', '📷', '🌸', '🎵', '🚗', '👗', '🎂',
  ];

  static const List<String> weddingTypes = [
    'White wedding',
    'Traditional',
    'Both',
  ];

  static const List<String> weddingStyles = [
    'Romantic', 'Modern', 'Rustic', 'Royal', 'Boho',
    'Beach', 'Garden', 'Vintage', 'Minimalist', 'Cultural',
  ];

  static const Map<String, double> defaultBudgetAllocation = {
    'Venue': 0.33,
    'Catering': 0.25,
    'Photography': 0.10,
    'Decor & flowers': 0.14,
    'DJ & MC': 0.05,
    'Transport': 0.03,
    'Wedding attire': 0.06,
    'Cake & sweets': 0.04,
  };

  static const Map<String, String> budgetAIJustifications = {
    'Venue': 'Venues typically account for 30–35% of total wedding budgets.',
    'Catering': 'Catering costs scale with guest count, usually 22–28%.',
    'Photography': 'Professional photographers typically cost 8–12% of budget.',
    'Decor & flowers': 'Floral and décor arrangements typically account for 12–16%.',
    'DJ & MC': 'Entertainment usually costs 4–6% of total budget.',
    'Transport': 'Transportation usually accounts for 2–4%.',
    'Wedding attire': 'Attire and accessories typically run 5–8%.',
    'Cake & sweets': 'Wedding cakes and sweets typically account for 3–5%.',
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
  static const int maxFileUploadMB = 10;
  static const int rsvpReminderCooldownSeconds = 60;
}
