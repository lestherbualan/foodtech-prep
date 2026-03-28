import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../exam/domain/dashboard_stats.dart';
import '../../../exam/presentation/providers/dashboard_providers.dart';
import '../widgets/feature_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final greeting = user?.displayName ?? user?.email ?? 'Student';

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () {
              ref.read(authActionProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $greeting!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Ready to ace your Food Technology exam?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Quick Progress Snapshot ──
              if (user != null) _ProgressSnapshot(userId: user.uid),

              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  children: [
                    FeatureCard(
                      title: AppConstants.practiceMode,
                      icon: Icons.menu_book_rounded,
                      color: AppColors.primary,
                      onTap: () => context.push(RouteNames.questionBank),
                    ),
                    FeatureCard(
                      title: AppConstants.timedExam,
                      icon: Icons.timer_rounded,
                      color: AppColors.secondary,
                      onTap: () => context.push(RouteNames.examSetup),
                    ),
                    FeatureCard(
                      title: AppConstants.results,
                      icon: Icons.bar_chart_rounded,
                      color: AppColors.warning,
                      onTap: () => context.push(RouteNames.dashboard),
                    ),
                    FeatureCard(
                      title: AppConstants.profile,
                      icon: Icons.person_rounded,
                      color: AppColors.primaryLight,
                      onTap: () => context.push(RouteNames.profile),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Progress Snapshot Card ──────────────────────────────────────────────────

class _ProgressSnapshot extends ConsumerWidget {
  const _ProgressSnapshot({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider(userId));

    return statsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (stats) {
        if (stats.totalAttempts == 0) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => context.push(RouteNames.dashboard),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                // Score circle
                _MiniScoreCircle(score: stats.latestScore),
                const SizedBox(width: AppSpacing.md),
                // Stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Latest: ${stats.latestScore.round()}%  ·  Best: ${stats.bestScore.round()}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _buildSubtitle(stats),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Trend icon
                _TrendIcon(trend: stats.trend),
              ],
            ),
          ),
        );
      },
    );
  }

  String _buildSubtitle(DashboardStats stats) {
    final parts = <String>[];
    parts.add(
      '${stats.totalAttempts} exam${stats.totalAttempts != 1 ? 's' : ''}',
    );
    if (stats.weakestSubject != null) {
      parts.add('Focus: ${stats.weakestSubject}');
    }
    return parts.join('  ·  ');
  }
}

class _MiniScoreCircle extends StatelessWidget {
  const _MiniScoreCircle({required this.score});
  final double score;

  @override
  Widget build(BuildContext context) {
    final passed = score >= 50;
    final color = passed ? AppColors.success : AppColors.error;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '${score.round()}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _TrendIcon extends StatelessWidget {
  const _TrendIcon({required this.trend});
  final TrendDirection trend;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (trend) {
      TrendDirection.improving => (
        Icons.trending_up_rounded,
        AppColors.success,
      ),
      TrendDirection.steady => (Icons.trending_flat_rounded, AppColors.warning),
      TrendDirection.declining => (
        Icons.trending_down_rounded,
        AppColors.error,
      ),
      TrendDirection.insufficient => (
        Icons.show_chart_rounded,
        AppColors.textHint,
      ),
    };

    return Icon(icon, size: 22, color: color);
  }
}
