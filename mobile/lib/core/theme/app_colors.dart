import 'package:flutter/material.dart';

/// Color tokens ported from the website's design system
/// (frontend/src/design-system/tokens.ts, frontend/src/index.css).
///
/// The palette is warm, not cold-blue: stone off-white backgrounds, a deep
/// pine-green "trust" color as the single primary brand color, and a
/// terracotta accent deliberately reserved for "Featured" highlights only
/// (never a second button color).
class AppColors {
  AppColors._();

  // Stone (backgrounds)
  static const stone50 = Color(0xFFFAF9F6);
  static const stone100 = Color(0xFFF0EEE8);
  static const stone200 = Color(0xFFE2DED4);

  // Ink (text)
  static const ink900 = Color(0xFF211F1A);
  static const ink700 = Color(0xFF59564D);

  // Trust green (primary brand color) — trust700 (#1f4b3f) is the primary;
  // trust600 is a lighter tint used for some link/hover states.
  static const trust700 = Color(0xFF1F4B3F);
  static const trust600 = Color(0xFF2C6753);
  static const trust100 = Color(0xFFE4EDE8);

  // Terracotta accent — "Featured" tags only, not a general accent color.
  static const accent600 = Color(0xFFBF5F2C);
  static const accent500 = Color(0xFFD67C40);
  static const accent100 = Color(0xFFF8E6D8);

  // Status colors
  static const danger600 = Color(0xFFDC2626);
  static const danger100 = Color(0xFFFEE2E2);
  static const warning600 = Color(0xFFD97706);
  static const warning100 = Color(0xFFFEF3C7);
  static const success600 = Color(0xFF15803D);
  static const success100 = Color(0xFFDCFCE7);

  // Links reuse the deep trust green rather than a separate hue.
  static const link600 = trust700;
  static const link700 = Color(0xFF163829);
}
