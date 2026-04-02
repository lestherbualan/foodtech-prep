import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/secondary_screen_header.dart';
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
      backgroundColor: AppColors.background,
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

                    _SectionLabel(label: 'Review'),
                    _ReviewControlCard(
                      summary: summary,
                      onUpdate: (status, note) =>
                          _updateStatus(summary.questionId, status, note),
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
                              ?.copyWith(color: AppColors.textHint),
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

  Future<void> _updateStatus(
    String questionId,
    ReviewStatus status,
    String? note,
  ) async {
    try {
      final repo = ref.read(reportRepositoryProvider);
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      await repo.updateReviewStatus(
        questionId: questionId,
        status: status,
        reviewerUid: uid,
        adminNote: note,
      );

      ref.invalidate(reportDetailProvider(questionId));
      ref.invalidate(reportSummariesProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to ${status.displayLabel}'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
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
              color: AppColors.textPrimary,
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
        color: AppColors.card,
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
                  color: AppColors.primarySurface,
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
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.textHint),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            q?.questionText ?? summary.questionTextPreview,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),

          if (q != null) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.divider),
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
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isCorrect
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        i < labels.length ? labels[i] : '',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCorrect
                              ? AppColors.success
                              : AppColors.textSecondary,
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
                                    : AppColors.textPrimary,
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
              const Divider(height: 1, color: AppColors.divider),
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
                  color: AppColors.textSecondary,
                  height: 1.5,
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
        color: AppColors.card,
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
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppSpacing.md),

          Text(
            'Issue Breakdown',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
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
                        color: AppColors.textPrimary,
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
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textHint),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// C. Review control card
// ═══════════════════════════════════════════════════════════════════════════════

class _ReviewControlCard extends StatefulWidget {
  const _ReviewControlCard({required this.summary, required this.onUpdate});

  final QuestionReportSummary summary;
  final void Function(ReviewStatus status, String? note) onUpdate;

  @override
  State<_ReviewControlCard> createState() => _ReviewControlCardState();
}

class _ReviewControlCardState extends State<_ReviewControlCard> {
  late ReviewStatus _selectedStatus;
  late TextEditingController _noteController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.summary.reviewStatus;
    _noteController = TextEditingController(
      text: widget.summary.adminNote ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _ReviewControlCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.summary.reviewStatus != widget.summary.reviewStatus) {
      _selectedStatus = widget.summary.reviewStatus;
    }
    if (oldWidget.summary.adminNote != widget.summary.adminNote) {
      _noteController.text = widget.summary.adminNote ?? '';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
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
          Text(
            'Set Status',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReviewStatus.values.map((status) {
              final isSelected = _selectedStatus == status;
              final color = _statusColor(status);
              return GestureDetector(
                onTap: () => setState(() => _selectedStatus = status),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(
                      color: isSelected
                          ? color.withValues(alpha: 0.5)
                          : AppColors.divider,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    status.displayLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected ? color : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.md),

          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Admin note (optional)',
              hintStyle: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.md),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      widget.onUpdate(
                        _selectedStatus,
                        _noteController.text.trim().isNotEmpty
                            ? _noteController.text.trim()
                            : null,
                      );
                      await Future.delayed(const Duration(milliseconds: 500));
                      if (mounted) setState(() => _saving = false);
                    },
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Review'),
            ),
          ),

          if (widget.summary.reviewedByUid != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Last reviewed by: ${widget.summary.reviewedByUid}',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textHint),
            ),
            if (widget.summary.reviewedAt != null)
              Text(
                'Reviewed at: ${_formatDate(widget.summary.reviewedAt!)}',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.textHint),
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
      case ReviewStatus.fixed:
        return AppColors.success;
      case ReviewStatus.dismissed:
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 16,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  report.reportedByDisplayName.isNotEmpty
                      ? report.reportedByDisplayName
                      : report.reportedByEmail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatDate(report.reportedAt),
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 4),

          Text(
            '${report.reportedByEmail} • ${report.reportedByUid.substring(0, 8)}…',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textHint,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  report.context == ReportContext.timedExam
                      ? 'Timed Exam'
                      : 'Practice',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                report.note!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
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
