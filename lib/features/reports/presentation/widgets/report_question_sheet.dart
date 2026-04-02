import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../questions/domain/question.dart';
import '../../domain/question_report.dart';
import '../providers/report_providers.dart';

/// Shows a bottom sheet for reporting a question issue.
///
/// [question] — the question being reported.
/// [reportContext] — whether from practice or timed exam.
/// [examAttemptId] — optional exam attempt ID if from timed exam.
Future<void> showReportQuestionSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Question question,
  required ReportContext reportContext,
  String? examAttemptId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (ctx) => _ReportQuestionSheet(
      question: question,
      reportContext: reportContext,
      examAttemptId: examAttemptId,
      ref: ref,
    ),
  );
}

class _ReportQuestionSheet extends StatefulWidget {
  const _ReportQuestionSheet({
    required this.question,
    required this.reportContext,
    required this.ref,
    this.examAttemptId,
  });

  final Question question;
  final ReportContext reportContext;
  final WidgetRef ref;
  final String? examAttemptId;

  @override
  State<_ReportQuestionSheet> createState() => _ReportQuestionSheetState();
}

class _ReportQuestionSheetState extends State<_ReportQuestionSheet> {
  final _selectedIssues = <String>{};
  final _noteController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedIssues.isEmpty) return;

    setState(() => _submitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final preview = widget.question.questionText.length > 120
          ? '${widget.question.questionText.substring(0, 120)}...'
          : widget.question.questionText;

      final report = QuestionReport(
        reportId: '', // assigned by Firestore
        questionId: widget.question.questionId,
        subjectId: widget.question.subjectId,
        subjectName: widget.question.subjectName,
        subtopicId: widget.question.subtopicId,
        subtopicName: widget.question.subtopicName,
        questionTextPreview: preview,
        reportedByUid: user.uid,
        reportedByDisplayName: user.displayName ?? '',
        reportedByEmail: user.email ?? '',
        reportedAt: DateTime.now(),
        context: widget.reportContext,
        issueTypes: _selectedIssues.toList(),
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
        examAttemptId: widget.examAttemptId,
      );

      final repo = widget.ref.read(reportRepositoryProvider);
      await repo.submitReport(report);

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks, your report was submitted.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title
              Text(
                'Report Question',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Select the issues you found with this question.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Issue type checkboxes
              ...ReportIssueType.all.map(
                (issue) => _IssueCheckbox(
                  label: issue,
                  isSelected: _selectedIssues.contains(issue),
                  onChanged: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedIssues.add(issue);
                      } else {
                        _selectedIssues.remove(issue);
                      }
                    });
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Optional note
              TextField(
                controller: _noteController,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Additional notes (optional)',
                  hintStyle: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  counterStyle: Theme.of(context).textTheme.labelSmall,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _selectedIssues.isNotEmpty && !_submitting
                          ? _submit
                          : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 50),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Submit Report'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IssueCheckbox extends StatelessWidget {
  const _IssueCheckbox({
    required this.label,
    required this.isSelected,
    required this.onChanged,
  });

  final String label;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!isSelected),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: isSelected,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(color: AppColors.disabled, width: 1.5),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
