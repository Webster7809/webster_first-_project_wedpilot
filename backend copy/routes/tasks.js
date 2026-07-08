const express = require('express');
const { Op } = require('sequelize');
const Task = require('../db/models/task');
const Vendor = require('../db/models/vendor');
const verifyJwt = require('../middleware/verifyJwt');
const { requireCouple } = require('../middleware/roles');

const router = express.Router();

function serializeTask(task, vendorName = null) {
  return {
    id: task.task_id,
    couple_id: task.couple_user_id,
    phase: task.phase,
    task: task.task,
    is_completed: task.is_completed,
    due_date: task.due_date,
    linked_vendor_id: task.linked_vendor_id,
    linked_vendor_name: vendorName,
  };
}

/// Batch-resolves each task's linked vendor's current business_name.
async function serializeTasks(tasks) {
  const vendorIds = [...new Set(tasks.map((t) => t.linked_vendor_id).filter(Boolean))];
  if (vendorIds.length === 0) return tasks.map((t) => serializeTask(t));

  const vendors = await Vendor.findAll({ where: { vendor_id: { [Op.in]: vendorIds } } });
  const nameById = new Map(vendors.map((v) => [v.vendor_id, v.business_name]));
  return tasks.map((t) => serializeTask(t, t.linked_vendor_id ? nameById.get(t.linked_vendor_id) ?? null : null));
}

function validateTaskBody(body, { partial = false } = {}) {
  if (!partial || body.task !== undefined) {
    if (typeof body.task !== 'string' || body.task.trim().length < 3) {
      return 'Task name must be at least 3 characters.';
    }
  }
  if (!partial || body.phase !== undefined) {
    if (typeof body.phase !== 'string' || body.phase.trim().length === 0) {
      return 'A planning phase must be selected.';
    }
  }
  return null;
}

// ── GET /api/tasks ──────────────────────────────────────────────────────────────
router.get('/', verifyJwt, requireCouple, async (req, res) => {
  try {
    const tasks = await Task.findAll({
      where: { couple_user_id: req.user.user_id },
      order: [['created_at', 'ASC']],
    });
    res.json({ tasks: await serializeTasks(tasks) });
  } catch (err) {
    console.error('List tasks error:', err.message);
    res.status(500).json({ error: 'Could not load tasks.' });
  }
});

// ── POST /api/tasks ─────────────────────────────────────────────────────────────
router.post('/', verifyJwt, requireCouple, async (req, res) => {
  const error = validateTaskBody(req.body);
  if (error) return res.status(400).json({ error });

  try {
    const task = await Task.create({
      couple_user_id: req.user.user_id,
      phase: req.body.phase,
      task: req.body.task.trim(),
      due_date: req.body.due_date ?? null,
      linked_vendor_id: req.body.linked_vendor_id ?? null,
    });
    const [serialized] = await serializeTasks([task]);
    res.status(201).json({ task: serialized });
  } catch (err) {
    console.error('Create task error:', err.message);
    res.status(500).json({ error: 'Could not create task.' });
  }
});

// ── PUT /api/tasks/:id ──────────────────────────────────────────────────────────
router.put('/:id', verifyJwt, requireCouple, async (req, res) => {
  const error = validateTaskBody(req.body, { partial: true });
  if (error) return res.status(400).json({ error });

  try {
    const task = await Task.findOne({
      where: { task_id: req.params.id, couple_user_id: req.user.user_id },
    });
    if (!task) return res.status(404).json({ error: 'Task not found.' });

    const fields = {};
    if (req.body.task !== undefined) fields.task = req.body.task.trim();
    if (req.body.phase !== undefined) fields.phase = req.body.phase;
    if (req.body.clear_due_date === true) {
      fields.due_date = null;
    } else if (req.body.due_date !== undefined) {
      fields.due_date = req.body.due_date;
    }

    task.set(fields);
    await task.save();
    const [serialized] = await serializeTasks([task]);
    res.json({ task: serialized });
  } catch (err) {
    console.error('Update task error:', err.message);
    res.status(500).json({ error: 'Could not update task.' });
  }
});

// ── PATCH /api/tasks/:id/toggle ─────────────────────────────────────────────────
router.patch('/:id/toggle', verifyJwt, requireCouple, async (req, res) => {
  try {
    const task = await Task.findOne({
      where: { task_id: req.params.id, couple_user_id: req.user.user_id },
    });
    if (!task) return res.status(404).json({ error: 'Task not found.' });

    task.is_completed = !task.is_completed;
    await task.save();
    const [serialized] = await serializeTasks([task]);
    res.json({ task: serialized });
  } catch (err) {
    console.error('Toggle task error:', err.message);
    res.status(500).json({ error: 'Could not update task.' });
  }
});

// ── DELETE /api/tasks/:id ───────────────────────────────────────────────────────
router.delete('/:id', verifyJwt, requireCouple, async (req, res) => {
  try {
    const deleted = await Task.destroy({
      where: { task_id: req.params.id, couple_user_id: req.user.user_id },
    });
    if (!deleted) return res.status(404).json({ error: 'Task not found.' });
    res.status(204).send();
  } catch (err) {
    console.error('Delete task error:', err.message);
    res.status(500).json({ error: 'Could not delete task.' });
  }
});

module.exports = router;
