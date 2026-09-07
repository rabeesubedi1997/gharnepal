import 'package:intl/intl.dart';

/// NPR currency formatting, ported to match
/// frontend/src/design-system/tokens.ts exactly (`formatNpr`/
/// `formatNprCompact`) so numbers read identically to the website.
class NprFormatter {
  NprFormatter._();

  static final _grouped = NumberFormat('#,##,##0', 'en_IN');

  /// e.g. 4500000 -> "Rs 45,00,000" (Nepali/Indian digit grouping).
  static String format(num amount) {
    return 'Rs ${_grouped.format(amount.round())}';
  }

  /// Compact form for cards/lists, e.g. 4500000 -> "Rs 45 Lakh",
  /// 25000000 -> "Rs 2.5 Crore".
  static String formatCompact(num amount) {
    final abs = amount.abs();
    if (abs >= 1_00_00_000) return 'Rs ${_trim(amount / 1_00_00_000)} Crore';
    if (abs >= 1_00_000) return 'Rs ${_trim(amount / 1_00_000)} Lakh';
    if (abs >= 1_000) return 'Rs ${_trim(amount / 1_000)}K';
    return format(amount);
  }

  static String _trim(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }
}

/// Compact view/favorite/count display, e.g. 950 -> "950", 12400 -> "12.4K",
/// 2000000 -> "2M". Ported from `formatCompactCount` in the same file.
String formatCompactCount(num count) {
  if (count >= 1_000_000) {
    return '${NprFormatter._trim(count / 1_000_000)}M';
  }
  if (count >= 1_000) {
    return '${NprFormatter._trim(count / 1_000)}K';
  }
  return count.toStringAsFixed(0);
}
