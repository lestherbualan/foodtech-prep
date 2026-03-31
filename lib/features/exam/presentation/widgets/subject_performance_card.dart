import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/exam_models.dart';

/// Compact card showing performance stats for a single subject.
class SubjectPerformanceCard extends StatelessWidget {
  const SubjectPerformanceCard({super.key, required this.performance});

  final SubjectPerformance performance;

  @override
  Widget build(BuildContext context) {
    final pct = performance.scorePercent;
    final barColor = _barColor(pct);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject name + score badge
          Row(
            children: [
              Expanded(
                child: Text(
                  performance.subjectName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  '${pct.round()}%',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: barColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Mini progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 6,
              backgroundColor: AppColors.divider,
              color: barColor,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Stat chips row
          Row(
            children: [
              _MiniStat(
                label: 'Correct',
                value: '${performance.correct}',
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.sm),
              _MiniStat(
                label: 'Incorrect',
                value: '${performance.incorrect}',
                color: AppColors.error,
              ),
              if (performance.unanswered > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                _MiniStat(
                  label: 'Skipped',
                  value: '${performance.unanswered}',
                  color: AppColors.warning,
                ),
              ],
              const Spacer(),
              Text(
                '${performance.correct}/${performance.total}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _barColor(double pct) {
    if (pct >= 70) return AppColors.success;
    if (pct >= 40) return AppColors.warning;
    return AppColors.error;
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
