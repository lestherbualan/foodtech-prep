import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../domain/saved_exam_attempt.dart';

/// Detailed view for a single exam attempt from Recent Activity.
class AttemptDetailScreen extends StatelessWidget {
  const AttemptDetailScreen({super.key, required this.attempt});
  final SavedExamAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final passed = attempt.scorePercent >= 50;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Attempt Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            centerTitle: true,
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.md),

                // ── Score hero ──
                PremiumCard(
                  elevated: true,
                  gradient: AppColors.heroGradient,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xl,
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    children: [
                      _ScoreCircle(score: attempt.scorePercent),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        passed ? 'Passed' : 'Needs Improvement',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${attempt.correctCount} of ${attempt.totalQuestions} correct',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Details breakdown ──
                PremiumCard(
                  padding: const EdgeInsets.all(AppSpacing.md + 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Details',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _DetailRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Date',
                        value: _formatDate(attempt.submittedAt),
                      ),
                      const _DetailDivider(),
                      _DetailRow(
                        icon: Icons.category_rounded,
                        label: 'Mode',
                        value: _capitalize(attempt.mode),
                      ),
                      const _DetailDivider(),
                      _DetailRow(
                        icon: Icons.timer_rounded,
                        label: 'Time Spent',
                        value: _formatDuration(attempt.timeSpentSeconds),
                      ),
                      if (attempt.wasAutoSubmitted) ...[
                        const _DetailDivider(),
                        _DetailRow(
                          icon: Icons.access_alarm_rounded,
                          label: 'Auto-submitted',
                          value: 'Yes — time ran out',
                          valueColor: AppColors.warning,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md + 4),

                // ── Answer breakdown ──
                PremiumCard(
                  padding: const EdgeInsets.all(AppSpacing.md + 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Answer Breakdown',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          _StatChip(
                            label: 'Correct',
                            value: '${attempt.correctCount}',
                            color: AppColors.success,
                          ),
                          const SizedBox(width: AppSpacing.sm + 2),
                          _StatChip(
                            label: 'Incorrect',
                            value: '${attempt.incorrectCount}',
                            color: AppColors.error,
                          ),
                          const SizedBox(width: AppSpacing.sm + 2),
                          _StatChip(
                            label: 'Unanswered',
                            value: '${attempt.unansweredCount}',
                            color: AppColors.textHint,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 8,
                          child: Row(
                            children: [
                              if (attempt.correctCount > 0)
                                Flexible(
                                  flex: attempt.correctCount,
                                  child: Container(color: AppColors.success),
                                ),
                              if (attempt.incorrectCount > 0)
                                Flexible(
                                  flex: attempt.incorrectCount,
                                  child: Container(color: AppColors.error),
                                ),
                              if (attempt.unansweredCount > 0)
                                Flexible(
                                  flex: attempt.unansweredCount,
                                  child: Container(
                                    color: AppColors.textHint.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md + 4),

                // ── Subject performance (if available) ──
                if (attempt.strongestSubject != null ||
                    attempt.weakestSubject != null)
                  PremiumCard(
                    padding: const EdgeInsets.all(AppSpacing.md + 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subject Performance',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (attempt.strongestSubject != null)
                          _SubjectRow(
                            icon: Icons.star_rounded,
                            label: 'Strongest',
                            subject: attempt.strongestSubject!,
                            color: AppColors.success,
                          ),
                        if (attempt.strongestSubject != null &&
                            attempt.weakestSubject != null)
                          const SizedBox(height: AppSpacing.sm + 2),
                        if (attempt.weakestSubject != null)
                          _SubjectRow(
                            icon: Icons.trending_down_rounded,
                            label: 'Weakest',
                            subject: attempt.weakestSubject!,
                            color: AppColors.warning,
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  static String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes == 0) return '${seconds}s';
    return '${minutes}m ${seconds}s';
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

// ─── Score circle ────────────────────────────────────────────────────────────

class _ScoreCircle extends StatelessWidget {
  const _ScoreCircle({required this.score});
  final double score;

  @override
  Widget build(BuildContext context) {
    final fraction = (score / 100).clamp(0.0, 1.0);
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: fraction,
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          Text(
            '${score.round()}%',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Detail row ──────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailDivider extends StatelessWidget {
  const _DetailDivider();
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5));
  }
}

// ─── Stat chip ───────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
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
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Subject row ─────────────────────────────────────────────────────────────

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    required this.icon,
    required this.label,
    required this.subject,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String subject;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              subject,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
