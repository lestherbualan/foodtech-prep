import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/activity_log.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../questions/presentation/providers/practice_session_provider.dart';
import '../../domain/exam_models.dart';
import '../../domain/result_feedback.dart';
import '../../domain/saved_exam_attempt.dart';
import '../providers/exam_attempt_providers.dart';
import '../widgets/performance_insight_card.dart';
import '../widgets/retry_actions_section.dart';
import '../widgets/study_guidance_card.dart';
import '../widgets/subject_performance_card.dart';

class ExamResultScreen extends ConsumerStatefulWidget {
  const ExamResultScreen({super.key, required this.result});

  final ExamResult result;

  @override
  ConsumerState<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends ConsumerState<ExamResultScreen> {
  @override
  void initState() {
    super.initState();
    _saveAttempt();
  }

  Future<void> _saveAttempt() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final attempt = SavedExamAttempt.fromResult(
      result: widget.result,
      userId: user.uid,
      timeLimitSeconds:
          widget.result.timeLimitSeconds ?? widget.result.durationSeconds,
    );

    try {
      final repo = ref.read(examAttemptRepositoryProvider);
      await repo.saveAttempt(attempt);
      ref.invalidate(recentAttemptsProvider);

      // Update user stats in Firestore.
      final breakdown = widget.result.performanceBreakdown;
      ref
          .read(userRepositoryProvider)
          .updateStatsAfterExam(
            uid: user.uid,
            scorePercent: widget.result.scorePercent,
            strongestSubject: breakdown.strongest?.subjectName,
            weakestSubject: breakdown.weakest?.subjectName,
          );

      // Log exam submission activity.
      ref
          .read(activityLoggerProvider)
          .log(
            uid: user.uid,
            type: ActivityType.submitTimedExam,
            metadata: {
              'score': widget.result.scorePercent,
              'correct': widget.result.correctCount,
              'total': widget.result.totalQuestions,
            },
          );
    } catch (e) {
      debugPrint('[ExamResultScreen] Failed to save attempt: $e');
      // Non-blocking — result screen still works
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final passed = result.scorePercent >= 50;
    final breakdown = result.performanceBreakdown;
    final feedback = ResultFeedback.from(result);
    final guidance = buildStudyGuidance(result);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(RouteNames.home);
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(6),
            child: Material(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.go(RouteNames.home),
                child: const Icon(Icons.close_rounded, size: 20),
              ),
            ),
          ),
          title: Text(
            'Exam Results',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // ── Score hero card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xl + 8,
                  horizontal: AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  gradient: passed
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                        )
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                        ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: (passed ? AppColors.primary : AppColors.error)
                          .withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Score circle
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 3.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${result.scorePercent.round()}%',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md + 4),
                    Text(
                      feedback.headline,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Text(
                        feedback.subtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (result.wasAutoSubmitted) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm + 2,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull,
                          ),
                        ),
                        child: Text(
                          'Time expired — auto-submitted',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Summary breakdown card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg + 4),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
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
                          'Summary',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md + 4),
                    _StatRow(
                      label: 'Total Questions',
                      value: '${result.totalQuestions}',
                      color: AppColors.textPrimary,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Divider(height: 1, color: AppColors.divider),
                    ),
                    _StatRow(
                      label: 'Correct',
                      value: '${result.correctCount}',
                      color: AppColors.success,
                    ),
                    const SizedBox(height: AppSpacing.sm + 2),
                    _StatRow(
                      label: 'Incorrect',
                      value: '${result.incorrectCount}',
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.sm + 2),
                    _StatRow(
                      label: 'Unanswered',
                      value: '${result.unansweredCount}',
                      color: AppColors.warning,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Divider(height: 1, color: AppColors.divider),
                    ),
                    _StatRow(
                      label: 'Time Spent',
                      value: _formatDuration(result.durationSeconds),
                      color: AppColors.textPrimary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Performance insights ──
              PerformanceInsightCard(breakdown: breakdown),

              const SizedBox(height: AppSpacing.xl),

              // ── Subject breakdown ──
              if (breakdown.subjects.isNotEmpty) ...[
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
                      'Subject Breakdown',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ...breakdown.subjects.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                    child: SubjectPerformanceCard(performance: s),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // ── Study guidance ──
              StudyGuidanceCard(tips: guidance),

              const SizedBox(height: AppSpacing.xl),

              // ── Retry actions ──
              RetryActionsSection(
                incorrectCount: result.incorrectCount,
                unansweredCount: result.unansweredCount,
                onRetryFull: () => context.go(RouteNames.examSetup),
                onRetryIncorrect: result.incorrectCount > 0
                    ? () => context.push(
                        RouteNames.practice,
                        extra: PracticeSessionArgs(
                          questions: result.incorrectQuestions,
                        ),
                      )
                    : null,
                onRetryUnanswered: result.unansweredCount > 0
                    ? () => context.push(
                        RouteNames.practice,
                        extra: PracticeSessionArgs(
                          questions: result.unansweredQuestions,
                        ),
                      )
                    : null,
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Actions ──
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      context.push(RouteNames.examReview, extra: result),
                  icon: const Icon(Icons.rate_review_rounded, size: 20),
                  label: const Text('Review Exam'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 54),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go(RouteNames.home),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 54),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes == 0) return '${seconds}s';
    return '${minutes}m ${seconds}s';
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
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
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
