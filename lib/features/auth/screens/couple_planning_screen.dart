import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_text_field.dart';

class CouplePlanningScreen extends ConsumerStatefulWidget {
  const CouplePlanningScreen({super.key});

  @override
  ConsumerState<CouplePlanningScreen> createState() =>
      _CouplePlanningScreenState();
}

class _CouplePlanningScreenState extends ConsumerState<CouplePlanningScreen> {
  final _budgetCtrl = TextEditingController();
  final _guestsCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  final Map<String, bool> _weddingItems = {
    'Venue': false,
    'Catering': false,
    'Photography': false,
    'Decoration': false,
    'Entertainment': false,
    'Attire': false,
    'Transport': false,
    'Music / DJ': false,
    'Flowers': false,
    'Wedding Cake': false,
    'Makeup & Hair': false,
    'Honeymoon': false,
  };

  String _weddingStyle = 'traditional';
  String _weddingClass = 'budget';

  @override
  void dispose() {
    _budgetCtrl.dispose();
    _guestsCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _createPlan() {
    final budget =
        double.tryParse(_budgetCtrl.text.replaceAll(',', '')) ?? 0.0;
    final guests = int.tryParse(_guestsCtrl.text) ?? 0;
    final selectedItems = _weddingItems.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    ref.read(authProvider.notifier).updateCoupleProfile(
          selectedItems: selectedItems,
          budget: budget,
          weddingStyle: _weddingStyle,
          weddingClass: _weddingClass,
          guestCount: guests,
          location: _locationCtrl.text.trim(),
        );

    context.go('/couple/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.secondary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.secondary, Color(0xFFAD1457)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Text(
                          '💍 Plan Your Dream Wedding',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Tell us about your perfect day and we\'ll match you with the best vendors.',
                          style: TextStyle(
                            color: Color(0xFFFFCDD2),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Wedding Items ──────────────────────────────
                _SectionHeader(
                  title: 'What do you need for your wedding?',
                  subtitle: 'Tick everything that applies',
                ),
                const SizedBox(height: 14),
                _ItemsChecklist(
                  items: _weddingItems,
                  onToggle: (key, value) =>
                      setState(() => _weddingItems[key] = value),
                ),
                const SizedBox(height: 28),

                // ── Budget ─────────────────────────────────────
                _SectionHeader(
                  title: 'Total Wedding Budget',
                  subtitle: 'How much do you plan to spend? (K)',
                ),
                const SizedBox(height: 14),
                WedTextField(
                  label: 'Budget Amount',
                  hint: 'e.g. 50,000',
                  controller: _budgetCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.monetization_on_outlined,
                ),
                const SizedBox(height: 28),

                // ── Wedding Style ──────────────────────────────
                _SectionHeader(
                  title: 'Wedding Style',
                  subtitle: 'Choose your preferred ceremony style',
                ),
                const SizedBox(height: 14),
                _BinaryToggle(
                  leftValue: 'traditional',
                  leftLabel: 'Traditional',
                  leftIcon: Icons.diversity_3_outlined,
                  rightValue: 'modern',
                  rightLabel: 'Modern',
                  rightIcon: Icons.auto_awesome_outlined,
                  selected: _weddingStyle,
                  onSelect: (v) => setState(() => _weddingStyle = v),
                ),
                const SizedBox(height: 28),

                // ── Wedding Class ──────────────────────────────
                _SectionHeader(
                  title: 'Wedding Class',
                  subtitle: 'What type of experience are you planning?',
                ),
                const SizedBox(height: 14),
                _BinaryToggle(
                  leftValue: 'budget',
                  leftLabel: 'Budget-Friendly',
                  leftIcon: Icons.savings_outlined,
                  rightValue: 'highclass',
                  rightLabel: 'High Class',
                  rightIcon: Icons.diamond_outlined,
                  selected: _weddingClass,
                  onSelect: (v) => setState(() => _weddingClass = v),
                ),
                const SizedBox(height: 28),

                // ── Number of Guests ───────────────────────────
                _SectionHeader(
                  title: 'Number of Guests',
                  subtitle: 'How many guests will you be hosting?',
                ),
                const SizedBox(height: 14),
                WedTextField(
                  label: 'Guest Count',
                  hint: 'e.g. 150',
                  controller: _guestsCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.people_outline,
                ),
                const SizedBox(height: 28),

                // ── Location ───────────────────────────────────
                _SectionHeader(
                  title: 'Wedding Location',
                  subtitle: 'Which city or area will the wedding be held?',
                ),
                const SizedBox(height: 14),
                WedTextField(
                  label: 'City / Location',
                  hint: 'e.g. Lusaka',
                  controller: _locationCtrl,
                  prefixIcon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 36),

                // ── Create Plan ────────────────────────────────
                WedButton(
                  label: 'Create My Wedding Plan',
                  onPressed: _createPlan,
                  icon: Icons.auto_awesome,
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Our AI will match you with the best vendors for your preferences.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ItemsChecklist extends StatelessWidget {
  final Map<String, bool> items;
  final void Function(String key, bool value) onToggle;

  const _ItemsChecklist({required this.items, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: items.entries.map((entry) {
        final selected = entry.value;
        return GestureDetector(
          onTap: () => onToggle(entry.key, !selected),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.secondary : AppColors.surface,
              border: Border.all(
                color: selected ? AppColors.secondary : AppColors.divider,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.secondary.withAlpha(64),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 16,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  entry.key,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BinaryToggle extends StatelessWidget {
  final String leftValue;
  final String leftLabel;
  final IconData leftIcon;
  final String rightValue;
  final String rightLabel;
  final IconData rightIcon;
  final String selected;
  final void Function(String) onSelect;

  const _BinaryToggle({
    required this.leftValue,
    required this.leftLabel,
    required this.leftIcon,
    required this.rightValue,
    required this.rightLabel,
    required this.rightIcon,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToggleCard(
            value: leftValue,
            label: leftLabel,
            icon: leftIcon,
            isSelected: selected == leftValue,
            onTap: () => onSelect(leftValue),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ToggleCard(
            value: rightValue,
            label: rightLabel,
            icon: rightIcon,
            isSelected: selected == rightValue,
            onTap: () => onSelect(rightValue),
          ),
        ),
      ],
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.divider,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withAlpha(51),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
