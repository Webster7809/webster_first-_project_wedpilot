/// The couple's stated wedding-class preference — drives both AI
/// vendor-ranking weights and which rating band is preferred when picking a
/// vendor for each category (see `VendorFilteringService.preferredByWeddingClass`).
enum BudgetClass {
  highClass,
  flexible,
  budgetFriendly;

  String get displayName => switch (this) {
        BudgetClass.highClass => 'High Class',
        BudgetClass.flexible => 'Flexible',
        BudgetClass.budgetFriendly => 'Budget-Friendly',
      };

  String get icon => switch (this) {
        BudgetClass.highClass => '👑',
        BudgetClass.flexible => '⚖️',
        BudgetClass.budgetFriendly => '💚',
      };

  String get subtitle => switch (this) {
        BudgetClass.highClass => 'Luxury & Premium Only',
        BudgetClass.flexible => 'Best Value, Proven Track Record',
        BudgetClass.budgetFriendly => 'Affordable First',
      };

  String get description => switch (this) {
        BudgetClass.highClass =>
          'Exclusive curation of premium vendors — top-rated, luxury-tier, celebrated for extraordinary weddings.',
        BudgetClass.flexible =>
          'AI-optimised mix of vendors with a solid, verified track record and the best quality-to-price balance — the intelligent middle ground between luxury and budget.',
        BudgetClass.budgetFriendly =>
          'Cost-conscious vendors, including newer and not-yet-rated ones — the best way to stretch your budget further.',
      };

  List<String> get features => switch (this) {
        BudgetClass.highClass => [
            '4.5★ or higher only',
            'Premium tier vendors',
            'Top portfolio & brand reputation',
            'Luxury package included on every category',
          ],
        BudgetClass.flexible => [
            'Best quality-to-price ratio',
            '3.5★ or higher, verified track record',
            'Intelligent AI-balanced mix',
            'Starter package included per category',
          ],
        BudgetClass.budgetFriendly => [
            'Under 3.5★ or not yet rated',
            'Affordable pricing tier',
            'Best price-to-value match',
            'No bundled packages — lowest price, pure and simple',
          ],
      };
}
