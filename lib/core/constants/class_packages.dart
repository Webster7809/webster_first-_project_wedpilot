import '../../models/budget_class.dart';

/// Per-category package inclusions that come with a wedding-class choice —
/// static product content (like [AppConstants.budgetAIJustifications]), not
/// vendor data. High Class bundles a full luxury package on every category,
/// Flexible a lighter starter package, and Budget-Friendly deliberately none:
/// the absence is what keeps that tier honest about "you pay for the service
/// itself, nothing bundled on top".
class ClassPackages {
  ClassPackages._();

  static String? labelFor(BudgetClass bc) => switch (bc) {
        BudgetClass.highClass => 'LUXURY PACKAGE — INCLUDED',
        BudgetClass.flexible => 'STARTER PACKAGE — INCLUDED',
        BudgetClass.budgetFriendly => null,
      };

  static String? taglineFor(BudgetClass bc) => switch (bc) {
        BudgetClass.highClass =>
          'A signature premium experience reserved for High Class weddings.',
        BudgetClass.flexible =>
          'A few bundled perks — lighter than High Class, more than Budget-Friendly.',
        BudgetClass.budgetFriendly => null,
      };

  /// Inclusions for [category] under [bc]; empty means "show no package".
  static List<String> inclusionsFor(BudgetClass bc, String category) =>
      switch (bc) {
        BudgetClass.highClass =>
          _luxury[category] ?? _genericLuxury,
        BudgetClass.flexible =>
          _starter[category] ?? _genericStarter,
        BudgetClass.budgetFriendly => const [],
      };

  static const _luxury = <String, List<String>>{
    'Venue': [
      'Exclusive venue hire with private grounds',
      'Dedicated event concierge & day-of coordinator',
      'Valet parking and red-carpet guest arrival',
      'Champagne welcome reception',
    ],
    'Catering': [
      'Chef-curated multi-course gourmet menu',
      'Private tasting session for the couple',
      'Full waitstaff, premium tableware & bar service',
      'Signature cocktail and dessert stations',
    ],
    'Photography': [
      'Two lead photographers plus cinematic video team',
      'Full-day coverage including drone footage',
      'Luxury printed album & same-week highlight reel',
      'Complimentary pre-wedding photoshoot',
    ],
    'Decor & flowers': [
      'Bespoke floral design with premium blooms',
      'Full venue styling, lighting & draping',
      'Statement arch and centerpiece installations',
      'On-site florist team throughout the event',
    ],
    'DJ & MC': [
      'Headline DJ with professional MC duo',
      'Concert-grade sound & intelligent lighting rig',
      'Custom playlist consultation & live requests',
      'Dance-floor effects package',
    ],
    'Transport': [
      'Chauffeured luxury bridal car',
      'Guest shuttle fleet coordination',
      'Decorated convoy with standby backup vehicle',
      'Red-carpet arrival service',
    ],
    'Wedding attire': [
      'Designer gown & tailored suit consultation',
      'Private fittings with an in-house stylist',
      'Accessories, veil & grooming package',
      'Day-of dressing assistance',
    ],
    'Cake & sweets': [
      'Multi-tier designer cake with custom detailing',
      'Private tasting with the pastry chef',
      'Luxury dessert & chocolate bar for guests',
      'Guest favor boxes included',
    ],
  };

  static const _genericLuxury = <String>[
    'Premium white-glove service package',
    'Dedicated coordinator for this service',
    'Priority scheduling & on-site support',
  ];

  static const _starter = <String, List<String>>{
    'Venue': [
      'Standard hall setup with seating & basic décor',
      'On-site coordinator on the day',
    ],
    'Catering': [
      'Set buffet menu with service staff',
      'Menu tasting on request',
    ],
    'Photography': [
      'Full-ceremony coverage by a lead photographer',
      'Edited digital gallery with highlights',
    ],
    'Decor & flowers': [
      'Fresh seasonal arrangements & venue styling',
      'Head-table and arch décor',
    ],
    'DJ & MC': [
      'Professional DJ set with MC support',
      'Standard sound & lighting package',
    ],
    'Transport': [
      'Decorated bridal car with chauffeur',
      'Flexible pickup schedule',
    ],
    'Wedding attire': [
      'Fitting session with alteration support',
      'Accessory add-ons at package rates',
    ],
    'Cake & sweets': [
      'Two-tier custom cake',
      'Flavor tasting included',
    ],
  };

  static const _genericStarter = <String>[
    'Standard service package included',
    'Basic day-of support',
  ];
}
