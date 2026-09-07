import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../features/listings/data/models/trust_score.dart';

(Color, Color, String) _tierStyle(int score) {
  if (score >= 70) return (AppColors.success100, AppColors.success600, 'Trusted');
  if (score >= 40) return (AppColors.warning100, AppColors.warning600, 'Fair trust');
  return (AppColors.danger100, AppColors.danger600, 'Low trust');
}

/// A compact "Trust NN" chip for `PropertyCard`, mirroring
/// frontend/src/components/trust/TrustBadge.tsx's `TrustScoreChip`. Tiering:
/// >=70 green "Trusted", >=40 amber "Fair trust", else red "Low trust".
class TrustScoreChip extends StatelessWidget {
  const TrustScoreChip({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, _) = _tierStyle(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 12, color: foreground),
          const SizedBox(width: 3),
          Text(
            'Trust $score',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full trust badge with an expandable per-factor breakdown, for Listing
/// Detail — mirrors `TrustExplanationPopover` on the website. Every score is
/// backed by this explanation; never shown as a bare number.
class TrustBadge extends StatefulWidget {
  const TrustBadge({super.key, required this.trust});

  final TrustScore trust;

  @override
  State<TrustBadge> createState() => _TrustBadgeState();
}

class _TrustBadgeState extends State<TrustBadge> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, label) = _tierStyle(widget.trust.score);

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Icon(Icons.verified, color: foreground),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trust score: ${widget.trust.score}/100',
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(color: foreground, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: foreground),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: foreground,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...widget.trust.breakdown.map(
              (factor) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            factor.label ?? factor.key ?? '',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(factor.explanation, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Text(
                      '${factor.pointsAwarded.toStringAsFixed(0)}/${factor.maxPoints.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
