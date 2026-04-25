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
import '../../domain/board_exam_generator.dart';
import '../../domain/exam_models.dart';

/// Setup screen for the Subject TOS Mock mode.
///
/// The user selects one of the four major subjects and starts a 100-item
/// TOS-based simulation for that subject. Each subject is a separate
/// 100-item exam in the actual board exam (TOS-grounded).
class BoardExamSetupScreen extends ConsumerStatefulWidget {
  const BoardExamSetupScreen({super.key, this.initialSubjectId});

  final String? initialSubjectId;

  @override
  ConsumerState<BoardExamSetupScreen> createState() =>
      _BoardExamSetupScreenState();
}

class _BoardExamSetupScreenState extends ConsumerState<BoardExamSetupScreen> {
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.initialSubjectId;
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

          // Count available questions per subject.
          final Map<String, int> subjectCounts = {};
          for (final q in allQuestions) {
            subjectCounts[q.subjectId] = (subjectCounts[q.subjectId] ?? 0) + 1;
          }

          final selectedBp = _selectedSubjectId != null
              ? BoardExamBlueprint.forSubject(_selectedSubjectId!)
              : null;
          final availableForSelected = subjectCounts[_selectedSubjectId] ?? 0;
          final hasEnough =
              _selectedSubjectId != null && availableForSelected > 0;

          return Column(
            children: [
              // ── Shared header ──
              const SecondaryScreenHeader(
                title: 'Subject TOS Mock',
                subtitle: 'TOS-based focused practice for one major subject.',
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
                                Icons.school_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const Text(
                              'Subject TOS Mock',
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
                              'Practice one subject at a time using its'
                              ' official TOS subtopic blueprint.',
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
                              value: '${BoardExamConfig.totalQuestions} items',
                              color: AppColors.primary,
                            ),
                            _divider(),
                            _ExamDetailRow(
                              icon: Icons.schedule_rounded,
                              label: 'Duration',
                              value:
                                  '${BoardExamConfig.durationMinutes} minutes',
                              color: AppColors.secondary,
                            ),
                            _divider(),
                            _ExamDetailRow(
                              icon: Icons.auto_awesome_rounded,
                              label: 'Distribution',
                              value: 'TOS-based',
                              color: AppColors.accent,
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

                      // ── Subject selection ──
                      const _SectionLabel(
                        title: 'Select Subject',
                        subtitle:
                            'Each subject follows its official TOS subtopic'
                            ' blueprint. Choose which one to practice.',
                      ),
                      const SizedBox(height: AppSpacing.md - 2),

                      ...BoardExamBlueprint.allSubjects.map((bp) {
                        final available = subjectCounts[bp.subjectId] ?? 0;
                        final isSelected = _selectedSubjectId == bp.subjectId;
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.sm + 2,
                          ),
                          child: _SubjectSelectionCard(
                            blueprint: bp,
                            available: available,
                            isSelected: isSelected,
                            onTap: () => setState(() {
                              _selectedSubjectId = bp.subjectId;
                            }),
                          ),
                        );
                      }),

                      // ── TOS subtopic breakdown for selected subject ──
                      if (selectedBp != null) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _SectionLabel(
                          title: 'TOS Subtopic Breakdown',
                          subtitle:
                              'Item allocation from the official Table of '
                              'Specification for ${selectedBp.abbreviation}.',
                        ),
                        const SizedBox(height: AppSpacing.md - 2),
                        ...selectedBp.subtopics.map((tos) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm + 2,
                            ),
                            child: _TosSubtopicRow(
                              subtopic: tos,
                              totalItems: selectedBp.totalTargetItems,
                            ),
                          );
                        }),
                      ],

                      // ── Coverage info ──
                      if (_selectedSubjectId != null)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.md,
                            bottom: AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color:
                                    availableForSelected >=
                                        BoardExamConfig.totalQuestions
                                    ? AppColors.textHint
                                    : AppColors.warning,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '$availableForSelected questions available'
                                  ' for ${selectedBp?.abbreviation ?? _selectedSubjectId}'
                                  ' (${BoardExamConfig.totalQuestions} target)',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color:
                                        availableForSelected >=
                                            BoardExamConfig.totalQuestions
                                        ? AppColors.textHint
                                        : AppColors.warning,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                                'This mode provides TOS-based focused'
                                ' practice for one subject. Questions are'
                                ' distributed across subtopics following'
                                ' the official TOS blueprint.'
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
                    onPressed: hasEnough
                        ? () => _startExam(allQuestions)
                        : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      _selectedSubjectId == null
                          ? 'Select a Subject'
                          : hasEnough
                          ? 'Start TOS Mock'
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

  void _startExam(List<Question> allQuestions) {
    if (_selectedSubjectId == null) return;

    final generator = BoardExamGenerator();
    final result = generator.generate(
      subjectId: _selectedSubjectId!,
      pool: allQuestions,
    );

    if (result.questions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough questions for this subject.'),
          ),
        );
      }
      return;
    }

    // Log coverage warnings for diagnostics.
    for (final w in result.warnings) {
      debugPrint('[SubjectTosMock] Warning: $w');
    }

    context.push(
      RouteNames.timedExam,
      extra: TimedExamArgs(
        questions: result.questions,
        durationMinutes: BoardExamConfig.durationMinutes,
        mode: 'subject_tos_mock',
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
// Subject selection card
// ═══════════════════════════════════════════════════════════════════════════════

class _SubjectSelectionCard extends StatelessWidget {
  const _SubjectSelectionCard({
    required this.blueprint,
    required this.available,
    required this.isSelected,
    required this.onTap,
  });

  final SubjectBlueprint blueprint;
  final int available;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSufficient = available >= BoardExamConfig.totalQuestions;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
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
            // Subject icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                blueprint.icon,
                size: 24,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blueprint.tosFullName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$available available'
                    ' · ${blueprint.subtopics.length} subtopics',
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
            // Selection indicator
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TOS subtopic row
// ═══════════════════════════════════════════════════════════════════════════════

class _TosSubtopicRow extends StatelessWidget {
  const _TosSubtopicRow({required this.subtopic, required this.totalItems});

  final TosSubtopic subtopic;
  final int totalItems;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 4,
      ),
      child: Row(
        children: [
          // Code badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              subtopic.code,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          // Subtopic name
          Expanded(
            child: Text(
              subtopic.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Weight badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              '${subtopic.targetItems} items (${subtopic.weightPercent}%)',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
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
