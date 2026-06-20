import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class VendorListingsScreen extends StatefulWidget {
  const VendorListingsScreen({super.key});

  @override
  State<VendorListingsScreen> createState() => _VendorListingsScreenState();
}

class _VendorListingsScreenState extends State<VendorListingsScreen> {
  int _filterIndex = 0;
  final _filters = ['All (4)', 'Live (3)', 'In review (1)'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.cream,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('YOUR LISTINGS',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.amber,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        )),
                    const SizedBox(height: 4),
                    Text('Manage your portfolio',
                        style: AppTextStyles.displaySmall.copyWith(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
              ),
            ),
            expandedHeight: 100,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FloatingActionButton.small(
                  backgroundColor: AppColors.amber,
                  elevation: 0,
                  onPressed: () {},
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats
                Row(
                  children: [
                    _StatBox(value: '3', label: 'LIVE\nLISTINGS'),
                    const SizedBox(width: 12),
                    _StatBox(value: '412', label: 'TOTAL\nVIEWS'),
                    const SizedBox(width: 12),
                    _StatBox(value: '38', label: 'INQUIRIES'),
                  ],
                ),
                const SizedBox(height: 20),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_filters.length, (i) {
                      final active = _filterIndex == i;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _filterIndex = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: active ? AppColors.forestGreen : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: active ? AppColors.forestGreen : AppColors.divider),
                            ),
                            child: Text(
                              _filters[i],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                                color: active ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),

                // Listing cards
                _ListingCard(
                  title: 'Open Air Garden Package',
                  category: 'Venue',
                  priceRange: 'ZMW 28,000–35,000',
                  views: 286,
                  rating: 4.9,
                  status: 'Live',
                  statusColor: AppColors.verified,
                  iconBg: AppColors.amber.withAlpha(30),
                ),
                const SizedBox(height: 10),
                _ListingCard(
                  title: 'Indoor Hall, Full Decor',
                  category: 'Venue',
                  priceRange: 'ZMW 22,000–30,000',
                  views: 98,
                  rating: 4.7,
                  status: 'Live',
                  statusColor: AppColors.verified,
                  iconBg: const Color(0xFFE8F5EE),
                ),
                const SizedBox(height: 10),
                _ListingCard(
                  title: 'Premium Marquee Setup',
                  category: 'Venue',
                  priceRange: 'ZMW 40,000–55,000',
                  views: null,
                  rating: null,
                  status: 'In review',
                  statusColor: AppColors.warning,
                  pendingNote: 'Pending admin approval',
                  iconBg: AppColors.amber.withAlpha(20),
                ),
                const SizedBox(height: 10),
                _ListingCard(
                  title: 'Weekday Discount Package',
                  category: 'Venue',
                  priceRange: 'Not published',
                  views: null,
                  rating: null,
                  status: 'Draft',
                  statusColor: AppColors.textSecondary,
                  pendingNote: 'Finish setup to publish',
                  iconBg: AppColors.creamDark,
                  isDraft: true,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forestGreen,
                )),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                )),
          ],
        ),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final String title;
  final String category;
  final String priceRange;
  final int? views;
  final double? rating;
  final String status;
  final Color statusColor;
  final String? pendingNote;
  final Color iconBg;
  final bool isDraft;

  const _ListingCard({
    required this.title,
    required this.category,
    required this.priceRange,
    required this.views,
    required this.rating,
    required this.status,
    required this.statusColor,
    this.pendingNote,
    required this.iconBg,
    this.isDraft = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.grid_view_rounded,
              color: isDraft ? AppColors.textHint : AppColors.amber,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDraft ? AppColors.textSecondary : AppColors.textPrimary,
                          )),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text('$category · $priceRange',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                if (pendingNote != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isDraft ? Icons.edit_outlined : Icons.info_outline,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(pendingNote!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          )),
                    ],
                  ),
                ],
                if (views != null && rating != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.visibility_outlined, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('$views views',
                          style: AppTextStyles.caption.copyWith(fontSize: 11)),
                      const SizedBox(width: 10),
                      const Icon(Icons.star_rounded, size: 12, color: AppColors.amber),
                      const SizedBox(width: 3),
                      Text('$rating rating',
                          style: AppTextStyles.caption.copyWith(fontSize: 11)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
