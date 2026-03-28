import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
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
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.go(RouteNames.home),
          ),
          title: Text(
            'Exam Results',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // ── Score card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    // Score circle
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: passed
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                        border: Border.all(
                          color: passed ? AppColors.success : AppColors.error,
                          width: 3,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${result.scorePercent.round()}%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: passed ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      feedback.headline,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Text(
                        feedback.subtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (result.wasAutoSubmitted) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Time expired — auto-submitted',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Breakdown card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Summary',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
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
                    const SizedBox(height: AppSpacing.sm),
                    _StatRow(
                      label: 'Incorrect',
                      value: '${result.incorrectCount}',
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.sm),
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

              const SizedBox(height: AppSpacing.lg),

              // ── Performance insights ──
              PerformanceInsightCard(breakdown: breakdown),

              const SizedBox(height: AppSpacing.lg),

              // ── Subject breakdown ──
              if (breakdown.subjects.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Subject Breakdown',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...breakdown.subjects.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: SubjectPerformanceCard(performance: s),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // ── Study guidance ──
              StudyGuidanceCard(tips: guidance),

              const SizedBox(height: AppSpacing.lg),

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

              const SizedBox(height: AppSpacing.lg),

              // ── Actions ──
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      context.push(RouteNames.examReview, extra: result),
                  icon: const Icon(Icons.rate_review_rounded, size: 20),
                  label: const Text('Review Exam'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go(RouteNames.home),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
