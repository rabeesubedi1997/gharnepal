import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// App-wide theme, mirroring the website's design system: Plus Jakarta Sans
/// for headings, Inter for body text, both falling back to Noto Sans
/// Devanagari for Nepali text — matching
/// frontend/index.html's Google Fonts stack exactly (same weights, same
/// families), so text mixing English and Nepali renders consistently with
/// the website.
class AppTheme {
  AppTheme._();

  static const double cardRadius = 12;

  static List<String> get _devanagariFallback => [
    GoogleFonts.notoSansDevanagari().fontFamily!,
  ];

  static TextStyle _display(TextStyle base) =>
      GoogleFonts.plusJakartaSans(textStyle: base).copyWith(
        fontFamilyFallback: _devanagariFallback,
      );

  static TextStyle _body(TextStyle base) =>
      GoogleFonts.inter(textStyle: base).copyWith(
        fontFamilyFallback: _devanagariFallback,
      );

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.trust700,
      primary: AppColors.trust700,
      onPrimary: Colors.white,
      secondary: AppColors.accent600,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: AppColors.ink900,
      error: AppColors.danger600,
      brightness: Brightness.light,
    );

    final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);

    final textTheme = base.textTheme.copyWith(
      displayLarge: _display(base.textTheme.displayLarge!),
      displayMedium: _display(base.textTheme.displayMedium!),
      displaySmall: _display(base.textTheme.displaySmall!),
      headlineLarge: _display(base.textTheme.headlineLarge!),
      headlineMedium: _display(base.textTheme.headlineMedium!),
      headlineSmall: _display(base.textTheme.headlineSmall!),
      titleLarge: _display(base.textTheme.titleLarge!),
      titleMedium: _display(base.textTheme.titleMedium!),
      titleSmall: _display(base.textTheme.titleSmall!),
      bodyLarge: _body(base.textTheme.bodyLarge!),
      bodyMedium: _body(base.textTheme.bodyMedium!),
      bodySmall: _body(base.textTheme.bodySmall!),
      labelLarge: _body(base.textTheme.labelLarge!),
      labelMedium: _body(base.textTheme.labelMedium!),
      labelSmall: _body(base.textTheme.labelSmall!),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.stone50,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.stone50,
        foregroundColor: AppColors.ink900,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _display(
          base.textTheme.titleLarge!.copyWith(
            color: AppColors.ink900,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
          side: BorderSide(color: AppColors.stone200),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.trust700,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.stone200,
          disabledForegroundColor: AppColors.ink700,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          textStyle: _body(
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.trust700,
          side: const BorderSide(color: AppColors.stone200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: const BorderSide(color: AppColors.stone200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: const BorderSide(color: AppColors.stone200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: const BorderSide(color: AppColors.trust700, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: const BorderSide(color: AppColors.danger600),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.stone200),
    );
  }
}
