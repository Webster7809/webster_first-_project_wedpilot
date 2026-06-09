import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/checklist_item.dart';

final _checklistProvider = StateNotifierProvider<_ChecklistNotifier, List<ChecklistItem>>(
  (ref) => _ChecklistNotifier(),
);

class _ChecklistNotifier extends StateNotifier<List<ChecklistItem>> {
  _ChecklistNotifier() : super(defaultChecklist);

  void toggle(String id) {
    state = state.map((item) {
      if (item.id == id) return item.copyWith(isCompleted: !item.isCompleted);
      return item;
    }).toList();
  }
}

class PlanningChecklistScreen extends ConsumerWidget {
  const PlanningChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(_checklistProvider);
    final completed = items.where((i) => i.isCompleted).length;
    final phases = <String, List<ChecklistItem>>{};
    for (final item in items) {
      phases.putIfAbsent(item.phase, () => []).add(item);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Planning Checklist'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('$completed/${items.length}',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.secondary)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Progress: ${(completed / items.length * 100).toStringAsFixed(0)}%',
                        style: AppTextStyles.labelLarge),
                    Text('$completed of ${items.length} tasks',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: completed / items.length,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: phases.length,
              itemBuilder: (_, i) {
                final phase = phases.keys.elementAt(i);
                final phaseItems = phases[phase]!;
                final phaseCompleted = phaseItems.where((x) => x.isCompleted).length;
                return _PhaseSection(
                  phase: phase,
                  items: phaseItems,
                  completed: phaseCompleted,
                  onToggle: (id) => ref.read(_checklistProvider.notifier).toggle(id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseSection extends StatefulWidget {
  final String phase;
  final List<ChecklistItem> items;
  final int completed;
  final ValueChanged<String> onToggle;

  const _PhaseSection({
    required this.phase,
    required this.items,
    required this.completed,
    required this.onToggle,
  });

  @override
  State<_PhaseSection> createState() => _PhaseSectionState();
}

class _PhaseSectionState extends State<_PhaseSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              children: [
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(widget.phase, style: AppTextStyles.headlineSmall)),
                Text('${widget.completed}/${widget.items.length}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
        if (_expanded)
          ...widget.items.map((item) => CheckboxListTile(
                value: item.isCompleted,
                onChanged: (_) => widget.onToggle(item.id),
                title: Text(
                  item.task,
                  style: AppTextStyles.bodyMedium.copyWith(
                    decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                    color: item.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
                activeColor: AppColors.secondary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                dense: true,
              )),
        const SizedBox(height: 8),
      ],
    );
  }
}
