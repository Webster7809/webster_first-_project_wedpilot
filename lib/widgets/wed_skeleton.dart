import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/app_colors.dart';

/// Loading placeholder. Use the shape that matches what is about to appear —
/// [WedSkeleton.card] for a card slot, [WedSkeleton.line] for a line of text.
class WedSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const WedSkeleton._({
    this.width,
    required this.height,
    required this.borderRadius,
  });

  /// Placeholder for a [WedCard]-shaped slot.
  const WedSkeleton.card(double height)
      : this._(width: double.infinity, height: height, borderRadius: 20);

  /// Placeholder for a line of text.
  const WedSkeleton.line({double? width, double height = 12})
      : this._(width: width, height: height, borderRadius: 4);

  /// Placeholder for an avatar or a round icon slot.
  const WedSkeleton.circle(double size)
      : this._(width: size, height: size, borderRadius: size);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// The loading state for a screen that is about to show a list.
///
/// Prefer this over a bare [CircularProgressIndicator]: a spinner says only
/// "wait", while a skeleton in the shape of the coming content says what is
/// arriving and stops the layout jumping when it lands.
class WedListSkeleton extends StatelessWidget {
  final int rows;

  /// Leaves room for an avatar or thumbnail at the start of each row.
  final bool hasLeading;

  /// Renders full card slots instead of list rows.
  final bool asCards;

  final double cardHeight;

  const WedListSkeleton({
    super.key,
    this.rows = 5,
    this.hasLeading = true,
    this.asCards = false,
    this.cardHeight = 120,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      // One announcement for the whole block — a screen reader should hear
      // "loading", not eight anonymous placeholder shapes.
      child: Semantics(
        label: 'Loading',
        liveRegion: true,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rows,
          separatorBuilder: (_, _) => SizedBox(height: asCards ? 16 : 22),
          itemBuilder: (context, i) {
            if (asCards) return WedSkeleton.card(cardHeight);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasLeading) ...[
                  const WedSkeleton.circle(44),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Staggered widths so the block reads as text rather
                      // than as a stack of identical bars.
                      WedSkeleton.line(width: i.isEven ? 180 : 140, height: 13),
                      const SizedBox(height: 9),
                      WedSkeleton.line(width: i.isEven ? 240 : 200, height: 11),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
