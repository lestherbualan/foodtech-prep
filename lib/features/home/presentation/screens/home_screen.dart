import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/responsive_utils.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/quick_action_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../exam/domain/dashboard_stats.dart';
import '../../../exam/domain/exam_subject.dart';
import '../../../exam/domain/saved_exam_attempt.dart';
import '../../../exam/presentation/providers/dashboard_providers.dart';
import '../../../exam/presentation/providers/weekly_performance_providers.dart';
import '../../../exam/presentation/widgets/weekly_timed_exam_performance_strip.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static Color _countdownColor(int daysLeft) {
    if (daysLeft == 0) return const Color(0xFFB71C1C); // strong red — today
    if (daysLeft <= 7) return AppColors.error; // red — urgent
    if (daysLeft <= 30) return const Color(0xFFD35400); // deep orange — close
    if (daysLeft <= 90)
      return AppColors.warning; // warning orange — getting serious
    return AppColors.primaryLight; // teal — calm preparation
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final firstName =
        user?.displayName?.split(' ').first ??
        user?.email?.split('@').first ??
        'Student';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Smart greeting header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.pageHorizontalPad,
                  AppSpacing.lg,
                  context.pageHorizontalPad,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_timeGreeting()}, $firstName',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontSize: context.responsiveFontSize(24),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          Builder(
                            builder: (context) {
                              final examDate = AppConstants.boardExamDate;
                              final now = DateTime.now();
                              final today = DateTime(
                                now.year,
                                now.month,
                                now.day,
                              );
                              final daysLeft = examDate
                                  .difference(today)
                                  .inDays;
                              if (daysLeft < 0) return const SizedBox.shrink();
                              final text = daysLeft == 0
                                  ? 'Board exam is today'
                                  : '$daysLeft day${daysLeft == 1 ? '' : 's'} until the Food Technologist Board Exam';
                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.xs + 2,
                                ),
                                child: Text(
                                  text,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: _countdownColor(daysLeft),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.1,
                                        fontSize: context
                                            .responsiveSecondaryFontSize(12),
                                      ),
                                ),
                              );
                            },
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
                          backgroundColor: context.appPrimarySurfaceColor,
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

            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.md + 4),
            ),

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
    final weeklyAsync = ref.watch(weeklyTimedExamSummaryProvider(userId));

    return statsAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => SliverToBoxAdapter(child: _EmptyDashboard()),
      data: (stats) {
        if (stats.totalAttempts == 0) {
          return SliverToBoxAdapter(child: _EmptyDashboard());
        }
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: context.pageHorizontalPad),
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

              // ── 3b. Weekly timed exam performance strip ──
              if (weeklyAsync case AsyncData(:final value)) ...[
                SectionHeader(
                  title: 'This Week',
                  trailingText: 'Calendar',
                  onTrailingTap: () =>
                      context.push(RouteNames.performanceCalendar),
                ),
                GestureDetector(
                  onTap: () => context.push(RouteNames.performanceCalendar),
                  child: WeeklyTimedExamPerformanceStrip(
                    summary: value,
                    onDayTap: (_) =>
                        context.push(RouteNames.performanceCalendar),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

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

              // ── 6. Recent activity (interactive) ──
              if (stats.recentAttempts.isNotEmpty) ...[
                SectionHeader(
                  title: 'Recent Activity',
                  trailingText: 'View All',
                  onTrailingTap: () => context.push(RouteNames.examHistory),
                ),
                _RecentActivityList(attempts: stats.recentAttempts),
                const SizedBox(height: AppSpacing.xxl),
              ],
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
      padding: EdgeInsets.symmetric(horizontal: context.pageHorizontalPad),
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
                    gradient: context.appPrimaryGradient,
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
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Start your first exam to begin tracking your progress and get personalized study recommendations.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.5),
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
            subtitle: 'Start a quick exam or full mock',
            iconColor: AppColors.secondary,
            onTap: () => _showTimedExamChooserSheet(context),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          QuickActionCard(
            icon: Icons.menu_book_rounded,
            title: 'Subject Practice',
            subtitle: 'Study a specific subject your way',
            iconColor: AppColors.primary,
            onTap: () => context.push(RouteNames.subjectPractice),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          QuickActionCard(
            icon: Icons.grid_view_rounded,
            title: 'Question Bank',
            subtitle: 'Browse questions by subject',
            iconColor: AppColors.accent,
            onTap: () => context.push(RouteNames.questionBank),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 1. Hero performance card — dominant latest score with context
// ═══════════════════════════════════════════════════════════════════════════════

class _HeroPerformanceCard extends StatelessWidget {
  const _HeroPerformanceCard({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final focusSubject = stats.weakestSubject != null
        ? ExamSubject.abbreviate(stats.weakestSubject!)
        : null;

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.lg + 4),
      elevated: true,
      gradient: context.appHeroGradient,
      child: Column(
        children: [
          // ── Top: score ring + dominant score + context ──
          Row(
            children: [
              _ScoreRing(score: stats.latestScore),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stats.latestScore.round()}%',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(38),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Latest Score',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.75),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // ── Context line ──
                    Text(
                      _contextLine(focusSubject),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.55),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md + 4),
          // ── Bottom: supporting stats bar ──
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md + 4,
              vertical: AppSpacing.sm + 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
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
          // ── Trend chip ──
          const SizedBox(height: AppSpacing.sm + 4),
          _PerformanceTrendChip(
            trend: stats.trend,
            explanation: stats.trendExplanation,
          ),
        ],
      ),
    );
  }

  String _contextLine(String? focusSubject) {
    final parts = <String>[];
    parts.add(
      '${stats.totalAttempts} exam${stats.totalAttempts == 1 ? '' : 's'}',
    );
    if (focusSubject != null) {
      parts.add('Focus next: $focusSubject');
    }
    return parts.join(' · ');
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
                  fontWeight: FontWeight.w700,
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
            style: TextStyle(
              fontSize: context.responsiveFontSize(16),
              fontWeight: FontWeight.w700,
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
          subtitle: 'Start a quick exam or full mock',
          iconColor: AppColors.secondary,
          onTap: () => _showTimedExamChooserSheet(context),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        QuickActionCard(
          icon: Icons.menu_book_rounded,
          title: 'Subject Practice',
          subtitle: 'Study a specific subject your way',
          iconColor: AppColors.primary,
          onTap: () => context.push(RouteNames.subjectPractice),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        QuickActionCard(
          icon: Icons.track_changes_rounded,
          title: 'Weak Areas',
          subtitle: stats.weakestSubject != null
              ? 'Focus: ${ExamSubject.abbreviate(stats.weakestSubject!)}'
              : 'Focus on your weakest topics',
          iconColor: AppColors.warning,
          onTap: () => context.push(RouteNames.weakAreas),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        QuickActionCard(
          icon: Icons.insights_rounded,
          title: 'Progress',
          subtitle: 'Track your scores and trends',
          iconColor: AppColors.accent,
          onTap: () => context.push(RouteNames.dashboard),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. Performance snapshot — unified card with hierarchy
// ═══════════════════════════════════════════════════════════════════════════════

class _PerformanceGrid extends StatelessWidget {
  const _PerformanceGrid({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md + 4),
      child: Column(
        children: [
          // ── Primary metric: average score ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md + 2,
              horizontal: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: context.appPrimarySurfaceColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: context.appPrimaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Average Score',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${stats.averageScore.round()}%',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontSize: context.responsiveFontSize(20),
                              fontWeight: FontWeight.w700,
                              color: context.appPrimaryColor,
                              letterSpacing: -0.5,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // ── Supporting metrics row ──
          Row(
            children: [
              _SnapshotMetric(
                icon: Icons.emoji_events_rounded,
                label: 'Best Score',
                value: '${stats.bestScore.round()}%',
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              _SnapshotMetric(
                icon: Icons.assignment_rounded,
                label: 'Exams Taken',
                value: '${stats.totalAttempts}',
                color: AppColors.secondary,
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              _SnapshotMetric(
                icon: Icons.update_rounded,
                label: 'Latest',
                value: '${stats.latestScore.round()}%',
                color: AppColors.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SnapshotMetric extends StatelessWidget {
  const _SnapshotMetric({
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm + 4,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: context.responsiveFontSize(16),
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
            const SizedBox(height: AppSpacing.sm + 4),
            // ── Tappable affordance ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View Subject Breakdown',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.appPrimaryColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: context.appPrimaryColor,
                ),
              ],
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$label:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  fullName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appTextHintColor,
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
      color: context.appPrimarySurfaceColor.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: context.appPrimaryGradient,
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
                  fontSize: context.responsiveFontSize(14),
                  fontWeight: FontWeight.w700,
                  color: context.appPrimaryColor,
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
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(height: 1.5),
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
// 6. Recent activity (interactive)
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

    return Material(
      color: context.appCardColor,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () => context.push(RouteNames.attemptDetail, extra: attempt),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
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
                    fontWeight: FontWeight.w700,
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
                      attempt.mode == 'board_exam_style'
                          ? 'Subject TOS Mock'
                          : attempt.mode == 'subject_tos_mock'
                          ? 'Subject TOS Mock'
                          : attempt.mode == 'full_mock_exam'
                          ? 'Full Mock Exam'
                          : 'Timed Exam',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${attempt.correctCount}/${attempt.totalQuestions} correct  ·  $dateStr',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Chevron affordance
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: context.appTextHintColor,
              ),
            ],
          ),
        ),
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
// Performance trend chip — inline inside hero card
// ═══════════════════════════════════════════════════════════════════════════════

class _PerformanceTrendChip extends StatelessWidget {
  const _PerformanceTrendChip({required this.trend, required this.explanation});

  final TrendDirection trend;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final (icon, label, accent) = switch (trend) {
      TrendDirection.improving => (
        Icons.trending_up_rounded,
        'Improving',
        const Color(0xFF66BB6A),
      ),
      TrendDirection.steady => (
        Icons.trending_flat_rounded,
        'Steady',
        const Color(0xFF90CAF9),
      ),
      TrendDirection.declining => (
        Icons.trending_down_rounded,
        'Needs Attention',
        const Color(0xFFEF9A9A),
      ),
      TrendDirection.insufficient => (
        Icons.show_chart_rounded,
        'Still Early',
        Colors.white.withValues(alpha: 0.6),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          // ── Accent icon pill ──
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: AppSpacing.md - 2),
          // ── Label + explanation ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: context.responsiveSecondaryFontSize(13),
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  explanation,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.55),
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Timed Exam mode chooser — bottom sheet
// ═══════════════════════════════════════════════════════════════════════════════

void _showTimedExamChooserSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    builder: (sheetCtx) => _TimedExamChooserSheet(
      onQuickExam: () {
        Navigator.of(sheetCtx).pop();
        context.push(RouteNames.examSetup);
      },
      onFullMock: () {
        Navigator.of(sheetCtx).pop();
        context.push(RouteNames.fullMockSetup);
      },
    ),
  );
}

class _TimedExamChooserSheet extends StatelessWidget {
  const _TimedExamChooserSheet({
    required this.onQuickExam,
    required this.onFullMock,
  });

  final VoidCallback onQuickExam;
  final VoidCallback onFullMock;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appDividerColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Choose Exam Format',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Pick a format to get started.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            _ExamTypeOption(
              icon: Icons.timer_rounded,
              color: AppColors.secondary,
              title: 'Quick Timed Exam',
              subtitle: '60 questions · 40 minutes',
              onTap: onQuickExam,
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            _ExamTypeOption(
              icon: Icons.assignment_rounded,
              color: const Color(0xFF0D9488),
              title: 'Full Mock Exam',
              subtitle: '100 questions · full board simulation',
              onTap: onFullMock,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _ExamTypeOption extends StatelessWidget {
  const _ExamTypeOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md + 2),
          decoration: BoxDecoration(
            color: context.appSurfaceHighColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: context.appDividerColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: context.appTextHintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
