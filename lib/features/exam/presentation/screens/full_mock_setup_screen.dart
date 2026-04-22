import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/secondary_screen_header.dart';
import '../../../questions/domain/question.dart';
import '../../../questions/presentation/providers/question_providers.dart';
import '../../domain/board_exam_blueprint.dart';
import '../../domain/exam_models.dart';
import '../../domain/full_mock_generator.dart';

/// Setup screen for the Full Mock Exam mode.
///
/// This mode produces a single 100-item exam covering all four major
/// subjects (PCBMP, FLR, FPPE, QSSEF). The cross-subject allocation
/// is APP-CONFIGURED (not official PRC weighting). The within-subject
/// subtopic distribution is TOS-informed.
class FullMockSetupScreen extends ConsumerWidget {
  const FullMockSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: questionsAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading questions…'),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md + 4),
                  decoration: const BoxDecoration(
                    color: AppColors.errorLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 40,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Failed to load questions.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Please check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(questionsProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (allQuestions) {
          if (allQuestions.isEmpty) {
            return const Center(child: Text('No questions available.'));
          }

          // Count available questions per subject.
          final Map<String, int> subjectCounts = {};
          for (final q in allQuestions) {
            subjectCounts[q.subjectId] = (subjectCounts[q.subjectId] ?? 0) + 1;
          }

          final totalAvailable = allQuestions.length;
          final hasQuestions = totalAvailable > 0;

          return Column(
            children: [
              // ── Header ──
              const SecondaryScreenHeader(
                title: 'Full Mock Exam',
                subtitle:
                    'Simulate a full board exam across all major subjects.',
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Hero card ──
                      PremiumCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.xl,
                        ),
                        elevated: true,
                        gradient: AppColors.heroGradient,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md + 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.assignment_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const Text(
                              'Full Mock Exam',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              '100 items across all four subjects.'
                              ' Randomized, broad coverage, full review'
                              ' simulation.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.85),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Exam details card ──
                      PremiumCard(
                        padding: const EdgeInsets.all(AppSpacing.md + 4),
                        child: Column(
                          children: [
                            _ExamDetailRow(
                              icon: Icons.quiz_rounded,
                              label: 'Questions',
                              value: '${FullMockConfig.totalQuestions} items',
                              color: AppColors.primary,
                            ),
                            _divider(),
                            _ExamDetailRow(
                              icon: Icons.schedule_rounded,
                              label: 'Duration',
                              value:
                                  '${FullMockConfig.durationMinutes} minutes',
                              color: AppColors.secondary,
                            ),
                            _divider(),
                            _ExamDetailRow(
                              icon: Icons.auto_awesome_rounded,
                              label: 'Distribution',
                              value: 'TOS-informed',
                              color: AppColors.accent,
                            ),
                            _divider(),
                            _ExamDetailRow(
                              icon: Icons.shuffle_rounded,
                              label: 'Coverage',
                              value: 'All 4 subjects',
                              color: const Color(0xFF0D9488),
                            ),
                            _divider(),
                            _ExamDetailRow(
                              icon: Icons.visibility_off_rounded,
                              label: 'Answers',
                              value: 'Shown after submit',
                              color: AppColors.warning,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Subject allocation section ──
                      const _SectionLabel(
                        title: 'Subject Allocation',
                        subtitle:
                            'App-configured distribution across the four'
                            ' major subjects. Within each subject, questions'
                            ' follow TOS subtopic distribution.',
                      ),
                      const SizedBox(height: AppSpacing.md - 2),

                      ...FullMockConfig.subjectOrder.map((subjectId) {
                        final bp = BoardExamBlueprint.forSubject(subjectId);
                        final allocation =
                            FullMockConfig.subjectAllocation[subjectId] ?? 0;
                        final available = subjectCounts[subjectId] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.sm + 2,
                          ),
                          child: _SubjectAllocationCard(
                            blueprint: bp,
                            subjectId: subjectId,
                            allocation: allocation,
                            available: available,
                          ),
                        );
                      }),

                      const SizedBox(height: AppSpacing.md),

                      // ── Total available hint ──
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color:
                                totalAvailable >= FullMockConfig.totalQuestions
                                ? AppColors.textHint
                                : AppColors.warning,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '$totalAvailable total questions available'
                              ' (${FullMockConfig.totalQuestions} target)',
                              style: TextStyle(
                                fontSize: 12.5,
                                color:
                                    totalAvailable >=
                                        FullMockConfig.totalQuestions
                                    ? AppColors.textHint
                                    : AppColors.warning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Simulation notice ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md + 2),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF0D9488,
                          ).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                          border: Border.all(
                            color: const Color(
                              0xFF0D9488,
                            ).withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF0D9488,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: Color(0xFF0D9488),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm + 2),
                            Expanded(
                              child: Text(
                                'This is a full mock simulation. The'
                                ' cross-subject allocation is app-configured'
                                ' for balanced coverage. Within each subject,'
                                ' questions follow TOS subtopic distribution.'
                                ' Answers are revealed after submission.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.5,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),

              // ── Bottom CTA ──
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: FilledButton.icon(
                    onPressed: hasQuestions
                        ? () => _startExam(context, allQuestions)
                        : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      hasQuestions
                          ? 'Start Full Mock Exam'
                          : 'No Questions Available',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: const Color(0xFF0D9488),
                      disabledBackgroundColor: AppColors.disabled,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _startExam(BuildContext context, List<Question> allQuestions) {
    final generator = FullMockGenerator();
    final result = generator.generate(pool: allQuestions);

    if (result.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough questions for a full mock exam.'),
        ),
      );
      return;
    }

    for (final w in result.warnings) {
      debugPrint('[FullMockSetup] Warning: $w');
    }

    context.push(
      RouteNames.timedExam,
      extra: TimedExamArgs(
        questions: result.questions,
        durationMinutes: FullMockConfig.durationMinutes,
        mode: 'full_mock_exam',
      ),
    );
  }

  static Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
      child: Divider(
        height: 1,
        color: AppColors.divider.withValues(alpha: 0.5),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Subject allocation card
// ═══════════════════════════════════════════════════════════════════════════════

class _SubjectAllocationCard extends StatelessWidget {
  const _SubjectAllocationCard({
    required this.blueprint,
    required this.subjectId,
    required this.allocation,
    required this.available,
  });

  final SubjectBlueprint? blueprint;
  final String subjectId;
  final int allocation;
  final int available;

  @override
  Widget build(BuildContext context) {
    final isSufficient = available >= allocation;
    final icon = blueprint?.icon ?? Icons.help_outline_rounded;
    final name = blueprint?.tosFullName ?? subjectId;

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Subject icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 24, color: const Color(0xFF0D9488)),
          ),
          const SizedBox(width: AppSpacing.md),
          // Labels
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$available available',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isSufficient
                        ? AppColors.textHint
                        : AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Allocation badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isSufficient
                  ? AppColors.successLight
                  : AppColors.warningLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              '$allocation items',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isSufficient ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Section label
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm + 3),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Exam detail row
// ═══════════════════════════════════════════════════════════════════════════════

class _ExamDetailRow extends StatelessWidget {
  const _ExamDetailRow({
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
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
