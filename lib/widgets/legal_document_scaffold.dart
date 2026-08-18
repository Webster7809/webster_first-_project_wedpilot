import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class LegalSection {
  final String heading;
  final String body;
  const LegalSection(this.heading, this.body);
}

/// Shared static-content layout for the Privacy Policy, Terms of Service, and
/// Cookie Preferences screens — same AppBar-over-scrollable-content shell as
/// HelpScreen, minus the search/FAQ specifics, so the three legal pages stay
/// visually consistent without three copies of the same boilerplate.
class LegalDocumentScaffold extends StatelessWidget {
  final String title;
  final String lastUpdated;
  final String disclaimer;
  final List<LegalSection> sections;

  const LegalDocumentScaffold({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.disclaimer,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Last updated: $lastUpdated',
            style: AppTextStyles.caption.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondary.withAlpha(51)),
            ),
            child: Text(
              disclaimer,
              style: AppTextStyles.bodySmall.copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
          for (final section in sections) ...[
            Text(section.heading, style: AppTextStyles.titleMedium),
            const SizedBox(height: 6),
            Text(
              section.body,
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
