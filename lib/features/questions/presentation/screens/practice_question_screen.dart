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

    // Guard: empty session (should never happen with proper routing)
    if (session.totalQuestions == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Practice')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'No questions available.\nGo back and try again.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final notifier = ref.read(practiceSessionProvider.notifier);
    final question = session.currentQuestion;
    final qState = session.currentQuestionState;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Practice Mode',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: (session.currentIndex + 1) / session.totalQuestions,
            backgroundColor: AppColors.divider,
            color: AppColors.primary,
            minHeight: 3,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Question header card ──
                  _QuestionHeader(
                    questionNumber: session.currentIndex + 1,
                    totalQuestions: session.totalQuestions,
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

                  // ── Answer choices ──
                  ...List.generate(question.options.length, (i) {
                    const labels = ['A', 'B', 'C', 'D'];
                    final originalIndex = session.currentChoiceOrder[i];
                    return AnswerOptionCard(
                      letter: labels[i],
                      text: question.options[originalIndex].text,
                      optionState: _resolveOptionState(
                        letter: labels[i],
                        selectedAnswer: qState.selectedAnswer,
                        isChecked: qState.isChecked,
                        correctAnswer: session.currentDisplayCorrectAnswer,
                      ),
                      onTap: qState.isChecked
                          ? null
                          : () => notifier.selectAnswer(labels[i]),
                    );
                  }),

                  // ── Result feedback + explanation ──
                  if (qState.isChecked) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _ResultBanner(isCorrect: qState.isCorrect),
                    const SizedBox(height: AppSpacing.md),
                    _ExplanationCard(question: question),
                  ],
                ],
              ),
            ),
          ),

          // ── Bottom action bar ──
          _BottomActionBar(
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
      if (selectedAnswer == letter) return AnswerOptionState.selected;
      return AnswerOptionState.idle;
    }
    if (letter == correctAnswer) return AnswerOptionState.correct;
    if (letter == selectedAnswer) return AnswerOptionState.incorrect;
    return AnswerOptionState.disabled;
  }
}

// ===========================================================================
// Question Header
// ===========================================================================

class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: question counter + difficulty
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
          // Subject
          Text(
            subjectName,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          // Subtopic
          Text(
            subtopicName,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
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
    final (Color bg, Color fg) = switch (difficulty) {
      'Easy' => (const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
      'Hard' => (const Color(0xFFFFEBEE), const Color(0xFFC62828)),
      _ => (const Color(0xFFFFF3E0), const Color(0xFFE65100)), // Medium
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
// Result Banner
// ===========================================================================

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.isCorrect});
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    final icon = isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final title = isCorrect ? 'Correct!' : 'Incorrect';
    final subtitle = isCorrect
        ? 'Great job — you got it right.'
        : 'Review the explanation below.';
    final color = isCorrect ? AppColors.success : AppColors.error;
    final bgColor = isCorrect
        ? const Color(0xFFF0F9F1)
        : const Color(0xFFFDF0F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color.withValues(alpha: 0.8),
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

// ===========================================================================
// Explanation Card
// ===========================================================================

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({required this.question});
  final Question question;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              Icon(
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
          // Explanation body
          Text(
            question.explanation,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: AppColors.textPrimary,
            ),
          ),

          // Study note (if present)
          if (question.studyNote != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(height: 1, color: AppColors.divider),
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
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        question.studyNote!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.55,
                          color: AppColors.textSecondary,
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
// Bottom Action Bar
// ===========================================================================

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
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
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
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
            // Previous button
            _NavButton(
              icon: Icons.chevron_left_rounded,
              label: 'Prev',
              onPressed: onPrevious,
            ),

            const SizedBox(width: AppSpacing.sm),

            // Center action
            Expanded(child: _buildCenterAction(context)),

            const SizedBox(width: AppSpacing.sm),

            // Next button
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

  Widget _buildCenterAction(BuildContext context) {
    if (!qState.isChecked) {
      return FilledButton(
        onPressed: qState.selectedAnswer != null ? onCheck : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        child: const Text('Check Answer'),
      );
    }

    // Already checked — show a subtle result chip
    final isCorrect = qState.isCorrect;
    return Container(
      height: 46,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFFF0F9F1) : const Color(0xFFFDF0F0),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 18,
            color: isCorrect ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 6),
          Text(
            isCorrect ? 'Correct' : 'Incorrect',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isCorrect ? AppColors.success : AppColors.error,
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
        ? AppColors.textSecondary
        : AppColors.disabled;
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
