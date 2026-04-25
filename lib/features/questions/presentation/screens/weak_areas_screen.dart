import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/secondary_screen_header.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../exam/domain/exam_subject.dart';
import '../../../exam/presentation/providers/dashboard_providers.dart';
import '../providers/question_providers.dart';

/// Recommendation-driven study entry point.
///
/// Shows the user what the app thinks they should review next,
/// based on their exam performance and weak subjects.
/// This is intentionally different from Subject Practice,
/// which is user-controlled / manual.
class WeakAreasScreen extends ConsumerWidget {
  const WeakAreasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      body: Column(
        children: [
          const SecondaryScreenHeader(
            title: 'Weak Areas',
            subtitle:
                'Review the subjects and concepts that need more attention.',
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                if (user == null)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text('Sign in to see recommendations.'),
                    ),
                  )
                else
                  _WeakAreasBody(userId: user.uid),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeakAreasBody extends ConsumerWidget {
  const _WeakAreasBody({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider(userId));
    final questionsAsync = ref.watch(questionsProvider);

    return statsAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, _) => SliverToBoxAdapter(child: _NoDataCard()),
      data: (stats) {
        if (stats.totalAttempts == 0) {
          return SliverToBoxAdapter(child: _NoDataCard());
        }

        final weakSubject = stats.weakestSubject;
        final strongSubject = stats.strongestSubject;
        final weakAbbr = weakSubject != null
            ? ExamSubject.abbreviate(weakSubject)
            : null;
        final strongAbbr = strongSubject != null
            ? ExamSubject.abbreviate(strongSubject)
            : null;

        // Count questions per weak subject
        final weakQuestionCount = questionsAsync.whenOrNull(
          data: (qs) {
            if (weakAbbr == null) return 0;
            return qs.where((q) => q.subjectId == weakAbbr).length;
          },
        );

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: AppSpacing.sm),

              // ── Weakest subject highlight ──
              if (weakSubject != null) ...[
                _WeakSubjectHeroCard(
                  subjectAbbr: weakAbbr!,
                  subjectFullName: weakSubject,
                  questionCount: weakQuestionCount ?? 0,
                  onPractice: () {
                    context.push(
                      RouteNames.questionBankSubject,
                      extra: weakAbbr,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // ── Recommendations ──
              if (stats.focusAdvice.isNotEmpty) ...[
                const SectionHeader(title: 'Recommended Actions'),
                ...stats.focusAdvice
                    .take(3)
                    .map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.sm + 2,
                        ),
                        child: _RecommendationTile(text: tip),
                      ),
                    ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // ── Performance context ──
              const SectionHeader(title: 'Performance Context'),
              PremiumCard(
                padding: const EdgeInsets.all(AppSpacing.md + 4),
                child: Column(
                  children: [
                    _ContextRow(
                      label: 'Latest Score',
                      value: '${stats.latestScore.round()}%',
                      color: _scoreColor(stats.latestScore),
                    ),
                    _contextDivider(context),
                    _ContextRow(
                      label: 'Average Score',
                      value: '${stats.averageScore.round()}%',
                      color: _scoreColor(stats.averageScore),
                    ),
                    _contextDivider(context),
                    if (strongSubject != null)
                      _ContextRow(
                        label: 'Strongest',
                        value: strongAbbr!,
                        color: AppColors.success,
                      ),
                    if (strongSubject != null && weakSubject != null)
                      _contextDivider(context),
                    if (weakSubject != null)
                      _ContextRow(
                        label: 'Weakest',
                        value: weakAbbr!,
                        color: AppColors.warning,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Quick actions ──
              const SectionHeader(title: 'Quick Actions'),
              _QuickActionTile(
                icon: Icons.timer_rounded,
                label: 'Take a Focused Timed Exam',
                subtitle: 'Practice under time pressure',
                color: AppColors.secondary,
                onTap: () => context.push(RouteNames.examSetup),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              _QuickActionTile(
                icon: Icons.menu_book_rounded,
                label: 'Browse All Subjects',
                subtitle: 'Manual exploration of question bank',
                color: AppColors.primary,
                onTap: () => context.push(RouteNames.subjectPractice),
              ),

              const SizedBox(height: AppSpacing.xxl),
            ]),
          ),
        );
      },
    );
  }

  Color _scoreColor(double score) {
    if (score >= 70) return AppColors.success;
    if (score >= 50) return AppColors.secondary;
    return AppColors.warning;
  }

  Widget _contextDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Divider(
        height: 1,
        color: context.appDividerColor.withValues(alpha: 0.5),
      ),
    );
  }
}

// ─── Weak subject hero card ──────────────────────────────────────────────────

class _WeakSubjectHeroCard extends StatelessWidget {
  const _WeakSubjectHeroCard({
    required this.subjectAbbr,
    required this.subjectFullName,
    required this.questionCount,
    required this.onPractice,
  });

  final String subjectAbbr;
  final String subjectFullName;
  final int questionCount;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.card : AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: isDark ? 0.45 : 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  size: 22,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Needs Most Attention',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subjectAbbr,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(
            subjectFullName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appTextSecondaryColor,
              height: 1.4,
            ),
          ),
          if (questionCount > 0) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPractice,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text('Practice $subjectAbbr'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── No data card ────────────────────────────────────────────────────────────

class _NoDataCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: PremiumCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        elevated: true,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md + 4),
              decoration: BoxDecoration(
                color: context.appPrimarySurfaceColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.insights_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No Performance Data Yet',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Complete at least one timed exam so the app can analyse your weak areas and give you personalised recommendations.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.appTextSecondaryColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recommendation tile ─────────────────────────────────────────────────────

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appCardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.appDividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.appTextPrimaryColor,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Context row ─────────────────────────────────────────────────────────────

class _ContextRow extends StatelessWidget {
  const _ContextRow({
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
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm + 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.appTextSecondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.appTextPrimaryColor,
          ),
        ),
      ],
    );
  }
}

// ─── Quick action tile ───────────────────────────────────────────────────────

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
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
            color: context.appCardColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: context.appDividerColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
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
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appTextSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
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
}
