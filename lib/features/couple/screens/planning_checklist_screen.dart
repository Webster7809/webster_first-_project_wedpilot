import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/checklist_item.dart';
import '../../../providers/task_provider.dart';
import '../../../widgets/wed_snack_bar.dart';

class PlanningChecklistScreen extends ConsumerStatefulWidget {
  const PlanningChecklistScreen({super.key});

  @override
  ConsumerState<PlanningChecklistScreen> createState() =>
      _PlanningChecklistScreenState();
}

class _PlanningChecklistScreenState
    extends ConsumerState<PlanningChecklistScreen> {
  String _filterPhase = 'All';

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskProvider);
    final progress = ref.watch(taskProgressProvider);
    final phases = ref.watch(taskPhasesProvider);
    final allPhases = ['All', ...phases];

    final filtered = _filterPhase == 'All'
        ? tasks
        : tasks.where((t) => t.phase == _filterPhase).toList();

    final completed = tasks.where((t) => t.isCompleted).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Planner'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '$completed/${tasks.length}',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.secondary),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskDialog(context),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Overall Progress: ${(progress * 100).toStringAsFixed(0)}%',
                      style: AppTextStyles.labelLarge,
                    ),
                    Text(
                      '$completed of ${tasks.length} tasks',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.secondary),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),

          // Phase filter chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: allPhases.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final phase = allPhases[i];
                final isSelected = _filterPhase == phase;
                return FilterChip(
                  label: Text(
                    phase == 'All' ? 'All Phases' : phase,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) =>
                      setState(() => _filterPhase = phase),
                  selectedColor: AppColors.secondary,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  showCheckmark: false,
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.secondary
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Task list grouped by phase
          Expanded(
            child: filtered.isEmpty
                ? _EmptyState(
                    filterPhase: _filterPhase,
                    onAdd: () => _showTaskDialog(context),
                  )
                : _GroupedTaskList(
                    tasks: filtered,
                    onToggle: (id) =>
                        ref.read(taskProvider.notifier).toggleComplete(id),
                    onEdit: (item) => _showTaskDialog(context, existing: item),
                    onDelete: (id) => _confirmDelete(context, id),
                  ),
          ),
        ],
      ),
    );
  }

  void _showTaskDialog(BuildContext context, {ChecklistItem? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskFormSheet(
        existing: existing,
        phases: ref.read(taskPhasesProvider),
        onSave: (taskName, phase, dueDate, clearDue) {
          String? error;
          if (existing != null) {
            error = ref.read(taskProvider.notifier).editTask(
                  id: existing.id,
                  taskName: taskName,
                  phase: phase,
                  dueDate: dueDate,
                  clearDueDate: clearDue,
                );
          } else {
            error = ref.read(taskProvider.notifier).addTask(
                  taskName: taskName,
                  phase: phase,
                  dueDate: dueDate,
                );
          }

          if (error != null) {
            showWedSnackBar(context, error, type: SnackType.error);
          } else {
            showWedSnackBar(
              context,
              existing != null ? 'Task updated.' : 'Task added.',
              type: SnackType.success,
            );
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Task'),
        content:
            const Text('Are you sure you want to delete this task? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(taskProvider.notifier).deleteTask(id);
              showWedSnackBar(context, 'Task deleted.', type: SnackType.info);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Grouped task list ─────────────────────────────────────────────────────────

class _GroupedTaskList extends StatelessWidget {
  final List<ChecklistItem> tasks;
  final ValueChanged<String> onToggle;
  final ValueChanged<ChecklistItem> onEdit;
  final ValueChanged<String> onDelete;

  const _GroupedTaskList({
    required this.tasks,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final phases = <String, List<ChecklistItem>>{};
    for (final t in tasks) {
      phases.putIfAbsent(t.phase, () => []).add(t);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: phases.length,
      itemBuilder: (_, i) {
        final phase = phases.keys.elementAt(i);
        final phaseItems = phases[phase]!;
        final doneCount = phaseItems.where((t) => t.isCompleted).length;
        return _PhaseSection(
          phase: phase,
          items: phaseItems,
          completedCount: doneCount,
          onToggle: onToggle,
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
    );
  }
}

class _PhaseSection extends StatefulWidget {
  final String phase;
  final List<ChecklistItem> items;
  final int completedCount;
  final ValueChanged<String> onToggle;
  final ValueChanged<ChecklistItem> onEdit;
  final ValueChanged<String> onDelete;

  const _PhaseSection({
    required this.phase,
    required this.items,
    required this.completedCount,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_PhaseSection> createState() => _PhaseSectionState();
}

class _PhaseSectionState extends State<_PhaseSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final progress = widget.items.isEmpty
        ? 0.0
        : widget.completedCount / widget.items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(widget.phase, style: AppTextStyles.headlineSmall),
                ),
                _PhaseProgressPill(
                  done: widget.completedCount,
                  total: widget.items.length,
                  progress: progress,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          ...widget.items.map((item) => _TaskTile(
                item: item,
                onToggle: () => widget.onToggle(item.id),
                onEdit: () => widget.onEdit(item),
                onDelete: () => widget.onDelete(item.id),
              )),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _PhaseProgressPill extends StatelessWidget {
  final int done;
  final int total;
  final double progress;

  const _PhaseProgressPill(
      {required this.done, required this.total, required this.progress});

  @override
  Widget build(BuildContext context) {
    final color = progress == 1.0 ? AppColors.success : AppColors.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        '$done/$total',
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final ChecklistItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskTile({
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  bool get _isOverdue =>
      !item.isCompleted &&
      item.dueDate != null &&
      item.dueDate!.isBefore(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      confirmDismiss: (_) async {
        bool confirmed = false;
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Task'),
            content: Text('Delete "${item.task}"?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  confirmed = true;
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        return confirmed;
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          leading: GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isCompleted
                    ? AppColors.secondary
                    : Colors.transparent,
                border: Border.all(
                  color: item.isCompleted
                      ? AppColors.secondary
                      : AppColors.textSecondary,
                  width: 2,
                ),
              ),
              child: item.isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          title: Text(
            item.task,
            style: AppTextStyles.bodyMedium.copyWith(
              decoration:
                  item.isCompleted ? TextDecoration.lineThrough : null,
              color: item.isCompleted
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: item.dueDate != null
              ? Text(
                  'Due ${DateFormat('MMM d, y').format(item.dueDate!)}',
                  style: AppTextStyles.caption.copyWith(
                    color: _isOverdue
                        ? AppColors.error
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: _isOverdue ? FontWeight.w600 : FontWeight.normal,
                  ),
                )
              : null,
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            onPressed: onEdit,
            tooltip: 'Edit task',
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String filterPhase;
  final VoidCallback onAdd;

  const _EmptyState({required this.filterPhase, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('✅', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text(
            filterPhase == 'All'
                ? 'No tasks yet'
                : 'No tasks in "$filterPhase"',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Task" to create your first planning task.',
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Task'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Task form bottom sheet ────────────────────────────────────────────────────

class _TaskFormSheet extends StatefulWidget {
  final ChecklistItem? existing;
  final List<String> phases;
  final void Function(String taskName, String phase, DateTime? dueDate, bool clearDue) onSave;

  const _TaskFormSheet({
    required this.existing,
    required this.phases,
    required this.onSave,
  });

  @override
  State<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<_TaskFormSheet> {
  late final TextEditingController _nameCtrl;
  late String _selectedPhase;
  DateTime? _dueDate;
  bool _clearDue = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.task ?? '');
    _selectedPhase =
        widget.existing?.phase ?? (widget.phases.isNotEmpty ? widget.phases.first : '');
    _dueDate = widget.existing?.dueDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Task name is required.');
      return;
    }
    if (name.length < 3) {
      setState(() => _error = 'Task name must be at least 3 characters.');
      return;
    }
    setState(() => _error = null);
    Navigator.pop(context);
    widget.onSave(name, _selectedPhase, _dueDate, _clearDue);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 1825)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
        _clearDue = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEdit ? 'Edit Task' : 'New Task',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 20),

            // Task name
            TextFormField(
              controller: _nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Task name *',
                hintText: 'e.g. Book the florist',
                errorText: _error,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 16),

            // Phase dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedPhase.isEmpty ? null : _selectedPhase,
              decoration: InputDecoration(
                labelText: 'Planning phase *',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: widget.phases
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedPhase = v!),
            ),
            const SizedBox(height: 16),

            // Due date picker
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _dueDate != null
                            ? 'Due: ${DateFormat('MMM d, y').format(_dueDate!)}'
                            : 'Set due date (optional)',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _dueDate != null
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() {
                          _dueDate = null;
                          _clearDue = true;
                        }),
                        child: Icon(Icons.close,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  isEdit ? 'Save Changes' : 'Add Task',
                  style: AppTextStyles.titleMedium
                      .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
