import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/score_band.dart';
import '../../domain/daily_timed_exam_summary.dart';
import '../../domain/weekly_timed_exam_summary.dart';

/// A compact Sunday-to-Saturday weekly strip that summarises
/// timed exam performance for each day of the current week.
class WeeklyTimedExamPerformanceStrip extends StatelessWidget {
  const WeeklyTimedExamPerformanceStrip({
    super.key,
    required this.summary,
    this.onDayTap,
  });

  final WeeklyTimedExamSummary summary;

  /// Called when a day cell is tapped.  Phase 1 stub — will expand in Phase 2.
  final void Function(DailyTimedExamSummary day)? onDayTap;

  static const _dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(7, (i) {
          final day = summary.days[i];
          final isToday = day.date == todayDate;
          return Expanded(
            child: _DayCell(
              label: _dayLabels[i],
              dateNumber: day.date.day,
              summary: day,
              isToday: isToday,
              onTap: onDayTap != null ? () => onDayTap!(day) : null,
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual day cell
// ─────────────────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.label,
    required this.dateNumber,
    required this.summary,
    required this.isToday,
    this.onTap,
  });

  final String label;
  final int dateNumber;
  final DailyTimedExamSummary summary;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasAttempt = summary.hasAttempt;
    final score = summary.averageScore;

    // ── Colour resolution ──
    final Color circleBg;
    final Color circleFg;
    final Color? ringColor;

    if (isToday) {
      circleBg = hasAttempt
          ? ScoreBand.surface(score)
          : AppColors.primarySurface;
      circleFg = hasAttempt
          ? ScoreBand.foregroundOnSurface(score)
          : AppColors.primary;
      ringColor = AppColors.primary;
    } else if (hasAttempt) {
      circleBg = ScoreBand.surface(score);
      circleFg = ScoreBand.foregroundOnSurface(score);
      ringColor = ScoreBand.color(score).withValues(alpha: 0.30);
    } else {
      circleBg = AppColors.surface.withValues(alpha: 0.6);
      circleFg = AppColors.textHint;
      ringColor = null;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Day label ──
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isToday ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              fontSize: 10.5,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 6),

          // ── Date circle ──
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: circleBg,
              shape: BoxShape.circle,
              border: ringColor != null
                  ? Border.all(color: ringColor, width: isToday ? 2.0 : 1.5)
                  : null,
              boxShadow: isToday
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$dateNumber',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: circleFg,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 5),

          // ── Activity indicator ──
          SizedBox(
            height: 5,
            child: hasAttempt
                ? Container(
                    width: 14,
                    height: 3,
                    decoration: BoxDecoration(
                      color: ScoreBand.color(score).withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
