import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

final _commaFmt = NumberFormat('#,##0');

/// "12,500"
String fmtAmount(num amount) => _commaFmt.format(amount.round());

/// "ZMW 12,500"
String fmtCurrency(num amount, {String symbol = AppConstants.currency}) =>
    '$symbol ${fmtAmount(amount)}';

/// "72%" — pass a value already in percent (e.g. 72.3 → "72%").
String fmtPercent(double value, {int decimals = 0}) =>
    '${value.toStringAsFixed(decimals)}%';

/// "12.5k" for values ≥ 1 000, otherwise plain integer string.
String fmtCompact(num amount) {
  if (amount >= 1000) {
    final k = amount / 1000;
    return '${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(1)}k';
  }
  return amount.round().toString();
}

/// "14 September 2026"
String fmtDate(DateTime d) {
  const months = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${d.day} ${months[d.month]} ${d.year}';
}
