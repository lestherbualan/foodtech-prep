import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/secondary_screen_header.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/dashboard_stats.dart';
import '../../domain/exam_subject.dart';
import '../providers/dashboard_providers.dart';

/// Shows all 4 subjects ranked by performance with scores and insights.
class SubjectBreakdownScreen extends ConsumerWidget {
  const SubjectBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: SecondaryScreenHeader(
              title: 'Subject Breakdown',
              subtitle: 'Performance across all subjects',
            ),
          ),
          if (user == null)
            const SliverFillRemaining(
              child: Center(child: Text('Sign in to view breakdown.')),
            )
          else
            _BreakdownBody(userId: user.uid),
        ],
      ),
    );
  }
}

class _BreakdownBody extends ConsumerWidget {
  const _BreakdownBody({required this.userId});
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
      error: (_, _) => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text('Could not load performance data.'),
        ),
      ),
      data: (stats) {
        if (stats.totalAttempts == 0) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: PremiumCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                elevated: true,
                child: Column(
                  children: [
                    const Icon(
                      Icons.bar_chart_rounded,
                      size: 48,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No Exam Data Yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Complete timed exams to see a performance breakdown across all subjects.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: AppSpacing.sm),

              // ── Summary ──
              _SummaryRow(stats: stats),
              const SizedBox(height: AppSpacing.xl),

              // ── Subject cards ──
              const SectionHeader(title: 'Subject Rankings'),
              ..._buildSubjectCards(context, stats),

              const SizedBox(height: AppSpacing.xl),

              // ── Focus note ──
              if (stats.focusAdvice.isNotEmpty) ...[
                const SectionHeader(title: 'Focus Recommendation'),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md + 2),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.lightbulb_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm + 2),
                      Expanded(
                        child: Text(
                          stats.focusAdvice.first,
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
              ],

              const SizedBox(height: AppSpacing.xxl),
            ]),
          ),
        );
      },
    );
  }

  List<Widget> _buildSubjectCards(BuildContext context, DashboardStats stats) {
    // Build a list of the 4 official subjects with their stats
    final subjects = <_SubjectRankData>[];

    for (final opt in ExamSubject.options.where((s) => !s.isAll)) {
      final isStrongest =
          stats.strongestSubject != null &&
          ExamSubject.abbreviate(stats.strongestSubject!) == opt.id;
      final isWeakest =
          stats.weakestSubject != null &&
          ExamSubject.abbreviate(stats.weakestSubject!) == opt.id;

      subjects.add(
        _SubjectRankData(
          abbr: opt.label,
          fullName: opt.subtitle,
          isStrongest: isStrongest,
          isWeakest: isWeakest,
        ),
      );
    }

    // Sort: strongest first, weakest last
    subjects.sort((a, b) {
      if (a.isStrongest) return -1;
      if (b.isStrongest) return 1;
      if (a.isWeakest) return 1;
      if (b.isWeakest) return -1;
      return 0;
    });

    return subjects.asMap().entries.map((entry) {
      final rank = entry.key + 1;
      final s = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
        child: _SubjectRankCard(rank: rank, data: s),
      );
    }).toList();
  }
}

// ─── Summary row ─────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final strongAbbr = stats.strongestSubject != null
        ? ExamSubject.abbreviate(stats.strongestSubject!)
        : '—';
    final weakAbbr = stats.weakestSubject != null
        ? ExamSubject.abbreviate(stats.weakestSubject!)
        : '—';

    return Row(
      children: [
        Expanded(
          child: _SummaryChip(
            label: 'Strongest',
            value: strongAbbr,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.sm + 2),
        Expanded(
          child: _SummaryChip(
            label: 'Weakest',
            value: weakAbbr,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.sm + 2),
        Expanded(
          child: _SummaryChip(
            label: 'Exams',
            value: '${stats.totalAttempts}',
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md + 2,
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
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
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

// ─── Subject rank data ───────────────────────────────────────────────────────

class _SubjectRankData {
  const _SubjectRankData({
    required this.abbr,
    required this.fullName,
    required this.isStrongest,
    required this.isWeakest,
  });

  final String abbr;
  final String fullName;
  final bool isStrongest;
  final bool isWeakest;
}

class _SubjectRankCard extends StatelessWidget {
  const _SubjectRankCard({required this.rank, required this.data});

  final int rank;
  final _SubjectRankData data;

  @override
  Widget build(BuildContext context) {
    final badgeColor = data.isStrongest
        ? AppColors.success
        : data.isWeakest
        ? AppColors.warning
        : AppColors.textSecondary;

    final badgeLabel = data.isStrongest
        ? 'Strongest'
        : data.isWeakest
        ? 'Needs Work'
        : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: data.isStrongest
              ? AppColors.success.withValues(alpha: 0.3)
              : data.isWeakest
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank number
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Subject info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.abbr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.fullName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Badge
          if (badgeLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                badgeLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
