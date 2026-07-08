import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/state/resource.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/checklist_item.dart';
import '../../../providers/task_provider.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_snack_bar.dart';
import '../../../widgets/wed_text_field.dart';

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
    final tasksState = ref.watch(taskProvider);

    if (tasksState.status == ResourceStatus.initial) {
      Future.microtask(() => ref.read(taskProvider.notifier).loadTasks());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Task Planner')),
      floatingActionButton: tasksState.hasData
          ? FloatingActionButton.extended(
              onPressed: () => _showTaskDialog(context),
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            )
          : null,
      body: tasksState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (message) => _ErrorState(
          message: message,
          onRetry: () => ref.read(taskProvider.notifier).loadTasks(),
        ),
        data: (tasks) => _TaskPlannerBody(
          tasks: tasks,
          filterPhase: _filterPhase,
          onFilterChanged: (phase) => setState(() => _filterPhase = phase),
          onAdd: () => _showTaskDialog(context),
          onEdit: (item) => _showTaskDialog(context, existing: item),
          onDelete: (id) => _confirmDelete(context, id),
        ),
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
        onSave: (taskName, phase, dueDate, clearDue) async {
          String? error;
          if (existing != null) {
            error = await ref
                .read(taskProvider.notifier)
                .editTask(
                  id: existing.id,
                  taskName: taskName,
                  phase: phase,
                  dueDate: dueDate,
                  clearDueDate: clearDue,
                );
          } else {
            error = await ref
                .read(taskProvider.notifier)
                .addTask(taskName: taskName, phase: phase, dueDate: dueDate);
          }
          if (!context.mounted) return;

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
        content: const Text(
          'Are you sure you want to delete this task? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final error = await ref
                  .read(taskProvider.notifier)
                  .deleteTask(id);
              if (!context.mounted) return;
              showWedSnackBar(
                context,
                error ?? 'Task deleted.',
                type: error != null ? SnackType.error : SnackType.info,
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(102),
            ),
            const SizedBox(height: 16),
            Text(
              "Couldn't load your tasks",
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            WedButton(
              label: 'Retry',
              onPressed: onRetry,
              icon: Icons.refresh_rounded,
              borderRadius: 30,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Task planner body (progress, filters, list) ─────────────────────────────

class _TaskPlannerBody extends ConsumerWidget {
  final List<ChecklistItem> tasks;
  final String filterPhase;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onAdd;
  final ValueChanged<ChecklistItem> onEdit;
  final ValueChanged<String> onDelete;

  const _TaskPlannerBody({
    required this.tasks,
    required this.filterPhase,
    required this.onFilterChanged,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(taskProgressProvider);
    final phases = ref.watch(taskPhasesProvider);
    final allPhases = ['All', ...phases];
    final dueSoonTasks = ref.watch(tasksDueSoonProvider);
    final dueSoonIds = dueSoonTasks.map((t) => t.id).toSet();

    final filtered = filterPhase == 'All'
        ? tasks
        : tasks.where((t) => t.phase == filterPhase).toList();
    final completed = tasks.where((t) => t.isCompleted).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$completed/${tasks.length}',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
        ),
        if (dueSoonTasks.isNotEmpty) _DueSoonBanner(count: dueSoonTasks.length),

        // Progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Overall Progress: ${(progress * 100).toStringAsFixed(0)}%',
                      style: AppTextStyles.labelLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '$completed of ${tasks.length} tasks',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(153),
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withAlpha(102),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
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
              final isSelected = filterPhase == phase;
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
                onSelected: (_) => onFilterChanged(phase),
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
              ? _EmptyState(filterPhase: filterPhase, onAdd: onAdd)
              : _GroupedTaskList(
                  tasks: filtered,
                  dueSoonIds: dueSoonIds,
                  onToggle: (id) async {
                    final error = await ref
                        .read(taskProvider.notifier)
                        .toggleComplete(id);
                    if (error != null && context.mounted) {
                      showWedSnackBar(context, error, type: SnackType.error);
                    }
                  },
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
        ),
      ],
    );
  }
}

// ── Due soon reminder banner ────────────────────────────────────────────────

class _DueSoonBanner extends StatelessWidget {
  final int count;
  const _DueSoonBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.warningBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withAlpha(90)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 20,
              color: AppColors.warning,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                count == 1
                    ? '1 task due in the next $taskDueSoonWindowDays days'
                    : '$count tasks due in the next $taskDueSoonWindowDays days',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Grouped task list ─────────────────────────────────────────────────────────

class _GroupedTaskList extends StatelessWidget {
  final List<ChecklistItem> tasks;
  final Set<String> dueSoonIds;
  final ValueChanged<String> onToggle;
  final ValueChanged<ChecklistItem> onEdit;
  final ValueChanged<String> onDelete;

  const _GroupedTaskList({
    required this.tasks,
    required this.dueSoonIds,
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
          dueSoonIds: dueSoonIds,
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
  final Set<String> dueSoonIds;
  final ValueChanged<String> onToggle;
  final ValueChanged<ChecklistItem> onEdit;
  final ValueChanged<String> onDelete;

  const _PhaseSection({
    required this.phase,
    required this.items,
    required this.completedCount,
    required this.dueSoonIds,
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
          ...widget.items.map(
            (item) => _TaskTile(
              item: item,
              isDueSoon: widget.dueSoonIds.contains(item.id),
              onToggle: () => widget.onToggle(item.id),
              onEdit: () => widget.onEdit(item),
              onDelete: () => widget.onDelete(item.id),
            ),
          ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _PhaseProgressPill extends StatelessWidget {
  final int done;
  final int total;
  final double progress;

  const _PhaseProgressPill({
    required this.done,
    required this.total,
    required this.progress,
  });

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
  final bool isDueSoon;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskTile({
    required this.item,
    required this.isDueSoon,
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
                child: const Text('Cancel'),
              ),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 2,
          ),
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
              decoration: item.isCompleted ? TextDecoration.lineThrough : null,
              color: item.isCompleted
                  ? Theme.of(context).colorScheme.onSurface.withAlpha(128)
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: item.dueDate != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isOverdue || isDueSoon)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          _isOverdue
                              ? Icons.error_outline_rounded
                              : Icons.schedule_rounded,
                          size: 13,
                          color: _isOverdue
                              ? AppColors.error
                              : AppColors.warning,
                        ),
                      ),
                    Flexible(
                      child: Text(
                        'Due ${DateFormat('MMM d, y').format(item.dueDate!)}',
                        style: AppTextStyles.caption.copyWith(
                          color: _isOverdue
                              ? AppColors.error
                              : isDueSoon
                              ? AppColors.warning
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(153),
                          fontWeight: (_isOverdue || isDueSoon)
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : null,
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
            onPressed: onEdit,
            tooltip: 'Edit task',
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends ConsumerStatefulWidget {
  final String filterPhase;
  final VoidCallback onAdd;

  const _EmptyState({required this.filterPhase, required this.onAdd});

  @override
  ConsumerState<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends ConsumerState<_EmptyState> {
  bool _loadingStarter = false;

  Future<void> _loadStarterChecklist() async {
    setState(() => _loadingStarter = true);
    final error = await ref.read(taskProvider.notifier).loadStarterChecklist();
    if (!mounted) return;
    setState(() => _loadingStarter = false);
    if (error != null) {
      showWedSnackBar(context, error, type: SnackType.error);
    } else {
      showWedSnackBar(
        context,
        'Starter checklist added.',
        type: SnackType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showStarterOption = widget.filterPhase == 'All';
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.success,
                        AppColors.success.withAlpha(200),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withAlpha(70),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.task_alt_rounded,
                    size: 44,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.filterPhase == 'All'
                      ? 'No tasks yet'
                      : 'No tasks in "${widget.filterPhase}"',
                  style: AppTextStyles.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap "Add Task" to create your first planning task.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(153),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: WedButton(
                        label: 'Add Task',
                        onPressed: widget.onAdd,
                        icon: Icons.add,
                        borderRadius: 30,
                        width: 220,
                      ),
                    ),
                  ],
                ),
                if (showStarterOption) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _loadingStarter ? null : _loadStarterChecklist,
                    icon: _loadingStarter
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.checklist_rounded, size: 18),
                    label: const Text('Load starter checklist'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Task form bottom sheet ────────────────────────────────────────────────────

class _TaskFormSheet extends StatefulWidget {
  final ChecklistItem? existing;
  final List<String> phases;
  final void Function(
    String taskName,
    String phase,
    DateTime? dueDate,
    bool clearDue,
  )
  onSave;

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
        widget.existing?.phase ??
        (widget.phases.isNotEmpty ? widget.phases.first : '');
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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: SingleChildScrollView(
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
                WedTextField(
                  label: 'Task name *',
                  hint: 'e.g. Book the florist',
                  controller: _nameCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  errorText: _error,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                ),
                const SizedBox(height: 16),

                // Phase dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedPhase.isEmpty ? null : _selectedPhase,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Planning phase *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  items: widget.phases
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(p, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedPhase = v!),
                ),
                const SizedBox(height: 16),

                // Due date picker
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(153),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _dueDate != null
                                ? 'Due: ${DateFormat('MMM d, y').format(_dueDate!)}'
                                : 'Set due date (optional)',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: _dueDate != null
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(153),
                            ),
                          ),
                        ),
                        if (_dueDate != null)
                          GestureDetector(
                            onTap: () => setState(() {
                              _dueDate = null;
                              _clearDue = true;
                            }),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(153),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save button
                WedButton(
                  label: isEdit ? 'Save Changes' : 'Add Task',
                  onPressed: _save,
                  height: 50,
                  borderRadius: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
