import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// The brand's signature 48×1 gold hairline.
///
/// It belongs under section titles and screen headings and nowhere else — the
/// moment it decorates something ordinary it stops reading as a mark of
/// hierarchy. [WedSectionHeader] and the auth/profile headings are its only
/// legitimate homes.
class GoldRule extends StatelessWidget {
  final double width;

  const GoldRule({super.key, this.width = 48});

  @override
  Widget build(BuildContext context) =>
      Container(width: width, height: 1, color: AppColors.accent);
}
