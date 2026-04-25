import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../questions/domain/question.dart';
import '../../../questions/presentation/widgets/answer_option_card.dart';
import '../../domain/exam_models.dart';

/// Read-only post-exam review screen.
class ExamReviewScreen extends ConsumerStatefulWidget {
  const ExamReviewScreen({super.key, required this.result});

  final ExamResult result;

  @override
  ConsumerState<ExamReviewScreen> createState() => _ExamReviewScreenState();
}

class _ExamReviewScreenState extends ConsumerState<ExamReviewScreen> {
  int _currentIndex = 0;
  _ReviewFilter _filter = _ReviewFilter.all;

  ExamResult get result => widget.result;

  List<Question> get _filteredQuestions {
    return switch (_filter) {
      _ReviewFilter.all => result.questions,
      _ReviewFilter.correct => result.questions.where((q) {
        final sel = result.answers[q.questionId];
        final correct =
            result.displayCorrectAnswers[q.questionId] ?? q.correctAnswerLabel;
        return sel != null && sel == correct;
      }).toList(),
      _ReviewFilter.incorrect => result.questions.where((q) {
        final sel = result.answers[q.questionId];
        final correct =
            result.displayCorrectAnswers[q.questionId] ?? q.correctAnswerLabel;
        return sel != null && sel != correct;
      }).toList(),
      _ReviewFilter.unanswered =>
        result.questions
            .where((q) => result.answers[q.questionId] == null)
            .toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final questions = _filteredQuestions;

    // Clamp index if filter changes
    if (_currentIndex >= questions.length) {
      _currentIndex = questions.isEmpty ? 0 : questions.length - 1;
    }

    return Scaffold(
      backgroundColor: context.appSurfaceColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Review Exam',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        bottom: questions.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / questions.length,
                  backgroundColor: context.appDividerColor,
                  color: context.appPrimaryColor,
                  minHeight: 3,
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          // ── Filter chips ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: Row(
              children: _ReviewFilter.values.map((f) {
                final isActive = f == _filter;
                final count = switch (f) {
                  _ReviewFilter.all => result.totalQuestions,
                  _ReviewFilter.correct => result.correctCount,
                  _ReviewFilter.incorrect => result.incorrectCount,
                  _ReviewFilter.unanswered => result.unansweredCount,
                };
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    selected: isActive,
                    label: Text('${f.label} ($count)'),
                    onSelected: (_) => setState(() {
                      _filter = f;
                      _currentIndex = 0;
                    }),
                    selectedColor: context.appPrimaryColor.withValues(
                      alpha: 0.12,
                    ),
                    checkmarkColor: context.appPrimaryColor,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? context.appPrimaryColor
                          : context.appTextSecondaryColor,
                    ),
                    side: BorderSide(
                      color: isActive
                          ? context.appPrimaryColor
                          : context.appDividerColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Body ──
          Expanded(
            child: questions.isEmpty
                ? _EmptyFilterState(filter: _filter)
                : _ReviewBody(
                    question: questions[_currentIndex],
                    questionNumber: _currentIndex + 1,
                    totalFiltered: questions.length,
                    selectedAnswer:
                        result.answers[questions[_currentIndex].questionId],
                    choiceOrder:
                        result.choiceOrders[questions[_currentIndex]
                            .questionId] ??
                        [0, 1, 2, 3],
                    displayCorrectAnswer:
                        result.displayCorrectAnswers[questions[_currentIndex]
                            .questionId] ??
                        questions[_currentIndex].correctAnswerLabel,
                    showSource: ref
                        .watch(userPermissionsProvider)
                        .canViewQuestionSource,
                  ),
          ),

          // ── Bottom nav ──
          if (questions.isNotEmpty)
            _ReviewBottomBar(
              currentIndex: _currentIndex,
              total: questions.length,
              selectedAnswer:
                  result.answers[questions[_currentIndex].questionId],
              correctAnswer:
                  result.displayCorrectAnswers[questions[_currentIndex]
                      .questionId] ??
                  questions[_currentIndex].correctAnswerLabel,
              onPrevious: _currentIndex > 0
                  ? () => setState(() => _currentIndex--)
                  : null,
              onNext: _currentIndex < questions.length - 1
                  ? () => setState(() => _currentIndex++)
                  : null,
            ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Filter enum
// ===========================================================================

enum _ReviewFilter {
  all('All'),
  correct('Correct'),
  incorrect('Incorrect'),
  unanswered('Unanswered');

  const _ReviewFilter(this.label);
  final String label;
}

// ===========================================================================
// Empty filter state
// ===========================================================================

class _EmptyFilterState extends StatelessWidget {
  const _EmptyFilterState({required this.filter});
  final _ReviewFilter filter;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String title, String subtitle) = switch (filter) {
      _ReviewFilter.correct => (
        Icons.sentiment_dissatisfied_rounded,
        'No Correct Answers',
        'Keep practicing — you\'ll get there!',
      ),
      _ReviewFilter.incorrect => (
        Icons.check_circle_outline_rounded,
        'No Incorrect Answers',
        'Great job — you got every answered question right!',
      ),
      _ReviewFilter.unanswered => (
        Icons.task_alt_rounded,
        'All Questions Answered',
        'You completed every question in this exam.',
      ),
      _ReviewFilter.all => (
        Icons.quiz_outlined,
        'No Questions',
        'This exam has no questions to review.',
      ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.success),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.appTextSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Review body — question + choices + explanation
// ===========================================================================

class _ReviewBody extends StatelessWidget {
  const _ReviewBody({
    required this.question,
    required this.questionNumber,
    required this.totalFiltered,
    required this.selectedAnswer,
    required this.choiceOrder,
    required this.displayCorrectAnswer,
    this.showSource = false,
  });

  final Question question;
  final int questionNumber;
  final int totalFiltered;
  final String? selectedAnswer;
  final List<int> choiceOrder;
  final String displayCorrectAnswer;
  final bool showSource;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          _ReviewQuestionHeader(
            questionNumber: questionNumber,
            totalQuestions: totalFiltered,
            subjectName: question.subjectName,
            subtopicName: question.subtopicName,
            difficulty: question.difficulty,
          ),
          const SizedBox(height: AppSpacing.md + 4),

          // ── Question text ──
          Text(
            question.questionText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Choices (read-only) ──
          ...List.generate(question.options.length, (i) {
            const labels = ['A', 'B', 'C', 'D'];
            final originalIndex = choiceOrder[i];
            return AnswerOptionCard(
              letter: labels[i],
              text: question.options[originalIndex].text,
              optionState: _resolveState(labels[i]),
              onTap: null, // read-only
            );
          }),

          // ── Explanation ──
          const SizedBox(height: AppSpacing.sm),
          _ReviewExplanation(question: question, showSource: showSource),
        ],
      ),
    );
  }

  AnswerOptionState _resolveState(String displayLabel) {
    final isCorrect = displayLabel == displayCorrectAnswer;
    final isSelected = displayLabel == selectedAnswer;

    if (isCorrect) return AnswerOptionState.correct;
    if (isSelected) return AnswerOptionState.incorrect;
    return AnswerOptionState.disabled;
  }
}

// ===========================================================================
// Question header
// ===========================================================================

class _ReviewQuestionHeader extends StatelessWidget {
  const _ReviewQuestionHeader({
    required this.questionNumber,
    required this.totalQuestions,
    required this.subjectName,
    required this.subtopicName,
    required this.difficulty,
  });

  final int questionNumber;
  final int totalQuestions;
  final String subjectName;
  final String subtopicName;
  final String difficulty;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appCardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.appDividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'Q$questionNumber of $totalQuestions',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _DifficultyBadge(difficulty: difficulty),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subjectName,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: context.appTextPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtopicName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appTextSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});
  final String difficulty;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final (Color bg, Color fg) = switch (difficulty) {
      'Easy' =>
        isDark
            ? (context.appSuccessLightColor, AppColors.success)
            : (const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
      'Hard' =>
        isDark
            ? (context.appErrorLightColor, AppColors.error)
            : (const Color(0xFFFFEBEE), const Color(0xFFC62828)),
      _ =>
        isDark
            ? (context.appWarningLightColor, AppColors.warning)
            : (const Color(0xFFFFF3E0), const Color(0xFFE65100)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        difficulty,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

// ===========================================================================
// Explanation card
// ===========================================================================

class _ReviewExplanation extends StatelessWidget {
  const _ReviewExplanation({required this.question, this.showSource = false});
  final Question question;
  final bool showSource;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appCardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.appDividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_stories_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Explanation',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(
            question.explanation,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: context.appTextPrimaryColor,
            ),
          ),
          if (question.studyNote != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(height: 1, color: context.appDividerColor),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Study Tip',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: context.appTextSecondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        question.studyNote!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.55,
                          color: context.appTextSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (showSource &&
              (question.sourceReference != null ||
                  question.sourceFile != null)) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(height: 1, color: context.appDividerColor),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.source_rounded,
                  size: 16,
                  color: context.appTextHintColor,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Source',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: context.appTextSecondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        [
                          if (question.sourceReference != null)
                            question.sourceReference!,
                          if (question.sourceFile != null) question.sourceFile!,
                        ].join(' - '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.45,
                          color: context.appTextHintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ===========================================================================
// Bottom bar
// ===========================================================================

class _ReviewBottomBar extends StatelessWidget {
  const _ReviewBottomBar({
    required this.currentIndex,
    required this.total,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentIndex;
  final int total;
  final String? selectedAnswer;
  final String correctAnswer;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.appCardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _NavButton(
              icon: Icons.chevron_left_rounded,
              label: 'Prev',
              onPressed: onPrevious,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _buildStatusChip(context)),
            const SizedBox(width: AppSpacing.sm),
            _NavButton(
              icon: Icons.chevron_right_rounded,
              label: 'Next',
              onPressed: onNext,
              iconFirst: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final String label;
    final Color color;
    final IconData icon;

    if (selectedAnswer == null) {
      label = 'Unanswered';
      color = AppColors.warning;
      icon = Icons.remove_circle_outline_rounded;
    } else if (selectedAnswer == correctAnswer) {
      label = 'Correct';
      color = AppColors.success;
      icon = Icons.check_circle_rounded;
    } else {
      label = 'Incorrect — You picked $selectedAnswer';
      color = AppColors.error;
      icon = Icons.cancel_rounded;
    }

    return Container(
      height: 42,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconFirst = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool iconFirst;

  @override
  Widget build(BuildContext context) {
    final color = onPressed != null
        ? context.appTextSecondaryColor
        : context.appDisabledColor;
    final iconWidget = Icon(icon, size: 22, color: color);
    final labelWidget = Text(
      label,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color),
    );

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: iconFirst
              ? [iconWidget, const SizedBox(width: 2), labelWidget]
              : [labelWidget, const SizedBox(width: 2), iconWidget],
        ),
      ),
    );
  }
}
