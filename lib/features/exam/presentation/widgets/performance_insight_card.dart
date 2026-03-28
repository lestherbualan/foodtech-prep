import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/exam_models.dart';

/// Card highlighting the strongest and weakest subject from an exam attempt.
class PerformanceInsightCard extends StatelessWidget {
  const PerformanceInsightCard({super.key, required this.breakdown});

  final ExamPerformanceBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final strongest = breakdown.strongest;
    final weakest = breakdown.weakest;

    // Nothing to show if fewer than 2 subjects
    if (strongest == null || weakest == null || breakdown.subjects.length < 2) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Insights',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          _InsightRow(
            icon: Icons.trending_up_rounded,
            iconColor: AppColors.success,
            title: 'Strongest',
            subjectName: strongest.subjectName,
            percent: strongest.scorePercent,
          ),
          const SizedBox(height: AppSpacing.sm),
          _InsightRow(
            icon: Icons.trending_down_rounded,
            iconColor: AppColors.error,
            title: 'Needs Work',
            subjectName: weakest.subjectName,
            percent: weakest.scorePercent,
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subjectName,
    required this.percent,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subjectName;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                subjectName,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Text(
          '${percent.round()}%',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: iconColor,
          ),
        ),
      ],
    );
  }
}
