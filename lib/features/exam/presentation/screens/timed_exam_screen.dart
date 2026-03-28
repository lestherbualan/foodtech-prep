import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../questions/presentation/widgets/answer_option_card.dart';
import '../providers/timed_exam_provider.dart';

class TimedExamScreen extends ConsumerStatefulWidget {
  const TimedExamScreen({super.key});

  @override
  ConsumerState<TimedExamScreen> createState() => _TimedExamScreenState();
}

class _TimedExamScreenState extends ConsumerState<TimedExamScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // Start the exam on first frame to ensure provider is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_started) {
        _started = true;
        ref.read(timedExamProvider.notifier).startExam();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final exam = ref.watch(timedExamProvider);

    // Auto-navigate to results when submitted.
    ref.listen<TimedExamState>(timedExamProvider, (prev, next) {
      if (prev?.isSubmitted != true &&
          next.isSubmitted &&
          next.result != null) {
        context.pushReplacement(RouteNames.examResult, extra: next.result);
      }
    });

    if (exam.totalQuestions == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Timed Exam')),
        body: const Center(child: Text('No questions loaded.')),
      );
    }

    final question = exam.currentQuestion;
    final selectedAnswer = exam.selectedAnswerFor(question.questionId);
    final choiceOrder = exam.currentChoiceOrder;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => _showExitDialog(context),
          ),
          title: _TimerChip(
            formattedTime: exam.formattedTime,
            remainingSeconds: exam.remainingSeconds,
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: LinearProgressIndicator(
              value: (exam.currentIndex + 1) / exam.totalQuestions,
              backgroundColor: AppColors.divider,
              color: AppColors.secondary,
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
                    // Question counter + subject
                    _ExamQuestionHeader(
                      questionNumber: exam.currentIndex + 1,
                      totalQuestions: exam.totalQuestions,
                      subjectName: question.subjectName,
                    ),
                    const SizedBox(height: AppSpacing.md + 4),

                    // Question text
                    Text(
                      question.questionText,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Choices — exam mode: only idle/selected states
                    ...choiceOrder.map(
                      (letter) => AnswerOptionCard(
                        letter: letter,
                        text: question.choices[letter] ?? '',
                        optionState: selectedAnswer == letter
                            ? AnswerOptionState.selected
                            : AnswerOptionState.idle,
                        onTap: () => ref
                            .read(timedExamProvider.notifier)
                            .selectAnswer(question.questionId, letter),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom bar
            _ExamBottomBar(
              exam: exam,
              onPrevious: exam.isFirst
                  ? null
                  : () => ref.read(timedExamProvider.notifier).goToPrevious(),
              onNext: exam.isLast
                  ? null
                  : () => ref.read(timedExamProvider.notifier).goToNext(),
              onSubmit: () => _showSubmitDialog(context, exam),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubmitDialog(BuildContext context, TimedExamState exam) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Exam?'),
        content: Text(
          exam.unansweredCount > 0
              ? 'You have ${exam.unansweredCount} unanswered '
                    '${exam.unansweredCount == 1 ? "question" : "questions"}. '
                    'Are you sure you want to submit?'
              : 'You have answered all questions. Submit your exam?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(timedExamProvider.notifier).submitExam();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Exam?'),
        content: const Text('Your progress will be lost if you leave now.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(RouteNames.home);
            },
            child: Text('Leave', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Timer chip
// ===========================================================================

class _TimerChip extends StatelessWidget {
  const _TimerChip({
    required this.formattedTime,
    required this.remainingSeconds,
  });
  final String formattedTime;
  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    final isLow = remainingSeconds <= 60;
    final color = isLow ? AppColors.error : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isLow
            ? AppColors.error.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isLow
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Question header (exam-specific, simpler than practice)
// ===========================================================================

class _ExamQuestionHeader extends StatelessWidget {
  const _ExamQuestionHeader({
    required this.questionNumber,
    required this.totalQuestions,
    required this.subjectName,
  });

  final int questionNumber;
  final int totalQuestions;
  final String subjectName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.secondary,
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
        Expanded(
          child: Text(
            subjectName,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Bottom bar
// ===========================================================================

class _ExamBottomBar extends StatelessWidget {
  const _ExamBottomBar({
    required this.exam,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  final TimedExamState exam;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onSubmit;

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
            // Prev
            _NavButton(
              icon: Icons.chevron_left_rounded,
              label: 'Prev',
              onPressed: onPrevious,
            ),
            const SizedBox(width: AppSpacing.sm),

            // Progress / submit
            Expanded(
              child: exam.isLast
                  ? FilledButton(
                      onPressed: onSubmit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                      ),
                      child: const Text('Submit Exam'),
                    )
                  : _ProgressInfo(
                      answered: exam.answeredCount,
                      total: exam.totalQuestions,
                    ),
            ),

            const SizedBox(width: AppSpacing.sm),
            // Next
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
}

class _ProgressInfo extends StatelessWidget {
  const _ProgressInfo({required this.answered, required this.total});
  final int answered;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Text(
        '$answered of $total answered',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
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
