import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/saved_exam_attempt.dart';
import '../providers/exam_attempt_providers.dart';

class ExamHistoryScreen extends ConsumerWidget {
  const ExamHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exam History')),
        body: const Center(child: Text('Please sign in to view history.')),
      );
    }

    final attemptsAsync = ref.watch(recentAttemptsProvider(user.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Exam History')),
      body: attemptsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorStateWidget(
          message: 'Could not load exam history.',
          onRetry: () => ref.invalidate(recentAttemptsProvider),
        ),
        data: (attempts) {
          if (attempts.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.history_rounded,
              message:
                  'No exams yet. Complete a timed exam to see your history here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: attempts.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) =>
                _AttemptCard(attempt: attempts[index]),
          );
        },
      ),
    );
  }
}

class _AttemptCard extends StatelessWidget {
  const _AttemptCard({required this.attempt});

  final SavedExamAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final passed = attempt.scorePercent >= 50;
    final dateStr = _formatDate(attempt.submittedAt);
    final minutes = attempt.timeSpentSeconds ~/ 60;
    final seconds = attempt.timeSpentSeconds % 60;
    final timeStr = minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => context.push(RouteNames.attemptDetail, extra: attempt),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: date + score badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dateStr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs / 2,
                    ),
                    decoration: BoxDecoration(
                      color: passed
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      '${attempt.scorePercent.round()}%',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: passed ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Stats row
              Row(
                children: [
                  _Chip(
                    icon: Icons.check_circle_outline,
                    label: '${attempt.correctCount}',
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _Chip(
                    icon: Icons.cancel_outlined,
                    label: '${attempt.incorrectCount}',
                    color: AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _Chip(
                    icon: Icons.remove_circle_outline,
                    label: '${attempt.unansweredCount}',
                    color: AppColors.warning,
                  ),
                  const Spacer(),
                  Text(
                    timeStr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // Subject info
              if (attempt.strongestSubject != null ||
                  attempt.weakestSubject != null) ...[
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: AppSpacing.sm),
                if (attempt.strongestSubject != null)
                  _SubjectLabel(
                    icon: Icons.arrow_upward_rounded,
                    label: attempt.strongestSubject!,
                    color: AppColors.success,
                  ),
                if (attempt.weakestSubject != null)
                  _SubjectLabel(
                    icon: Icons.arrow_downward_rounded,
                    label: attempt.weakestSubject!,
                    color: AppColors.error,
                  ),
              ],

              if (attempt.wasAutoSubmitted) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Time expired',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.warning),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} – $h:$min $ampm';
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SubjectLabel extends StatelessWidget {
  const _SubjectLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
