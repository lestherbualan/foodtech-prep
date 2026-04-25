import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/question_types.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/secondary_screen_header.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../questions/domain/question.dart';
import '../../../questions/presentation/providers/question_providers.dart';
import '../../domain/question_report.dart';
import '../../domain/question_report_summary.dart';
import '../providers/report_providers.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  const ReportDetailScreen({super.key, required this.questionId});

  final String questionId;

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(reportDetailProvider(widget.questionId));
    final reportsAsync = ref.watch(
      reportsForQuestionProvider(widget.questionId),
    );
    final questionsAsync = ref.watch(questionsProvider);

    return Scaffold(
      backgroundColor: context.appBackgroundColor,
      body: Column(
        children: [
          const SecondaryScreenHeader(title: 'Report Detail'),
          Expanded(
            child: summaryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (summary) {
                if (summary == null) {
                  return const Center(child: Text('Report summary not found.'));
                }

                final fullQuestion = questionsAsync.whenOrNull(
                  data: (questions) {
                    try {
                      return questions.firstWhere(
                        (q) => q.questionId == widget.questionId,
                      );
                    } catch (_) {
                      return null;
                    }
                  },
                );

                final reports =
                    reportsAsync.whenOrNull(data: (list) => list) ?? [];

                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  children: [
                    _SectionLabel(label: 'Question'),
                    _QuestionContentCard(
                      summary: summary,
                      fullQuestion: fullQuestion,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _SectionLabel(label: 'Report Summary'),
                    _ReportSummaryCard(summary: summary),
                    const SizedBox(height: AppSpacing.lg),

                    _SectionLabel(label: 'Moderation'),
                    _ModerationCard(
                      summary: summary,
                      fullQuestion: fullQuestion,
                      onMarkUnderReview: () =>
                          _markUnderReview(summary.questionId),
                      onResolve: () =>
                          _openEditAndResolve(summary.questionId, fullQuestion),
                      onReject: () => _openRejectDialog(summary.questionId),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _SectionLabel(label: 'Report History (${reports.length})'),
                    if (reportsAsync.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (reports.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          'No individual reports found.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: context.appTextHintColor),
                        ),
                      )
                    else
                      ...reports.map(
                        (report) => _IndividualReportCard(report: report),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markUnderReview(String questionId) async {
    try {
      final repo = ref.read(reportRepositoryProvider);
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final profile = ref.read(userProfileProvider).valueOrNull;
      final name = profile?.displayName ?? profile?.email ?? '';

      await repo.markUnderReview(
        questionId: questionId,
        reviewerUid: uid,
        reviewerName: name,
      );

      ref.invalidate(reportDetailProvider(questionId));
      ref.invalidate(reportSummariesProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report marked as Under Review'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openEditAndResolve(
    String questionId,
    Question? question,
  ) async {
    if (question == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question data not loaded yet.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuestionEditSheet(question: question),
    );

    if (result == null || !mounted) return;

    try {
      final repo = ref.read(reportRepositoryProvider);
      final firestoreRepo = ref.read(firestoreQuestionRepositoryProvider);
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final profile = ref.read(userProfileProvider).valueOrNull;
      final name = profile?.displayName ?? profile?.email ?? '';

      final bankId = await firestoreRepo.getActiveBankId();

      await repo.resolveReport(
        questionId: questionId,
        bankId: bankId,
        updatedQuestionData: result,
        resolvedByUid: uid,
        resolvedByName: name,
      );

      // Invalidate caches so the corrected question is reflected everywhere.
      firestoreRepo.clearCache();
      ref.invalidate(questionsProvider);
      ref.invalidate(reportDetailProvider(questionId));
      ref.invalidate(reportSummariesProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question corrected and report resolved'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resolve: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openRejectDialog(String questionId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => const _RejectDialog(),
    );

    if (reason == null || reason.trim().isEmpty || !mounted) return;

    try {
      final repo = ref.read(reportRepositoryProvider);
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final profile = ref.read(userProfileProvider).valueOrNull;
      final name = profile?.displayName ?? profile?.email ?? '';

      await repo.rejectReport(
        questionId: questionId,
        rejectedByUid: uid,
        rejectedByName: name,
        rejectionReason: reason.trim(),
      );

      ref.invalidate(reportDetailProvider(questionId));
      ref.invalidate(reportSummariesProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report rejected'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Section label
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.appTextPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// A. Question content card
// ═══════════════════════════════════════════════════════════════════════════════

class _QuestionContentCard extends StatelessWidget {
  const _QuestionContentCard({required this.summary, this.fullQuestion});

  final QuestionReportSummary summary;
  final Question? fullQuestion;

  @override
  Widget build(BuildContext context) {
    final q = fullQuestion;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appCardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.appPrimarySurfaceColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  summary.questionId,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${summary.subjectName} • ${summary.subtopicName}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.appTextHintColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            q?.questionText ?? summary.questionTextPreview,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.appTextPrimaryColor,
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),

          if (q != null) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: context.appDividerColor),
            const SizedBox(height: AppSpacing.md),

            ...List.generate(q.options.length, (i) {
              const labels = ['A', 'B', 'C', 'D'];
              final option = q.options[i];
              final isCorrect = option.isCorrect;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? AppColors.success.withValues(alpha: 0.1)
                            : context.appSurfaceColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isCorrect
                              ? AppColors.success.withValues(alpha: 0.3)
                              : context.appDividerColor,
                        ),
                      ),
                      child: Text(
                        i < labels.length ? labels[i] : '',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCorrect
                              ? AppColors.success
                              : context.appTextSecondaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          option.text,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isCorrect
                                    ? AppColors.success
                                    : context.appTextPrimaryColor,
                                fontWeight: isCorrect
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                        ),
                      ),
                    ),
                    if (isCorrect)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: AppColors.success,
                        ),
                      ),
                  ],
                ),
              );
            }),

            if (q.explanation.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Divider(height: 1, color: context.appDividerColor),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Icon(
                    Icons.auto_stories_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Explanation',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                q.explanation,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.appTextSecondaryColor,
                  height: 1.5,
                ),
              ),
            ],

            // Source metadata (visible in admin report detail)
            if (q.sourceFile != null || q.sourceReference != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Divider(height: 1, color: context.appDividerColor),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(
                    Icons.source_rounded,
                    size: 16,
                    color: context.appTextHintColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Source',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: context.appTextHintColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              if (q.sourceFile != null)
                Text(
                  q.sourceFile!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appTextSecondaryColor,
                  ),
                ),
              if (q.sourceReference != null)
                Text(
                  q.sourceReference!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appTextSecondaryColor,
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// B. Report summary card
// ═══════════════════════════════════════════════════════════════════════════════

class _ReportSummaryCard extends StatelessWidget {
  const _ReportSummaryCard({required this.summary});
  final QuestionReportSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appCardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MiniStat(
                label: 'Reports',
                value: '${summary.reportCount}',
                icon: Icons.flag_rounded,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.lg),
              _MiniStat(
                label: 'Reporters',
                value: '${summary.uniqueReporterCount}',
                icon: Icons.people_outline_rounded,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: context.appDividerColor),
          const SizedBox(height: AppSpacing.md),

          Text(
            'Issue Breakdown',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.appTextSecondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...summary.issueTypeCounts.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appTextPrimaryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${entry.value}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.appTextPrimaryColor,
              ),
            ),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: context.appTextHintColor),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// C. Moderation card (replaces legacy _ReviewControlCard)
// ═══════════════════════════════════════════════════════════════════════════════

class _ModerationCard extends ConsumerWidget {
  const _ModerationCard({
    required this.summary,
    required this.fullQuestion,
    required this.onMarkUnderReview,
    required this.onResolve,
    required this.onReject,
  });

  final QuestionReportSummary summary;
  final Question? fullQuestion;
  final VoidCallback onMarkUnderReview;
  final VoidCallback onResolve;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(userPermissionsProvider);
    final canModerate = permissions.canModerateReports;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appCardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current status badge
          Row(
            children: [
              Text(
                'Status: ',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: context.appTextSecondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(
                    summary.reviewStatus,
                  ).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  summary.reviewStatus.displayLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(summary.reviewStatus),
                  ),
                ),
              ),
            ],
          ),

          // Assignment info
          if (summary.assignedReviewerName != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _MetaRow(
              icon: Icons.person_outline_rounded,
              text: 'Assigned to: ${summary.assignedReviewerName}',
            ),
            if (summary.assignedAt != null)
              _MetaRow(
                icon: Icons.schedule_rounded,
                text: 'Assigned: ${_formatDate(summary.assignedAt!)}',
              ),
          ],

          // Resolution info
          if (summary.resolvedByName != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _MetaRow(
              icon: Icons.check_circle_outline_rounded,
              text: 'Resolved by: ${summary.resolvedByName}',
              color: AppColors.success,
            ),
            if (summary.resolvedAt != null)
              _MetaRow(
                icon: Icons.schedule_rounded,
                text: 'Resolved: ${_formatDate(summary.resolvedAt!)}',
              ),
            if (summary.resolutionNote != null &&
                summary.resolutionNote!.isNotEmpty)
              _MetaRow(
                icon: Icons.notes_rounded,
                text: 'Note: ${summary.resolutionNote}',
              ),
          ],

          // Rejection info
          if (summary.rejectedByName != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _MetaRow(
              icon: Icons.block_rounded,
              text: 'Rejected by: ${summary.rejectedByName}',
              color: AppColors.error,
            ),
            if (summary.rejectedAt != null)
              _MetaRow(
                icon: Icons.schedule_rounded,
                text: 'Rejected: ${_formatDate(summary.rejectedAt!)}',
              ),
            if (summary.rejectionReason != null &&
                summary.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  summary.rejectionReason!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appTextSecondaryColor,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],

          // Legacy reviewer info fallback
          if (summary.reviewedByUid != null &&
              summary.assignedReviewerUid == null &&
              summary.resolvedByUid == null &&
              summary.rejectedByUid == null) ...[
            const SizedBox(height: AppSpacing.sm),
            _MetaRow(
              icon: Icons.person_outline_rounded,
              text:
                  'Reviewed by: ${summary.reviewedByName ?? summary.reviewedByUid}',
            ),
            if (summary.reviewedAt != null)
              _MetaRow(
                icon: Icons.schedule_rounded,
                text: 'Reviewed: ${_formatDate(summary.reviewedAt!)}',
              ),
          ],

          // Admin note
          if (summary.adminNote != null && summary.adminNote!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _MetaRow(
              icon: Icons.sticky_note_2_outlined,
              text: 'Note: ${summary.adminNote}',
            ),
          ],

          // Action buttons (only for moderators)
          if (canModerate) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: context.appDividerColor),
            const SizedBox(height: AppSpacing.md),

            Text(
              'Actions',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: context.appTextSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (summary.reviewStatus == ReviewStatus.open ||
                    summary.reviewStatus == ReviewStatus.underReview)
                  _ActionButton(
                    label: 'Mark Under Review',
                    icon: Icons.visibility_rounded,
                    color: AppColors.tertiary,
                    onTap: onMarkUnderReview,
                  ),
                if (summary.reviewStatus != ReviewStatus.resolved)
                  _ActionButton(
                    label: 'Edit & Resolve',
                    icon: Icons.edit_rounded,
                    color: AppColors.success,
                    onTap: onResolve,
                  ),
                if (summary.reviewStatus != ReviewStatus.rejected)
                  _ActionButton(
                    label: 'Reject',
                    icon: Icons.block_rounded,
                    color: AppColors.error,
                    onTap: onReject,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Color _statusColor(ReviewStatus status) {
    switch (status) {
      case ReviewStatus.open:
        return AppColors.warning;
      case ReviewStatus.underReview:
        return AppColors.tertiary;
      case ReviewStatus.resolved:
        return AppColors.success;
      case ReviewStatus.rejected:
        return AppColors.textHint;
    }
  }

  static String _formatDate(DateTime dt) {
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
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text, this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color ?? context.appTextHintColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.appTextSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// E. Question edit sheet (modal bottom sheet for resolve flow)
// ═══════════════════════════════════════════════════════════════════════════════

class _QuestionEditSheet extends StatefulWidget {
  const _QuestionEditSheet({required this.question});
  final Question question;

  @override
  State<_QuestionEditSheet> createState() => _QuestionEditSheetState();
}

class _QuestionEditSheetState extends State<_QuestionEditSheet> {
  late TextEditingController _questionTextCtrl;
  late List<TextEditingController> _optionCtrls;
  late int _correctIndex;
  late TextEditingController _explanationCtrl;
  late TextEditingController _difficultyCtrl;
  late TextEditingController _questionTypeCtrl;
  late TextEditingController _studyNoteCtrl;
  late TextEditingController _weaknessLabelCtrl;
  late TextEditingController _recommendationCtrl;
  late TextEditingController _sourceRefCtrl;

  String? _errorText;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _questionTextCtrl = TextEditingController(text: q.questionText);
    _optionCtrls = List.generate(
      4,
      (i) => TextEditingController(
        text: i < q.options.length ? q.options[i].text : '',
      ),
    );
    _correctIndex = q.correctOptionIndex < 0 ? 0 : q.correctOptionIndex;
    _explanationCtrl = TextEditingController(text: q.explanation);
    _difficultyCtrl = TextEditingController(text: q.difficulty);
    _questionTypeCtrl = TextEditingController(text: q.questionType ?? '');
    _studyNoteCtrl = TextEditingController(text: q.studyNote ?? '');
    _weaknessLabelCtrl = TextEditingController(text: q.weaknessLabel ?? '');
    _recommendationCtrl = TextEditingController(
      text: q.recommendationText ?? '',
    );
    _sourceRefCtrl = TextEditingController(text: q.sourceReference ?? '');
  }

  @override
  void dispose() {
    _questionTextCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    _explanationCtrl.dispose();
    _difficultyCtrl.dispose();
    _questionTypeCtrl.dispose();
    _studyNoteCtrl.dispose();
    _weaknessLabelCtrl.dispose();
    _recommendationCtrl.dispose();
    _sourceRefCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_questionTextCtrl.text.trim().isEmpty) {
      return 'Question text cannot be empty.';
    }
    if (_explanationCtrl.text.trim().isEmpty) {
      return 'Explanation cannot be empty.';
    }
    for (int i = 0; i < 4; i++) {
      if (_optionCtrls[i].text.trim().isEmpty) {
        return 'Option ${['A', 'B', 'C', 'D'][i]} cannot be empty.';
      }
    }
    if (_correctIndex < 0 || _correctIndex > 3) {
      return 'Exactly one correct option must be selected.';
    }
    return null;
  }

  void _submit() {
    final error = _validate();
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }

    const labels = ['A', 'B', 'C', 'D'];
    final q = widget.question;

    final updatedData = <String, dynamic>{
      'questionText': _questionTextCtrl.text.trim(),
      'options': List.generate(4, (i) {
        final existingId = i < q.options.length
            ? q.options[i].optionId
            : labels[i];
        return {
          'optionId': existingId,
          'text': _optionCtrls[i].text.trim(),
          'isCorrect': i == _correctIndex,
        };
      }),
      'explanation': _explanationCtrl.text.trim(),
      'difficulty': _difficultyCtrl.text.trim().isNotEmpty
          ? _difficultyCtrl.text.trim()
          : 'Medium',
      'lastUpdated': DateTime.now().toIso8601String(),
      'needsManualReview': false,
    };

    // Optional fields — only include if non-empty
    final qType = _questionTypeCtrl.text.trim();
    if (qType.isNotEmpty) updatedData['questionType'] = qType;

    final studyNote = _studyNoteCtrl.text.trim();
    if (studyNote.isNotEmpty) updatedData['studyNote'] = studyNote;

    final weakness = _weaknessLabelCtrl.text.trim();
    if (weakness.isNotEmpty) updatedData['weaknessLabel'] = weakness;

    final recommendation = _recommendationCtrl.text.trim();
    if (recommendation.isNotEmpty) {
      updatedData['recommendationText'] = recommendation;
    }

    final sourceRef = _sourceRefCtrl.text.trim();
    if (sourceRef.isNotEmpty) updatedData['sourceReference'] = sourceRef;

    Navigator.of(context).pop(updatedData);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: context.appBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.appDisabledColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Edit & Resolve Question',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimaryColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.appDividerColor),

          // Scrollable form
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg + bottomInset,
              ),
              children: [
                if (_errorText != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm + 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      _errorText!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                _buildLabel(context, 'Question Text'),
                _buildTextField(_questionTextCtrl, maxLines: 4),
                const SizedBox(height: AppSpacing.md),

                _buildLabel(context, 'Options'),
                ...List.generate(4, (i) {
                  const labels = ['A', 'B', 'C', 'D'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _correctIndex = i),
                          child: Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(top: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _correctIndex == i
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : context.appSurfaceColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _correctIndex == i
                                    ? AppColors.success
                                    : context.appDividerColor,
                                width: _correctIndex == i ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              labels[i],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _correctIndex == i
                                    ? AppColors.success
                                    : context.appTextSecondaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTextField(
                            _optionCtrls[i],
                            hint: 'Option ${labels[i]}',
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    'Tap the letter to mark the correct option.',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appTextHintColor,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                _buildLabel(context, 'Explanation'),
                _buildTextField(_explanationCtrl, maxLines: 4),
                const SizedBox(height: AppSpacing.md),

                // Collapsible extra fields
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Additional Fields',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: context.appTextSecondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: [
                    _buildLabel(context, 'Difficulty'),
                    _buildDropdown(_difficultyCtrl, ['Easy', 'Medium', 'Hard']),
                    const SizedBox(height: AppSpacing.sm),
                    _buildLabel(context, 'Question Type'),
                    _buildDropdown(_questionTypeCtrl, QuestionTypes.canonical),
                    const SizedBox(height: AppSpacing.sm),
                    _buildLabel(context, 'Study Note'),
                    _buildTextField(_studyNoteCtrl, maxLines: 2),
                    const SizedBox(height: AppSpacing.sm),
                    _buildLabel(context, 'Weakness Label'),
                    _buildTextField(_weaknessLabelCtrl),
                    const SizedBox(height: AppSpacing.sm),
                    _buildLabel(context, 'Recommendation'),
                    _buildTextField(_recommendationCtrl, maxLines: 2),
                    const SizedBox(height: AppSpacing.sm),
                    _buildLabel(context, 'Source Reference'),
                    _buildTextField(_sourceRefCtrl),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Save & Resolve'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: context.appTextSecondaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    int maxLines = 1,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: context.appTextPrimaryColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: context.appTextHintColor),
        filled: true,
        fillColor: context.appSurfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: context.appDividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: context.appDividerColor),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }

  Widget _buildDropdown(TextEditingController controller, List<String> values) {
    final current = controller.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.appDividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: values.contains(current) ? current : null,
          hint: Text(
            current.isNotEmpty ? current : 'Select…',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.appTextSecondaryColor,
            ),
          ),
          items: values
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() => controller.text = v);
            }
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// F. Reject dialog
// ═══════════════════════════════════════════════════════════════════════════════

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.appCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      title: const Text('Reject Report'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Please provide a reason for rejection:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appTextSecondaryColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            maxLines: 3,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Rejection reason…',
              hintStyle: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.appTextHintColor),
              filled: true,
              fillColor: context.appSurfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(color: context.appDividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(color: context.appDividerColor),
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.md),
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_controller.text.trim().isEmpty) {
              setState(() => _error = 'Reason is required');
              return;
            }
            Navigator.of(context).pop(_controller.text.trim());
          },
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// D. Individual report card
// ═══════════════════════════════════════════════════════════════════════════════

class _IndividualReportCard extends StatelessWidget {
  const _IndividualReportCard({required this.report});
  final QuestionReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appCardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: context.appDividerColor.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 16,
                color: context.appTextHintColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  report.reportedByDisplayName.isNotEmpty
                      ? report.reportedByDisplayName
                      : report.reportedByEmail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appTextPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatDate(report.reportedAt),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.appTextHintColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          Text(
            '${report.reportedByEmail} • ${report.reportedByUid.substring(0, 8)}…',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.appTextHintColor,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: context.appSurfaceColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  report.context == ReportContext.timedExam
                      ? 'Timed Exam'
                      : 'Practice',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: context.appTextSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: report.issueTypes
                .map(
                  (issue) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      issue,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          if (report.note != null && report.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: context.appSurfaceColor,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                report.note!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.appTextSecondaryColor,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
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
    return '${months[dt.month - 1]} ${dt.day}, '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
