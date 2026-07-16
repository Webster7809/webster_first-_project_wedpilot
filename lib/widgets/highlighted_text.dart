import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Case-insensitive; highlights every non-overlapping occurrence of [query]
/// inside [text]. Falls back to a single plain span when [query] is blank or
/// doesn't occur in [text].
TextSpan buildHighlightedSpan({
  required String text,
  required String query,
  required TextStyle baseStyle,
  TextStyle? matchStyle,
}) {
  final effectiveMatchStyle = matchStyle ??
      baseStyle.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.forestGreen,
        backgroundColor: AppColors.amber.withAlpha(46),
      );

  final trimmedQuery = query.trim();
  if (trimmedQuery.isEmpty) {
    return TextSpan(text: text, style: baseStyle);
  }

  final lowerText = text.toLowerCase();
  final lowerQuery = trimmedQuery.toLowerCase();
  final spans = <TextSpan>[];
  var start = 0;
  var index = lowerText.indexOf(lowerQuery, start);

  if (index == -1) {
    return TextSpan(text: text, style: baseStyle);
  }

  while (index != -1) {
    if (index > start) {
      spans.add(TextSpan(text: text.substring(start, index), style: baseStyle));
    }
    spans.add(TextSpan(
      text: text.substring(index, index + trimmedQuery.length),
      style: effectiveMatchStyle,
    ));
    start = index + trimmedQuery.length;
    index = lowerText.indexOf(lowerQuery, start);
  }
  if (start < text.length) {
    spans.add(TextSpan(text: text.substring(start), style: baseStyle));
  }

  return TextSpan(children: spans, style: baseStyle);
}

/// Renders [text] with every occurrence of [query] visually emphasized —
/// used to show a couple/admin what part of a suggestion actually matched
/// what they typed.
class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;
  final TextStyle? matchStyle;
  final int? maxLines;
  final TextOverflow overflow;

  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    this.style,
    this.matchStyle,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    return Text.rich(
      buildHighlightedSpan(
        text: text,
        query: query,
        baseStyle: baseStyle,
        matchStyle: matchStyle,
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
