import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/quick_action_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../exam/domain/dashboard_stats.dart';
import '../../../exam/domain/exam_subject.dart';
import '../../../exam/domain/saved_exam_attempt.dart';
import '../../../exam/presentation/providers/dashboard_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final firstName =
        user?.displayName?.split(' ').first ??
        user?.email?.split('@').first ??
        'Student';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Premium top bar with greeting ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $firstName!',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs + 2),
                          Text(
                            'Keep building momentum for your board exam.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    GestureDetector(
                      onTap: () => context.push(RouteNames.profile),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primarySurface,
                          backgroundImage: user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          child: user?.photoURL == null
                              ? const Icon(
                                  Icons.person_rounded,
                                  size: 22,
                                  color: AppColors.primary,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

            // ── Body content ──
            if (user != null)
              _DashboardBody(userId: user.uid)
            else
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Sign in to see your dashboard',
                    style: Theme.of(context).textTheme.bodyMedium,
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
// Dashboard body
// ═══════════════════════════════════════════════════════════════════════════════

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider(userId));

    return statsAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, _) => SliverToBoxAdapter(child: _EmptyDashboard()),
      data: (stats) {
        if (stats.totalAttempts == 0) {
          return SliverToBoxAdapter(child: _EmptyDashboard());
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── 1. Hero performance card ──
              _HeroPerformanceCard(stats: stats),
              const SizedBox(height: AppSpacing.xl),

              // ── 2. Quick actions ──
              const SectionHeader(title: 'Quick Actions'),
              _QuickActionsSection(stats: stats),
              const SizedBox(height: AppSpacing.xl),

              // ── 3. Performance snapshot grid ──
              const SectionHeader(title: 'Performance Snapshot'),
              _PerformanceGrid(stats: stats),
              const SizedBox(height: AppSpacing.xl),

              // ── 4. Strength & weakness ──
              if (stats.strongestSubject != null ||
                  stats.weakestSubject != null) ...[
                SectionHeader(
                  title: 'Subject Insights',
                  trailingText: 'View Details',
                  onTrailingTap: () =>
                      context.push(RouteNames.subjectBreakdown),
                ),
                _SubjectInsightsCard(stats: stats),
                const SizedBox(height: AppSpacing.xl),
              ],

              // ── 5. What to focus on ──
              if (stats.focusAdvice.isNotEmpty) ...[
                const SectionHeader(title: 'What to Focus On'),
                _FocusRecommendations(tips: stats.focusAdvice),
                const SizedBox(height: AppSpacing.xl),
              ],

              // ── 6. Recent activity ──
              if (stats.recentAttempts.isNotEmpty) ...[
                SectionHeader(
                  title: 'Recent Activity',
                  trailingText: 'View All',
                  onTrailingTap: () => context.push(RouteNames.examHistory),
                ),
                _RecentActivityList(attempts: stats.recentAttempts),
                const SizedBox(height: AppSpacing.xl),
              ],

              // ── 7. Trend insight ──
              _TrendBanner(stats: stats),
              const SizedBox(height: AppSpacing.xxl),
            ]),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Empty state dashboard
// ═══════════════════════════════════════════════════════════════════════════════

class _EmptyDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          // Welcome card
          PremiumCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            elevated: true,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md + 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Welcome to FoodTech Prep',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Start your first exam to begin tracking your progress and get personalized study recommendations.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Quick actions for new users
          const SectionHeader(title: 'Get Started'),
          QuickActionCard(
            icon: Icons.timer_rounded,
            title: 'Timed Exam',
            subtitle: '60 questions • 40 minutes',
            iconColor: AppColors.secondary,
            onTap: () => context.push(RouteNames.examSetup),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          QuickActionCard(
            icon: Icons.menu_book_rounded,
            title: 'Question Bank',
            subtitle: 'Browse and practice by subject',
            iconColor: AppColors.primary,
            onTap: () => context.push(RouteNames.questionBank),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 1. Hero performance card — the visual anchor
// ═══════════════════════════════════════════════════════════════════════════════

class _HeroPerformanceCard extends StatelessWidget {
  const _HeroPerformanceCard({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.lg + 4),
      elevated: true,
      gradient: AppColors.heroGradient,
      child: Column(
        children: [
          Row(
            children: [
              // Score ring
              _ScoreRing(score: stats.latestScore),
              const SizedBox(width: AppSpacing.lg + 4),
              // Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latest Score',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${stats.latestScore.round()}%',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                _HeroMiniStat(
                  label: 'Best',
                  value: '${stats.bestScore.round()}%',
                ),
                _heroDivider(),
                _HeroMiniStat(
                  label: 'Average',
                  value: '${stats.averageScore.round()}%',
                ),
                _heroDivider(),
                _HeroMiniStat(label: 'Exams', value: '${stats.totalAttempts}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroDivider() {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score});
  final double score;

  @override
  Widget build(BuildContext context) {
    final fraction = (score / 100).clamp(0.0, 1.0);

    return SizedBox(
      width: 78,
      height: 78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 78,
            height: 78,
            child: CircularProgressIndicator(
              value: fraction,
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${score.round()}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                '%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMiniStat extends StatelessWidget {
  const _HeroMiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2. Quick actions
// ═══════════════════════════════════════════════════════════════════════════════

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        QuickActionCard(
          icon: Icons.timer_rounded,
          title: 'Timed Exam',
          subtitle: '60 questions • 40 minutes',
          iconColor: AppColors.secondary,
          onTap: () => context.push(RouteNames.examSetup),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        QuickActionCard(
          icon: Icons.menu_book_rounded,
          title: 'Subject Practice',
          subtitle: 'Choose what you want to study',
          iconColor: AppColors.primary,
          onTap: () => context.push(RouteNames.subjectPractice),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        QuickActionCard(
          icon: Icons.track_changes_rounded,
          title: 'Weak Areas',
          subtitle: stats.weakestSubject != null
              ? 'Focus: ${ExamSubject.abbreviate(stats.weakestSubject!)}'
              : 'Personalised recommendations',
          iconColor: AppColors.warning,
          onTap: () => context.push(RouteNames.weakAreas),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        QuickActionCard(
          icon: Icons.insights_rounded,
          title: 'Progress',
          subtitle: 'Scores, trends & insights',
          iconColor: AppColors.accent,
          onTap: () => context.push(RouteNames.dashboard),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. Performance snapshot grid
// ═══════════════════════════════════════════════════════════════════════════════

class _PerformanceGrid extends StatelessWidget {
  const _PerformanceGrid({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PerformanceGridItem(
            icon: Icons.emoji_events_rounded,
            label: 'Best',
            value: '${stats.bestScore.round()}%',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.sm + 2),
        Expanded(
          child: _PerformanceGridItem(
            icon: Icons.analytics_rounded,
            label: 'Average',
            value: '${stats.averageScore.round()}%',
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm + 2),
        Expanded(
          child: _PerformanceGridItem(
            icon: Icons.assignment_rounded,
            label: 'Exams',
            value: '${stats.totalAttempts}',
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _PerformanceGridItem extends StatelessWidget {
  const _PerformanceGridItem({
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
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md + 4,
        horizontal: AppSpacing.sm,
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 4. Subject insights
// ═══════════════════════════════════════════════════════════════════════════════

class _SubjectInsightsCard extends StatelessWidget {
  const _SubjectInsightsCard({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final strongAbbr = stats.strongestSubject != null
        ? ExamSubject.abbreviate(stats.strongestSubject!)
        : null;
    final weakAbbr = stats.weakestSubject != null
        ? ExamSubject.abbreviate(stats.weakestSubject!)
        : null;

    return GestureDetector(
      onTap: () => context.push(RouteNames.subjectBreakdown),
      child: PremiumCard(
        padding: const EdgeInsets.all(AppSpacing.md + 4),
        child: Column(
          children: [
            if (strongAbbr != null)
              _SubjectInsightRow(
                icon: Icons.star_rounded,
                label: 'Strongest',
                value: strongAbbr,
                fullName: stats.strongestSubject!,
                color: AppColors.success,
              ),
            if (strongAbbr != null && weakAbbr != null)
              const SizedBox(height: AppSpacing.sm + 2),
            if (weakAbbr != null)
              _SubjectInsightRow(
                icon: Icons.trending_down_rounded,
                label: 'Needs Work',
                value: weakAbbr,
                fullName: stats.weakestSubject!,
                color: AppColors.warning,
              ),
          ],
        ),
      ),
    );
  }
}

class _SubjectInsightRow extends StatelessWidget {
  const _SubjectInsightRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.fullName,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String fullName;
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
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              fullName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textHint,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 5. Focus recommendations
// ═══════════════════════════════════════════════════════════════════════════════

class _FocusRecommendations extends StatelessWidget {
  const _FocusRecommendations({required this.tips});
  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md + 4),
      color: AppColors.primarySurface.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Text(
                'Recommendations',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...tips
              .take(3)
              .map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm + 2),
                      Expanded(
                        child: Text(
                          tip,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                height: 1.5,
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

// ═══════════════════════════════════════════════════════════════════════════════
// 6. Recent activity
// ═══════════════════════════════════════════════════════════════════════════════

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList({required this.attempts});
  final List<SavedExamAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: attempts
          .take(4)
          .map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
              child: _RecentActivityRow(attempt: a),
            ),
          )
          .toList(),
    );
  }
}

class _RecentActivityRow extends StatelessWidget {
  const _RecentActivityRow({required this.attempt});
  final SavedExamAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final passed = attempt.scorePercent >= 50;
    final color = passed ? AppColors.success : AppColors.error;
    final dateStr = _shortDate(attempt.submittedAt);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Score badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              '${attempt.scorePercent.round()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Timed Exam',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '${attempt.correctCount}/${attempt.totalQuestions} correct  •  $dateStr',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Mini progress bar
          SizedBox(
            width: 44,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (attempt.scorePercent / 100).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
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

// ═══════════════════════════════════════════════════════════════════════════════
// 7. Trend banner
// ═══════════════════════════════════════════════════════════════════════════════

class _TrendBanner extends StatelessWidget {
  const _TrendBanner({required this.stats});
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
        AppColors.secondary,
        'Steady',
      ),
      TrendDirection.declining => (
        Icons.trending_down_rounded,
        AppColors.warning,
        'Needs Attention',
      ),
      TrendDirection.insufficient => (
        Icons.show_chart_rounded,
        AppColors.textHint,
        'Building Data',
      ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trend: $label',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  stats.trendExplanation,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
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
