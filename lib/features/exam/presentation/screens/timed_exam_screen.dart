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
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top exam bar ──
              _ExamTopBar(exam: exam, onClose: () => _showExitDialog(context)),

              // ── Question content ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject badge
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
                          height: 1.65,
                          fontWeight: FontWeight.w500,
                          fontSize: 17,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg + 4),

                      // Answer options
                      ...List.generate(question.options.length, (i) {
                        const labels = ['A', 'B', 'C', 'D'];
                        final originalIndex = choiceOrder[i];
                        return AnswerOptionCard(
                          letter: labels[i],
                          text: question.options[originalIndex].text,
                          optionState: selectedAnswer == labels[i]
                              ? AnswerOptionState.selected
                              : AnswerOptionState.idle,
                          onTap: () => ref
                              .read(timedExamProvider.notifier)
                              .selectAnswer(question.questionId, labels[i]),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // ── Bottom navigation bar ──
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

// ═══════════════════════════════════════════════════════════════════════════════
// Top exam bar
// ═══════════════════════════════════════════════════════════════════════════════

class _ExamTopBar extends StatelessWidget {
  const _ExamTopBar({required this.exam, required this.onClose});
  final TimedExamState exam;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Close button
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: onClose,
                  constraints: const BoxConstraints(
                    minWidth: 38,
                    minHeight: 38,
                  ),
                  padding: EdgeInsets.zero,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              // Timer — the visual anchor
              _TimerChip(
                formattedTime: exam.formattedTime,
                remainingSeconds: exam.remainingSeconds,
              ),
              const Spacer(),
              // Question counter pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  '${exam.currentIndex + 1}/${exam.totalQuestions}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (exam.currentIndex + 1) / exam.totalQuestions,
              backgroundColor: AppColors.divider,
              color: AppColors.primary,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Timer chip
// ═══════════════════════════════════════════════════════════════════════════════

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
    final color = isLow ? AppColors.error : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: isLow ? AppColors.errorLight : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
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
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Question header
// ═══════════════════════════════════════════════════════════════════════════════

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            'Q$questionNumber of $totalQuestions',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm + 2),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              subjectName,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Bottom bar
// ═══════════════════════════════════════════════════════════════════════════════

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
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          _NavButton(
            icon: Icons.chevron_left_rounded,
            label: 'Prev',
            onPressed: onPrevious,
          ),
          const SizedBox(width: AppSpacing.sm),

          Expanded(
            child: exam.isLast
                ? FilledButton(
                    onPressed: onSubmit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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
          _NavButton(
            icon: Icons.chevron_right_rounded,
            label: 'Next',
            onPressed: onNext,
            iconFirst: false,
          ),
        ],
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
      height: 50,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Text(
        '$answered of $total answered',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
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
        ? AppColors.textPrimary
        : AppColors.disabled;
    final iconWidget = Icon(icon, size: 22, color: color);
    final labelWidget = Text(
      label,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
    );

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: onPressed != null
              ? AppColors.surface
              : AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
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
