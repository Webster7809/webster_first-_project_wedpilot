import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class DashProgressBar extends StatelessWidget {
  final int total;
  final int current; // 0-indexed active step

  const DashProgressBar({
    super.key,
    required this.total,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final Color color;
        if (i < current) {
          color = AppColors.amber.withAlpha(178);
        } else if (i == current) {
          color = AppColors.amber;
        } else {
          color = Colors.white.withAlpha(64);
        }
        return Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
