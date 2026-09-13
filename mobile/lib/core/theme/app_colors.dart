import 'package:flutter/material.dart';

/// Color tokens ported from the website's design system
/// (frontend/src/design-system/tokens.ts, frontend/src/index.css).
///
/// "Alpine Sanctuary" — adopted at the user's explicit request from a
/// supplied palette (Primary #0F4C3A, Secondary #0F172A, Tertiary #10B981,
/// Neutral #334155). A cool slate/emerald system, replacing the previous
/// warm stone/terracotta identity — see the web tokens file for the full
/// rationale and the tint/shade ramp this was derived from.
class AppColors {
  AppColors._();

  // Stone (backgrounds) — cool light slate, not warm/cream
  static const stone50 = Color(0xFFF8FAFC);
  static const stone100 = Color(0xFFF1F5F9);
  static const stone200 = Color(0xFFE2E8F0);

  // Ink (text) — Alpine Sanctuary's Secondary/Neutral
  static const ink900 = Color(0xFF0F172A);
  static const ink700 = Color(0xFF334155);

  // Trust green (primary brand color) — Alpine Sanctuary's Primary.
  static const trust700 = Color(0xFF0F4C3A);
  static const trust600 = Color(0xFF3F7061);
  static const trust100 = Color(0xFFE7EDEB);

  // Emerald accent — Alpine Sanctuary's Tertiary, the site's one accent/pop color.
  static const accent600 = Color(0xFF059669);
  static const accent500 = Color(0xFF10B981);
  static const accent100 = Color(0xFFD1FAE5);

  // Status colors
  static const danger600 = Color(0xFFDC2626);
  static const danger100 = Color(0xFFFEE2E2);
  static const warning600 = Color(0xFFD97706);
  static const warning100 = Color(0xFFFEF3C7);
  static const success600 = Color(0xFF15803D);
  static const success100 = Color(0xFFDCFCE7);

  // Links reuse the deep trust green rather than a separate hue.
  static const link600 = trust700;
  static const link700 = Color(0xFF0D4131);
}
