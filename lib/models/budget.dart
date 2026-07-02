class Budget {
  final String id;
  final String coupleId;
  final double totalAmount;
  final String currency;
  final bool isAiGenerated;
  final List<BudgetCategory> categories;
  final List<BudgetCustomItem> customItems;
  final DateTime createdAt;

  final List<Expense> expenses;

  const Budget({
    required this.id,
    required this.coupleId,
    required this.totalAmount,
    required this.currency,
    required this.isAiGenerated,
    required this.categories,
    this.customItems = const [],
    this.expenses = const [],
    required this.createdAt,
  });

  double get totalCustomAmount =>
      customItems.fold(0.0, (sum, item) => sum + item.amount);

  double get totalAllocated =>
      categories.fold(0.0, (sum, c) => sum + c.allocatedAmount);

  double get totalSpent =>
      categories.fold(0.0, (sum, c) => sum + c.spentAmount);

  double get remainingBudget => totalAmount - totalSpent;

  double get allocationVariance => totalAmount - totalAllocated;

  double get spendingPercentage =>
      totalAmount > 0 ? (totalSpent / totalAmount) * 100 : 0;

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        id: json['budget_id'] as String,
        coupleId: json['couple_id'] as String,
        totalAmount: (json['total_amount'] as num).toDouble(),
        currency: json['currency'] as String,
        isAiGenerated: json['is_ai_generated'] as bool,
        categories: (json['categories'] as List<dynamic>? ?? [])
            .map((c) => BudgetCategory.fromJson(c as Map<String, dynamic>))
            .toList(),
        customItems: (json['custom_items'] as List<dynamic>? ?? [])
            .map((c) => BudgetCustomItem.fromJson(c as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'budget_id': id,
        'couple_id': coupleId,
        'total_amount': totalAmount,
        'currency': currency,
        'is_ai_generated': isAiGenerated,
        'categories': categories.map((c) => c.toJson()).toList(),
        'custom_items': customItems.map((c) => c.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
      };
}

class BudgetCustomItem {
  final String id;
  final String name;
  final double amount;

  const BudgetCustomItem({
    required this.id,
    required this.name,
    required this.amount,
  });

  factory BudgetCustomItem.fromJson(Map<String, dynamic> json) => BudgetCustomItem(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
      };
}

class BudgetCategory {
  final String id;
  final String budgetId;
  final String categoryName;
  final String categoryIcon;
  final double allocatedAmount;
  final double spentAmount;
  final String? aiJustification;

  const BudgetCategory({
    required this.id,
    required this.budgetId,
    required this.categoryName,
    required this.categoryIcon,
    required this.allocatedAmount,
    required this.spentAmount,
    this.aiJustification,
  });

  double get remainingAmount => allocatedAmount - spentAmount;
  double get spendingPercent =>
      allocatedAmount > 0 ? (spentAmount / allocatedAmount) * 100 : 0;
  bool get isOverBudget => spentAmount > allocatedAmount;
  bool get isNearLimit => spendingPercent >= 90;

  factory BudgetCategory.fromJson(Map<String, dynamic> json) => BudgetCategory(
        id: json['id'] as String,
        budgetId: json['budget_id'] as String,
        categoryName: json['category_name'] as String,
        categoryIcon: json['category_icon'] as String? ?? '💰',
        allocatedAmount: (json['allocated_amount'] as num).toDouble(),
        spentAmount: (json['spent_amount'] as num? ?? 0).toDouble(),
        aiJustification: json['ai_justification'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'budget_id': budgetId,
        'category_name': categoryName,
        'category_icon': categoryIcon,
        'allocated_amount': allocatedAmount,
        'spent_amount': spentAmount,
        'ai_justification': aiJustification,
      };
}

class Expense {
  final String id;
  final String budgetId;
  final String categoryName;
  final String? vendorId;
  final String? vendorName;
  final double amount;
  final String description;
  final String? receiptUrl;
  final String status;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.budgetId,
    required this.categoryName,
    this.vendorId,
    this.vendorName,
    required this.amount,
    required this.description,
    this.receiptUrl,
    required this.status,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['expense_id'] as String,
        budgetId: json['budget_id'] as String,
        categoryName: json['category_name'] as String,
        vendorId: json['vendor_id'] as String?,
        vendorName: json['vendor_name'] as String?,
        amount: (json['amount'] as num).toDouble(),
        description: json['description'] as String,
        receiptUrl: json['receipt_url'] as String?,
        status: json['status'] as String? ?? 'pending',
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'expense_id': id,
        'budget_id': budgetId,
        'category_name': categoryName,
        'vendor_id': vendorId,
        'vendor_name': vendorName,
        'amount': amount,
        'description': description,
        'receipt_url': receiptUrl,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };
}
