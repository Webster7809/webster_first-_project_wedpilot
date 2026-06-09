import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_snack_bar.dart';

class ContentModerationScreen extends StatefulWidget {
  const ContentModerationScreen({super.key});

  @override
  State<ContentModerationScreen> createState() => _ContentModerationScreenState();
}

class _ContentModerationScreenState extends State<ContentModerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final _reviews = [
    {'vendor': 'Blossom Photography', 'rating': 1, 'text': 'Terrible service, would not recommend...', 'flagReason': 'Spam'},
    {'vendor': 'The Garden Venue', 'rating': 2, 'text': 'They canceled on us last minute with no refund.', 'flagReason': 'Dispute'},
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Content Moderation'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Reviews (2)'),
            Tab(text: 'Images (3)'),
            Tab(text: 'Messages (1)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _ReviewModerationList(
            reviews: _reviews,
            onApprove: (i) {
              setState(() => _reviews.removeAt(i));
              showWedSnackBar(context, 'Review approved', type: SnackType.success);
            },
            onReject: (i) {
              setState(() => _reviews.removeAt(i));
              showWedSnackBar(context, 'Review rejected', type: SnackType.error);
            },
          ),
          const _ImageModerationPlaceholder(),
          const _MessageModerationPlaceholder(),
        ],
      ),
    );
  }
}

class _ReviewModerationList extends StatelessWidget {
  final List<Map<String, dynamic>> reviews;
  final ValueChanged<int> onApprove;
  final ValueChanged<int> onReject;

  const _ReviewModerationList({required this.reviews, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✅', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('No reviews to moderate', style: AppTextStyles.headlineMedium),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      itemBuilder: (_, i) {
        final review = reviews[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(review['vendor'] as String, style: AppTextStyles.titleMedium)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Flagged: ${review['flagReason']}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (j) => Icon(
                    j < (review['rating'] as int) ? Icons.star : Icons.star_border,
                    size: 14, color: AppColors.goldPremium,
                  )),
                ),
                const SizedBox(height: 6),
                Text(review['text'] as String, style: AppTextStyles.bodySmall),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: WedButton(label: 'Reject', variant: WedButtonVariant.destructive, onPressed: () => onReject(i), height: 38)),
                    const SizedBox(width: 8),
                    Expanded(child: WedButton(label: 'Approve', onPressed: () => onApprove(i), height: 38)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ImageModerationPlaceholder extends StatelessWidget {
  const _ImageModerationPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🖼️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('3 images pending review', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text('AI pre-screening in progress...', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _MessageModerationPlaceholder extends StatelessWidget {
  const _MessageModerationPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💬', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('1 message flagged', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text('Contains prohibited content keyword', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
