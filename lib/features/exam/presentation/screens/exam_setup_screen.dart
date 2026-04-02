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
import '../../domain/exam_models.dart';
import '../../domain/exam_subject.dart';
import '../widgets/exam_subject_selection_card.dart';

class ExamSetupScreen extends ConsumerStatefulWidget {
  const ExamSetupScreen({super.key});

  @override
  ConsumerState<ExamSetupScreen> createState() => _ExamSetupScreenState();
}

class _ExamSetupScreenState extends ConsumerState<ExamSetupScreen> {
  /// Currently selected subject. Defaults to "All Subjects" (index 0).
  ExamSubject _selectedSubject = ExamSubject.options.first;

  /// Filters the question pool by the selected subject.
  List<Question> _filterQuestions(List<Question> allQuestions) {
    if (_selectedSubject.isAll) return allQuestions;
    return allQuestions
        .where((q) => q.subjectId == _selectedSubject.id)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
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

          final config = ExamConfig.defaultConfig;
          final filtered = _filterQuestions(allQuestions);
          final availableCount = filtered.length;
          final examCount = availableCount < config.questionCount
              ? availableCount
              : config.questionCount;
          final hasEnoughQuestions = availableCount > 0;

          return Column(
            children: [
              // ── Shared header ──
              const SecondaryScreenHeader(
                title: 'Timed Exam',
                subtitle: 'Choose your subject focus before starting the exam.',
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
                                Icons.timer_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const Text(
                              'Ready for Exam Mode?',
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
                              'Choose your subject focus before starting the exam.',
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
                              value: '$examCount items',
                              color: AppColors.primary,
                            ),
                            _divider(),
                            _ExamDetailRow(
                              icon: Icons.schedule_rounded,
                              label: 'Duration',
                              value: '${config.durationMinutes} minutes',
                              color: AppColors.secondary,
                            ),
                            _divider(),
                            _ExamDetailRow(
                              icon: Icons.visibility_off_rounded,
                              label: 'Answers',
                              value: 'Shown after submit',
                              color: AppColors.accent,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Subject focus section ──
                      _SectionLabel(
                        title: 'Subject Focus',
                        subtitle:
                            'Select all subjects for a mixed mock exam, or choose one subject for targeted timed practice.',
                      ),
                      const SizedBox(height: AppSpacing.md - 2),

                      ...ExamSubject.options.map(
                        (subject) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.sm + 2,
                          ),
                          child: ExamSubjectSelectionCard(
                            subject: subject,
                            isSelected: _selectedSubject.id == subject.id,
                            onTap: () =>
                                setState(() => _selectedSubject = subject),
                          ),
                        ),
                      ),

                      // ── Available questions hint ──
                      if (!_selectedSubject.isAll)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.xs,
                            bottom: AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color: hasEnoughQuestions
                                    ? AppColors.textHint
                                    : AppColors.warning,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$availableCount questions available in ${_selectedSubject.label}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: hasEnoughQuestions
                                      ? AppColors.textHint
                                      : AppColors.warning,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: AppSpacing.md),

                      // ── Instructions notice ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md + 2),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: AppColors.warning.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm + 2),
                            Expanded(
                              child: Text(
                                'You can navigate between questions and change your answers before submitting. Answers are revealed after submission.',
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
                    onPressed: hasEnoughQuestions
                        ? () {
                            final shuffled = List<Question>.from(filtered)
                              ..shuffle();
                            final selected = shuffled.take(examCount).toList();
                            context.push(
                              RouteNames.timedExam,
                              extra: TimedExamArgs(
                                questions: selected,
                                durationMinutes: config.durationMinutes,
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      hasEnoughQuestions
                          ? 'Start Exam'
                          : 'No Questions Available',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: AppColors.primary,
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

  Widget _divider() {
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
// Section label with subtitle
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
                color: AppColors.primary,
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
