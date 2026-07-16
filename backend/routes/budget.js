const express = require('express');
const Budget = require('../db/models/budget');
const BudgetCategory = require('../db/models/budgetCategory');
const BudgetCustomItem = require('../db/models/budgetCustomItem');
const Expense = require('../db/models/expense');
const CoupleProfile = require('../db/models/coupleProfile');
const Notification = require('../db/models/notification');
const verifyJwt = require('../middleware/verifyJwt');
const { requireCouple } = require('../middleware/roles');
const { makeUploader, relativeUploadUrl } = require('../middleware/upload');
const { buildCategoriesFor } = require('../constants/budgetTemplate');

const router = express.Router();
const receiptUploader = makeUploader('receipts', { allowedMimePrefixes: ['image/'], maxSizeMb: 8 });

// ── Serialization ────────────────────────────────────────────────────────────────

function serializeCategory(c) {
  return {
    id: c.id,
    budget_id: c.budget_id,
    category_name: c.category_name,
    category_icon: c.category_icon,
    allocated_amount: Number(c.allocated_amount),
    spent_amount: Number(c.spent_amount),
    ai_justification: c.ai_justification,
  };
}

function serializeCustomItem(i) {
  return { id: i.id, name: i.name, amount: Number(i.amount) };
}

function serializeExpense(e) {
  return {
    expense_id: e.expense_id,
    budget_id: e.budget_id,
    category_name: e.category_name,
    vendor_id: e.vendor_id,
    vendor_name: e.vendor_name,
    amount: Number(e.amount),
    description: e.description,
    receipt_url: e.receipt_url,
    status: e.status,
    created_at: e.created_at,
  };
}

async function serializeBudget(budget) {
  const [categories, customItems, expenses] = await Promise.all([
    BudgetCategory.findAll({ where: { budget_id: budget.budget_id } }),
    BudgetCustomItem.findAll({ where: { budget_id: budget.budget_id } }),
    Expense.findAll({ where: { budget_id: budget.budget_id }, order: [['created_at', 'DESC']] }),
  ]);
  return {
    budget_id: budget.budget_id,
    couple_id: budget.couple_user_id,
    total_amount: Number(budget.total_amount),
    currency: budget.currency,
    is_ai_generated: budget.is_ai_generated,
    categories: categories.map(serializeCategory),
    custom_items: customItems.map(serializeCustomItem),
    expenses: expenses.map(serializeExpense),
    created_at: budget.created_at,
  };
}

async function findOwnBudgetOr404(req, res) {
  const budget = await Budget.findOne({ where: { couple_user_id: req.user.user_id } });
  if (!budget) {
    res.status(404).json({ error: 'No budget yet.' });
    return null;
  }
  return budget;
}

// Keeps a budget's category rows in sync on every repeat POST — two things:
//  1. Rescale: a category counts as "still auto-generated" when its
//     allocated_amount exactly matches what buildCategoriesFor would have
//     produced for it at the budget's *previous* total — i.e. the couple
//     never manually re-allocated it via PUT /categories/:id. Only those get
//     rescaled to track the new total_amount; anything deliberately
//     customized is left exactly as set. Without this, a category's
//     allocated_amount stays frozen at whatever number it was first computed
//     against, silently going nonsensical once total_amount changes — e.g.
//     "2,499,900% over budget" instead of tracking the couple's real budget.
//  2. Backfill: any category the couple has now selected (service_categories
//     on this request) that has no row at all yet — e.g. their very first
//     budget only covered one category, or they've added more on a later
//     wizard run — gets created fresh at its template share of the total.
//     Without this, a category can be permanently missing from the budget
//     breakdown and from the AI vendor matcher's per-category budget, no
//     matter how many times total_amount is later corrected.
// Never deletes or overrides a row the couple hasn't touched via this sync.
async function syncCategoriesForNewTotal(budget, oldTotal, newTotal, requestedNames) {
  const [existingCategories, existingCustomItems] = await Promise.all([
    BudgetCategory.findAll({ where: { budget_id: budget.budget_id } }),
    BudgetCustomItem.findAll({ where: { budget_id: budget.budget_id } }),
  ]);
  const existingNames = existingCategories
    .map((c) => c.category_name)
    .filter((n) => n !== 'Custom Items' && n !== 'Contingency');
  const allNames = [...new Set([...existingNames, ...(Array.isArray(requestedNames) ? requestedNames : [])])];
  if (allNames.length === 0) return;

  const customItemInputs = existingCustomItems.map((i) => ({ amount: Number(i.amount) }));
  // What each existing category's amount *should* have been under the
  // selection that was actually active last time (existingNames) — not
  // allNames. Using allNames here would pull in categories the couple is
  // only adding *now*, shifting the weight-renormalization base for every
  // pre-existing category and making the diff check below spuriously think
  // the couple had manually customized it, freezing it at its old amount
  // forever instead of rescaling it to the new total.
  const oldByName = Object.fromEntries(
    buildCategoriesFor(oldTotal, existingNames, customItemInputs).map((c) => [c.category_name, c.allocated_amount]),
  );
  const newTemplate = buildCategoriesFor(newTotal, allNames, customItemInputs);
  const newByName = Object.fromEntries(newTemplate.map((c) => [c.category_name, c]));

  for (const cat of existingCategories) {
    const wasTemplate = oldByName[cat.category_name];
    const nowTemplate = newByName[cat.category_name];
    if (wasTemplate == null || nowTemplate == null) continue;
    if (Math.abs(Number(cat.allocated_amount) - wasTemplate) >= 0.01) continue; // manually customized — leave it
    cat.allocated_amount = Math.max(nowTemplate.allocated_amount, Number(cat.spent_amount));
    await cat.save();
  }

  const existingNameSet = new Set(existingCategories.map((c) => c.category_name));
  const missingNames = allNames.filter((n) => !existingNameSet.has(n));
  if (missingNames.length) {
    await BudgetCategory.bulkCreate(
      missingNames.map((name) => ({ ...newByName[name], budget_id: budget.budget_id })),
    );
  }
}

// ── POST /api/budget ────────────────────────────────────────────────────────────
// Explicit create/update. Generates categories from the template only when no
// budget exists yet; on repeat calls it updates total_amount/currency and
// syncs categories (rescale + backfill any missing ones — see
// syncCategoriesForNewTotal) so the couple's current selection and total are
// always fully reflected.
router.post('/', verifyJwt, requireCouple, async (req, res) => {
  const { total_amount, currency, service_categories, custom_items } = req.body;
  if (typeof total_amount !== 'number' || total_amount < 0) {
    return res.status(400).json({ error: 'total_amount must be a non-negative number.' });
  }

  try {
    let budget = await Budget.findOne({ where: { couple_user_id: req.user.user_id } });
    if (budget) {
      const oldTotal = Number(budget.total_amount);
      budget.total_amount = total_amount;
      if (currency) budget.currency = currency;
      await budget.save();
      await syncCategoriesForNewTotal(budget, oldTotal, total_amount, service_categories);
      return res.json({ budget: await serializeBudget(budget) });
    }

    budget = await Budget.create({
      couple_user_id: req.user.user_id,
      total_amount,
      currency: currency || 'ZMW',
      is_ai_generated: true,
    });

    const customItemRows = Array.isArray(custom_items) ? custom_items : [];
    if (customItemRows.length) {
      await BudgetCustomItem.bulkCreate(
        customItemRows.map((i) => ({ budget_id: budget.budget_id, name: i.name, amount: i.amount })),
      );
    }
    const categories = buildCategoriesFor(total_amount, service_categories, customItemRows);
    await BudgetCategory.bulkCreate(categories.map((c) => ({ ...c, budget_id: budget.budget_id })));

    res.status(201).json({ budget: await serializeBudget(budget) });
  } catch (err) {
    console.error('Create/update budget error:', err.message);
    res.status(500).json({ error: 'Could not save budget.' });
  }
});

// ── GET /api/budget ─────────────────────────────────────────────────────────────
// Fetch; lazily auto-creates from the template only if the couple's profile
// already has a total_budget set (a resumed-session safety net for someone
// who reaches the dashboard without going through the wizard's POST above).
router.get('/', verifyJwt, requireCouple, async (req, res) => {
  try {
    let budget = await Budget.findOne({ where: { couple_user_id: req.user.user_id } });
    if (!budget) {
      const profile = await CoupleProfile.findOne({ where: { user_id: req.user.user_id } });
      if (!profile || profile.total_budget == null) {
        return res.status(404).json({ error: 'No budget yet.' });
      }
      budget = await Budget.create({
        couple_user_id: req.user.user_id,
        total_amount: profile.total_budget,
        currency: profile.currency || 'ZMW',
        is_ai_generated: true,
      });
      const categories = buildCategoriesFor(Number(profile.total_budget), profile.style_tags, []);
      await BudgetCategory.bulkCreate(categories.map((c) => ({ ...c, budget_id: budget.budget_id })));
    }
    res.json({ budget: await serializeBudget(budget) });
  } catch (err) {
    console.error('Get budget error:', err.message);
    res.status(500).json({ error: 'Could not load budget.' });
  }
});

// ── PUT /api/budget/categories/:id ──────────────────────────────────────────────
router.put('/categories/:id', verifyJwt, requireCouple, async (req, res) => {
  try {
    const budget = await findOwnBudgetOr404(req, res);
    if (!budget) return;
    const category = await BudgetCategory.findOne({ where: { id: req.params.id, budget_id: budget.budget_id } });
    if (!category) return res.status(404).json({ error: 'Category not found.' });

    const { allocated_amount } = req.body;
    if (typeof allocated_amount !== 'number' || allocated_amount < 0) {
      return res.status(400).json({ error: 'allocated_amount must be a non-negative number.' });
    }
    if (allocated_amount < Number(category.spent_amount)) {
      return res.status(400).json({
        error: `Cannot allocate less than already spent (${budget.currency} ${Number(category.spent_amount).toFixed(2)}).`,
      });
    }

    category.allocated_amount = allocated_amount;
    await category.save();
    res.json({ category: serializeCategory(category) });
  } catch (err) {
    console.error('Update category error:', err.message);
    res.status(500).json({ error: 'Could not update category.' });
  }
});

// ── Expenses ─────────────────────────────────────────────────────────────────────

router.post('/expenses', verifyJwt, requireCouple, receiptUploader.single('receipt'), async (req, res) => {
  try {
    const budget = await findOwnBudgetOr404(req, res);
    if (!budget) return;

    const { category_name, amount, description, vendor_id, vendor_name } = req.body;
    const amountNum = Number(amount);
    if (!category_name) return res.status(400).json({ error: 'category_name is required.' });
    if (!Number.isFinite(amountNum) || amountNum <= 0) {
      return res.status(400).json({ error: 'amount must be a positive number.' });
    }
    if (!description || description.trim().length < 3) {
      return res.status(400).json({ error: 'Description must be at least 3 characters.' });
    }

    const category = await BudgetCategory.findOne({ where: { budget_id: budget.budget_id, category_name } });
    if (!category) return res.status(400).json({ error: 'Selected category does not exist in this budget.' });

    const receiptUrl = req.file ? relativeUploadUrl('receipts', req.file.filename) : null;
    const expense = await Expense.create({
      budget_id: budget.budget_id,
      category_name,
      vendor_id: vendor_id || null,
      vendor_name: vendor_name || null,
      amount: amountNum,
      description: description.trim(),
      receipt_url: receiptUrl,
      status: 'paid',
    });

    const allocated = Number(category.allocated_amount);
    const previousRatio = allocated > 0 ? Number(category.spent_amount) / allocated : 0;
    category.spent_amount = Number(category.spent_amount) + amountNum;
    await category.save();
    const newRatio = allocated > 0 ? Number(category.spent_amount) / allocated : 0;

    // Only fire the moment a category first crosses 90%, not on every
    // subsequent expense once it's already over.
    if (previousRatio < 0.9 && newRatio >= 0.9) {
      await Notification.create({
        user_id: req.user.user_id,
        type: 'budget_alert',
        title: 'Budget alert',
        body: `${category.category_name} category is at ${Math.round(newRatio * 100)}% of your allocation.`,
        entity_id: category.id,
        entity_type: 'budget_category',
      });
    }

    res.status(201).json({ expense: serializeExpense(expense) });
  } catch (err) {
    console.error('Add expense error:', err.message);
    res.status(500).json({ error: 'Could not add expense.' });
  }
});

router.delete('/expenses/:id', verifyJwt, requireCouple, async (req, res) => {
  try {
    const budget = await findOwnBudgetOr404(req, res);
    if (!budget) return;
    const expense = await Expense.findOne({ where: { expense_id: req.params.id, budget_id: budget.budget_id } });
    if (!expense) return res.status(404).json({ error: 'Expense not found.' });

    const category = await BudgetCategory.findOne({ where: { budget_id: budget.budget_id, category_name: expense.category_name } });
    if (category) {
      category.spent_amount = Math.max(0, Number(category.spent_amount) - Number(expense.amount));
      await category.save();
    }

    await expense.destroy();
    res.status(204).send();
  } catch (err) {
    console.error('Delete expense error:', err.message);
    res.status(500).json({ error: 'Could not delete expense.' });
  }
});

// ── Custom items ─────────────────────────────────────────────────────────────────

router.post('/custom-items', verifyJwt, requireCouple, async (req, res) => {
  try {
    const budget = await findOwnBudgetOr404(req, res);
    if (!budget) return;
    const { name, amount } = req.body;
    if (!name || typeof amount !== 'number' || amount <= 0) {
      return res.status(400).json({ error: 'name and a positive amount are required.' });
    }
    const item = await BudgetCustomItem.create({ budget_id: budget.budget_id, name, amount });
    res.status(201).json({ custom_item: serializeCustomItem(item) });
  } catch (err) {
    console.error('Add custom item error:', err.message);
    res.status(500).json({ error: 'Could not add item.' });
  }
});

router.delete('/custom-items/:id', verifyJwt, requireCouple, async (req, res) => {
  try {
    const budget = await findOwnBudgetOr404(req, res);
    if (!budget) return;
    const deleted = await BudgetCustomItem.destroy({ where: { id: req.params.id, budget_id: budget.budget_id } });
    if (!deleted) return res.status(404).json({ error: 'Item not found.' });
    res.status(204).send();
  } catch (err) {
    console.error('Delete custom item error:', err.message);
    res.status(500).json({ error: 'Could not delete item.' });
  }
});

module.exports = router;
