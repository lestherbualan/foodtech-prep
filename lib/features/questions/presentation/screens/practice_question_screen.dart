import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/question.dart';
import '../providers/practice_session_provider.dart';
import '../widgets/answer_option_card.dart';

class PracticeQuestionScreen extends ConsumerWidget {
  const PracticeQuestionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(practiceSessionProvider);
    final notifier = ref.read(practiceSessionProvider.notifier);
    final question = session.currentQuestion;
    final qState = session.currentQuestionState;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Question ${session.currentIndex + 1} of ${session.totalQuestions}',
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (session.currentIndex + 1) / session.totalQuestions,
            backgroundColor: AppColors.divider,
            color: AppColors.primary,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject / subtopic header
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _MetaChip(label: question.subjectName),
                      _MetaChip(label: question.difficulty),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    question.subtopicName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Question text
                  Text(
                    question.questionText,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Choices
                  ...['A', 'B', 'C', 'D'].map(
                    (letter) => AnswerOptionCard(
                      letter: letter,
                      text: question.choices[letter] ?? '',
                      optionState: _resolveOptionState(
                        letter: letter,
                        selectedAnswer: qState.selectedAnswer,
                        isChecked: qState.isChecked,
                        correctAnswer: question.correctAnswer,
                      ),
                      onTap: qState.isChecked
                          ? null
                          : () => notifier.selectAnswer(letter),
                    ),
                  ),

                  // Explanation (shown after check)
                  if (qState.isChecked) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ExplanationSection(question: question),
                  ],
                ],
              ),
            ),
          ),

          // Bottom action bar
          _BottomBar(
            session: session,
            qState: qState,
            onCheck: () => notifier.checkAnswer(),
            onPrevious: session.isFirst ? null : () => notifier.goToPrevious(),
            onNext: session.isLast ? null : () => notifier.goToNext(),
          ),
        ],
      ),
    );
  }

  static AnswerOptionState _resolveOptionState({
    required String letter,
    required String? selectedAnswer,
    required bool isChecked,
    required String correctAnswer,
  }) {
    if (!isChecked) {
      // Before checking
      if (selectedAnswer == letter) return AnswerOptionState.selected;
      return AnswerOptionState.idle;
    }

    // After checking
    if (letter == correctAnswer) return AnswerOptionState.correct;
    if (letter == selectedAnswer) return AnswerOptionState.incorrect;
    return AnswerOptionState.disabled;
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ExplanationSection extends StatelessWidget {
  const _ExplanationSection({required this.question});
  final Question question;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.06),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Explanation',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            question.explanation,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          if (question.studyNote != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Study Note',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              question.studyNote!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.session,
    required this.qState,
    required this.onCheck,
    required this.onPrevious,
    required this.onNext,
  });

  final PracticeSessionState session;
  final PracticeQuestionState qState;
  final VoidCallback onCheck;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Previous
            IconButton(
              onPressed: onPrevious,
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
              tooltip: 'Previous',
            ),

            const Spacer(),

            // Center action — Check or status
            if (!qState.isChecked)
              FilledButton(
                onPressed: qState.selectedAnswer != null ? onCheck : null,
                child: const Text('Check Answer'),
              )
            else
              Chip(
                avatar: Icon(
                  qState.selectedAnswer == session.currentQuestion.correctAnswer
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 18,
                  color:
                      qState.selectedAnswer ==
                          session.currentQuestion.correctAnswer
                      ? AppColors.success
                      : AppColors.error,
                ),
                label: Text(
                  qState.selectedAnswer == session.currentQuestion.correctAnswer
                      ? 'Correct!'
                      : 'Incorrect',
                ),
              ),

            const Spacer(),

            // Next
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
              tooltip: 'Next',
            ),
          ],
        ),
      ),
    );
  }
}
