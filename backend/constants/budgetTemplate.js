// Server-side mirror of lib/core/constants/app_constants.dart's
// defaultBudgetAllocation / vendorCategoryIcons / budgetAIJustifications.
// Kept in sync manually — flagged here as a small, deliberate duplication of
// static config rather than a shared package, since first-run budget-category
// generation must happen server-side (see routes/budget.js).
const DEFAULT_BUDGET_ALLOCATION = {
  'Venue': 0.33,
  'Catering': 0.25,
  'Photography': 0.10,
  'Decor & flowers': 0.14,
  'DJ & MC': 0.05,
  'Transport': 0.03,
  'Wedding attire': 0.06,
  'Cake & sweets': 0.04,
};

const CATEGORY_ICONS = {
  'Venue': '🏛️',
  'Catering': '🍽️',
  'Photography': '📷',
  'Decor & flowers': '🌸',
  'DJ & MC': '🎵',
  'Transport': '🚗',
  'Wedding attire': '👗',
  'Cake & sweets': '🎂',
};

// Static rationale copy — must never be presented to users as "AI-generated"
// (no real AI call backs this text). See routes/budget.js.
const CATEGORY_JUSTIFICATIONS = {
  'Venue': 'Venues typically account for 30–35% of total wedding budgets.',
  'Catering': 'Catering costs scale with guest count, usually 22–28%.',
  'Photography': 'Professional photographers typically cost 8–12% of budget.',
  'Decor & flowers': 'Floral and décor arrangements typically account for 12–16%.',
  'DJ & MC': 'Entertainment usually costs 4–6% of total budget.',
  'Transport': 'Transportation usually accounts for 2–4%.',
  'Wedding attire': 'Attire and accessories typically run 5–8%.',
  'Cake & sweets': 'Wedding cakes and sweets typically account for 3–5%.',
};

// Mirrors BudgetService.createFromTemplate in lib/core/services/budget_service.dart:
// scale each category's weight against (total - customItemsTotal), add a
// "Custom Items" category if any custom items were supplied, and top up with
// a "Contingency" category if the weighted allocation undershoots the total.
function buildCategoriesFor(totalAmount, serviceCategories, customItems = []) {
  const names = (serviceCategories && serviceCategories.length)
    ? serviceCategories
    : Object.keys(DEFAULT_BUDGET_ALLOCATION);

  const customTotal = customItems.reduce((sum, i) => sum + Number(i.amount || 0), 0);
  const weights = names.map((n) => DEFAULT_BUDGET_ALLOCATION[n] ?? 0.05);
  const totalWeight = weights.reduce((s, w) => s + w, 0);
  const remaining = Math.max(0, Math.min(totalAmount, totalAmount - customTotal));
  const scale = totalWeight > 0 ? remaining / totalWeight : 0;

  const categories = names.map((name, i) => ({
    category_name: name,
    category_icon: CATEGORY_ICONS[name] ?? '💰',
    allocated_amount: Math.round(weights[i] * scale * 100) / 100,
    spent_amount: 0,
    ai_justification: CATEGORY_JUSTIFICATIONS[name] ?? null,
  }));

  if (customTotal > 0) {
    categories.push({
      category_name: 'Custom Items',
      category_icon: '🧾',
      allocated_amount: Math.round(customTotal * 100) / 100,
      spent_amount: 0,
      ai_justification: 'Special requests and one-off items you added.',
    });
  }

  const allocated = categories.reduce((s, c) => s + c.allocated_amount, 0);
  if (allocated < totalAmount) {
    categories.push({
      category_name: 'Contingency',
      category_icon: '🛡️',
      allocated_amount: Math.round((totalAmount - allocated) * 100) / 100,
      spent_amount: 0,
      ai_justification: 'Reserved for unexpected costs or last-minute upgrades.',
    });
  }

  return categories;
}

module.exports = { DEFAULT_BUDGET_ALLOCATION, CATEGORY_ICONS, CATEGORY_JUSTIFICATIONS, buildCategoriesFor };
