import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/dashboard_stats.dart';
import '../../domain/saved_exam_attempt.dart';
import '../providers/dashboard_providers.dart';
import '../providers/exam_attempt_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const Center(child: Text('Please sign in to view dashboard.')),
      );
    }

    final statsAsync = ref.watch(dashboardStatsProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Full History',
            onPressed: () => context.push(RouteNames.examHistory),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorStateWidget(
          message: 'Could not load dashboard.',
          onRetry: () => ref.invalidate(recentAttemptsProvider),
        ),
        data: (stats) {
          if (stats.totalAttempts == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const EmptyStateWidget(
                      icon: Icons.insights_rounded,
                      message:
                          'No exam data yet.\nComplete a timed exam to start tracking your progress.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: () => context.push(RouteNames.examSetup),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text('Take an Exam'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ScoreSummaryCard(stats: stats),
                const SizedBox(height: AppSpacing.md),
                _TrendCard(stats: stats),
                const SizedBox(height: AppSpacing.md),
                _SubjectSummaryCard(stats: stats),
                const SizedBox(height: AppSpacing.md),
                _FocusAdviceCard(tips: stats.focusAdvice),
                const SizedBox(height: AppSpacing.lg),
                _RecentAttemptsSection(attempts: stats.recentAttempts),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Score Summary ───────────────────────────────────────────────────────────

class _ScoreSummaryCard extends StatelessWidget {
  const _ScoreSummaryCard({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Performance',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ScoreIndicator(
                  label: 'Latest',
                  score: stats.latestScore,
                ),
              ),
              Expanded(
                child: _ScoreIndicator(label: 'Best', score: stats.bestScore),
              ),
              Expanded(
                child: _ScoreIndicator(
                  label: 'Average',
                  score: stats.averageScore,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Average bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (stats.averageScore / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                _scoreColor(stats.averageScore),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${stats.totalAttempts} exam${stats.totalAttempts != 1 ? 's' : ''} recently',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ScoreIndicator extends StatelessWidget {
  const _ScoreIndicator({required this.label, required this.score});
  final String label;
  final double score;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${score.round()}%',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: _scoreColor(score),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ─── Trend Card ──────────────────────────────────────────────────────────────

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (stats.trend) {
      TrendDirection.improving => (
        Icons.trending_up_rounded,
        AppColors.success,
        'Improving',
      ),
      TrendDirection.steady => (
        Icons.trending_flat_rounded,
        AppColors.warning,
        'Steady',
      ),
      TrendDirection.declining => (
        Icons.trending_down_rounded,
        AppColors.error,
        'Needs Attention',
      ),
      TrendDirection.insufficient => (
        Icons.show_chart_rounded,
        AppColors.textHint,
        'Not Enough Data',
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stats.trendExplanation,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Subject Summary ─────────────────────────────────────────────────────────

class _SubjectSummaryCard extends StatelessWidget {
  const _SubjectSummaryCard({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    if (stats.strongestSubject == null && stats.weakestSubject == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subject Trends',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          if (stats.strongestSubject != null)
            _SubjectRow(
              icon: Icons.star_rounded,
              label: 'Strongest',
              value: stats.strongestSubject!,
              color: AppColors.success,
            ),
          if (stats.strongestSubject != null && stats.weakestSubject != null)
            const SizedBox(height: AppSpacing.sm),
          if (stats.weakestSubject != null)
            _SubjectRow(
              icon: Icons.flag_rounded,
              label: 'Needs Work',
              value: stats.weakestSubject!,
              color: AppColors.error,
            ),
        ],
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Focus Advice ────────────────────────────────────────────────────────────

class _FocusAdviceCard extends StatelessWidget {
  const _FocusAdviceCard({required this.tips});
  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    if (tips.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'What to Focus On',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      tip,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Recent Attempts ─────────────────────────────────────────────────────────

class _RecentAttemptsSection extends StatelessWidget {
  const _RecentAttemptsSection({required this.attempts});
  final List<SavedExamAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Exams',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...attempts
            .take(5)
            .map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _MiniAttemptRow(attempt: a),
              ),
            ),
      ],
    );
  }
}

class _MiniAttemptRow extends StatelessWidget {
  const _MiniAttemptRow({required this.attempt});
  final SavedExamAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final passed = attempt.scorePercent >= 50;
    final dateStr = _shortDate(attempt.submittedAt);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Score bar
          SizedBox(
            width: 40,
            child: Text(
              '${attempt.scorePercent.round()}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: passed ? AppColors.success : AppColors.error,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Mini progress bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (attempt.scorePercent / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(
                  passed ? AppColors.success : AppColors.error,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Stats chips
          Text(
            '${attempt.correctCount}/${attempt.totalQuestions}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          // Date
          Text(
            dateStr,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  static String _shortDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

Color _scoreColor(double score) {
  if (score >= 75) return AppColors.success;
  if (score >= 50) return AppColors.warning;
  return AppColors.error;
}
