import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Tone-based pill badge, mirroring frontend/src/components/ui/Badge.tsx's
/// tone system (neutral/trust/accent/warning/success/danger).
enum BadgeTone { neutral, trust, accent, warning, success, danger }

class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, this.tone = BadgeTone.neutral});

  final String label;
  final BadgeTone tone;

  (Color background, Color foreground) get _colors => switch (tone) {
    BadgeTone.neutral => (AppColors.stone100, AppColors.ink700),
    BadgeTone.trust => (AppColors.trust100, AppColors.trust700),
    BadgeTone.accent => (AppColors.accent100, AppColors.accent600),
    BadgeTone.warning => (AppColors.warning100, AppColors.warning600),
    BadgeTone.success => (AppColors.success100, AppColors.success600),
    BadgeTone.danger => (AppColors.danger100, AppColors.danger600),
  };

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
