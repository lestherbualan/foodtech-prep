import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/score_band.dart';
import '../../../../core/widgets/secondary_screen_header.dart';
import '../../domain/daily_timed_exam_detail.dart';
import '../../domain/monthly_timed_exam_summary.dart';
import '../../domain/saved_exam_attempt.dart';
import '../providers/monthly_performance_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class PerformanceCalendarScreen extends ConsumerStatefulWidget {
  const PerformanceCalendarScreen({super.key});

  @override
  ConsumerState<PerformanceCalendarScreen> createState() =>
      _PerformanceCalendarScreenState();
}

class _PerformanceCalendarScreenState
    extends ConsumerState<PerformanceCalendarScreen> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;

  static final _today = () {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }();

  static final _boardExamDate = () {
    final d = AppConstants.boardExamDate;
    return DateTime(d.year, d.month, d.day);
  }();

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(_today.year, _today.month);
    _selectedDate = _today;
  }

  void _goToPreviousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
      );
    });
  }

  void _goToNextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
      );
    });
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final monthKey = (
      userId: user.uid,
      year: _displayedMonth.year,
      month: _displayedMonth.month,
    );
    final monthAsync = ref.watch(monthlyTimedExamSummaryProvider(monthKey));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ──
          const SecondaryScreenHeader(
            title: 'Performance Calendar',
            subtitle: 'Timed exams only',
          ),

          // ── Content ──
          Expanded(
            child: monthAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, _) => Center(
                child: Text(
                  'Unable to load calendar data.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              data: (summary) => _CalendarContent(
                summary: summary,
                displayedMonth: _displayedMonth,
                selectedDate: _selectedDate,
                today: _today,
                boardExamDate: _boardExamDate,
                onPreviousMonth: _goToPreviousMonth,
                onNextMonth: _goToNextMonth,
                onSelectDate: _selectDate,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Calendar content (loaded state)
// ═══════════════════════════════════════════════════════════════════════════════

class _CalendarContent extends StatelessWidget {
  const _CalendarContent({
    required this.summary,
    required this.displayedMonth,
    required this.selectedDate,
    required this.today,
    required this.boardExamDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDate,
  });

  final MonthlyTimedExamSummary summary;
  final DateTime displayedMonth;
  final DateTime selectedDate;
  final DateTime today;
  final DateTime boardExamDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final detail = summary.detailFor(selectedDate);
    final attempts = summary.attemptsFor(selectedDate);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        // ── Month navigation ──
        _MonthNavigation(
          displayedMonth: displayedMonth,
          onPrevious: onPreviousMonth,
          onNext: onNextMonth,
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Calendar grid card ──
        _CalendarGrid(
          summary: summary,
          selectedDate: selectedDate,
          today: today,
          boardExamDate: boardExamDate,
          onSelectDate: onSelectDate,
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Daily summary card ──
        _DailySummaryCard(
          detail: detail,
          isBoardExamDay: _isSameDay(selectedDate, boardExamDate),
        ),

        // ── Daily attempts drilldown ──
        if (attempts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _DailyAttemptsSection(attempts: attempts),
        ],

        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Month navigation
// ═══════════════════════════════════════════════════════════════════════════════

class _MonthNavigation extends StatelessWidget {
  const _MonthNavigation({
    required this.displayedMonth,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime displayedMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat.yMMMM().format(displayedMonth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _NavButton(icon: Icons.chevron_left_rounded, onTap: onPrevious),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        _NavButton(icon: Icons.chevron_right_rounded, onTap: onNext),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
        ),
        child: Icon(icon, size: 20, color: AppColors.textSecondary),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Calendar grid
// ═══════════════════════════════════════════════════════════════════════════════

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.summary,
    required this.selectedDate,
    required this.today,
    required this.boardExamDate,
    required this.onSelectDate,
  });

  final MonthlyTimedExamSummary summary;
  final DateTime selectedDate;
  final DateTime today;
  final DateTime boardExamDate;
  final ValueChanged<DateTime> onSelectDate;

  static const _weekdayLabels = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  @override
  Widget build(BuildContext context) {
    final year = summary.year;
    final month = summary.month;
    final daysInMonth = summary.daysInMonth;
    final firstWeekday = DateTime(year, month, 1).weekday % 7; // Sun=0

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
      child: Column(
        children: [
          // ── Weekday header row ──
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: _weekdayLabels
                  .map(
                    (label) => Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.sm),

          // ── Date cells ──
          ..._buildWeeks(context, year, month, daysInMonth, firstWeekday),
        ],
      ),
    );
  }

  List<Widget> _buildWeeks(
    BuildContext context,
    int year,
    int month,
    int daysInMonth,
    int firstWeekday,
  ) {
    final weeks = <Widget>[];
    var dayCounter = 1;

    // Up to 6 weeks can appear in a month grid.
    for (var w = 0; w < 6; w++) {
      if (dayCounter > daysInMonth) break;

      final cells = <Widget>[];
      for (var d = 0; d < 7; d++) {
        if ((w == 0 && d < firstWeekday) || dayCounter > daysInMonth) {
          cells.add(const Expanded(child: SizedBox(height: 44)));
        } else {
          final date = DateTime(year, month, dayCounter);
          final detail = summary.detailFor(date);
          final isSelected = _isSameDay(date, selectedDate);
          final isToday = _isSameDay(date, today);
          final isBoardExam = _isSameDay(date, boardExamDate);

          cells.add(
            Expanded(
              child: _CalendarDayCell(
                day: dayCounter,
                detail: detail,
                isSelected: isSelected,
                isToday: isToday,
                isBoardExam: isBoardExam,
                onTap: () => onSelectDate(date),
              ),
            ),
          );
          dayCounter++;
        }
      }

      weeks.add(
        Padding(
          padding: EdgeInsets.only(top: w > 0 ? 4.0 : 0),
          child: Row(children: cells),
        ),
      );
    }
    return weeks;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Calendar day cell
// ═══════════════════════════════════════════════════════════════════════════════

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.detail,
    required this.isSelected,
    required this.isToday,
    required this.isBoardExam,
    required this.onTap,
  });

  final int day;
  final DailyTimedExamDetail detail;
  final bool isSelected;
  final bool isToday;
  final bool isBoardExam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasAttempt = detail.hasAttempt;
    final score = detail.averageScore;

    // ── Colour resolution ──
    final Color bg;
    final Color fg;

    if (isSelected) {
      bg = AppColors.primary;
      fg = AppColors.textOnPrimary;
    } else if (hasAttempt) {
      bg = ScoreBand.surface(score);
      fg = ScoreBand.foregroundOnSurface(score);
    } else if (isToday) {
      bg = AppColors.primarySurface;
      fg = AppColors.primary;
    } else {
      bg = Colors.transparent;
      fg = AppColors.textHint; // emptier dates recede
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Circle ──
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.primary, width: 2)
                    : hasAttempt && !isSelected
                    ? Border.all(
                        color: ScoreBand.color(score).withValues(alpha: 0.3),
                        width: 1.5,
                      )
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: (isSelected || isToday || hasAttempt)
                      ? FontWeight.w700
                      : FontWeight.w400,
                  fontSize: 12.5,
                ),
              ),
            ),

            // ── Board exam star ──
            if (isBoardExam)
              Positioned(
                top: 1,
                right: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.secondaryLight.withValues(alpha: 0.3)
                        : AppColors.secondarySurface,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.star_rounded,
                    size: 13,
                    color: isSelected
                        ? AppColors.secondaryLight
                        : AppColors.secondary,
                  ),
                ),
              ),

            // ── Activity bar ──
            if (hasAttempt && !isSelected)
              Positioned(
                bottom: 3,
                child: Container(
                  width: 14,
                  height: 3,
                  decoration: BoxDecoration(
                    color: ScoreBand.color(score).withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Daily summary card
// ═══════════════════════════════════════════════════════════════════════════════

class _DailySummaryCard extends StatelessWidget {
  const _DailySummaryCard({required this.detail, required this.isBoardExamDay});

  final DailyTimedExamDetail detail;
  final bool isBoardExamDay;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat.yMMMEd().format(detail.date);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md + 4),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Date header + optional board exam badge ──
          Row(
            children: [
              Expanded(
                child: Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (isBoardExamDay)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySurface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Board Exam',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.secondaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          if (!detail.hasAttempt)
            _EmptyDayState()
          else
            _PopulatedDaySummary(detail: detail),
        ],
      ),
    );
  }
}

// ── Empty day ──

class _EmptyDayState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.event_busy_rounded,
                size: 22,
                color: AppColors.textHint.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            Text(
              'No timed exams on this day',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Populated day summary ──

class _PopulatedDaySummary extends StatelessWidget {
  const _PopulatedDaySummary({required this.detail});

  final DailyTimedExamDetail detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Primary metric: average score ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md + 2,
          ),
          decoration: BoxDecoration(
            color: ScoreBand.surface(detail.averageScore),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: ScoreBand.color(
                detail.averageScore,
              ).withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ScoreBand.color(
                    detail.averageScore,
                  ).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${detail.averageScore!.round()}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ScoreBand.foregroundOnSurface(detail.averageScore),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Average Score',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${detail.averageScore!.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ScoreBand.foregroundOnSurface(
                          detail.averageScore,
                        ),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // ── Supporting metric chips ──
        Row(
          children: [
            _MetricChip(
              label: 'Exams',
              value: '${detail.timedExamCount}',
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            _MetricChip(
              label: 'Best',
              value: '${detail.bestScore!.round()}%',
              color: AppColors.success,
            ),
            const SizedBox(width: AppSpacing.sm),
            _MetricChip(
              label: 'Lowest',
              value: '${detail.lowestScore!.round()}%',
              color: AppColors.error,
            ),
            const SizedBox(width: AppSpacing.sm),
            _MetricChip(
              label: 'Questions',
              value: '${detail.totalQuestions}',
              color: AppColors.accent,
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm + 4,
          horizontal: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Daily attempts drilldown
// ═══════════════════════════════════════════════════════════════════════════════

class _DailyAttemptsSection extends StatelessWidget {
  const _DailyAttemptsSection({required this.attempts});

  final List<SavedExamAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──
        Row(
          children: [
            Text(
              'Timed Attempts',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                '${attempts.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm + 2),

        // ── Attempt rows ──
        ...List.generate(attempts.length, (i) {
          return Padding(
            padding: EdgeInsets.only(top: i > 0 ? AppSpacing.sm : 0),
            child: _AttemptRow(attempt: attempts[i], index: i + 1),
          );
        }),
      ],
    );
  }
}

class _AttemptRow extends StatelessWidget {
  const _AttemptRow({required this.attempt, required this.index});

  final SavedExamAttempt attempt;
  final int index;

  @override
  Widget build(BuildContext context) {
    final score = attempt.scorePercent;
    final bandColor = ScoreBand.color(score);
    final timeStr = DateFormat.jm().format(attempt.submittedAt);
    final minutes = attempt.timeSpentSeconds ~/ 60;
    final seconds = attempt.timeSpentSeconds % 60;
    final durationStr = minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => context.push(RouteNames.attemptDetail, extra: attempt),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              // ── Score circle ──
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bandColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: bandColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${score.round()}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: bandColor,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // ── Details column ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          timeStr,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '·',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textHint),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          durationStr,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${attempt.correctCount}/${attempt.totalQuestions} correct',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Chevron ──
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════════════════════

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
