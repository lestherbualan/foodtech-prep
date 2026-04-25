import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/secondary_screen_header.dart';
import '../../domain/question_report_summary.dart';
import '../providers/report_providers.dart';

class ReportListScreen extends ConsumerStatefulWidget {
  const ReportListScreen({super.key});

  @override
  ConsumerState<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends ConsumerState<ReportListScreen> {
  ReviewStatus? _statusFilter;
  String _sortMode = 'latest'; // 'latest' or 'most_reported'

  @override
  Widget build(BuildContext context) {
    final summariesAsync = ref.watch(reportSummariesProvider);

    return Scaffold(
      backgroundColor: context.appBackgroundColor,
      body: Column(
        children: [
          const SecondaryScreenHeader(title: 'Reported Questions'),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _statusFilter == null,
                    onTap: () => setState(() => _statusFilter = null),
                  ),
                  ...ReviewStatus.values.map(
                    (status) => _FilterChip(
                      label: status.displayLabel,
                      isSelected: _statusFilter == status,
                      onTap: () => setState(() => _statusFilter = status),
                      color: _statusColor(status),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    width: 1,
                    height: 24,
                    color: context.appDividerColor,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'Latest',
                    isSelected: _sortMode == 'latest',
                    onTap: () => setState(() => _sortMode = 'latest'),
                  ),
                  _FilterChip(
                    label: 'Most reported',
                    isSelected: _sortMode == 'most_reported',
                    onTap: () => setState(() => _sortMode = 'most_reported'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Report list
          Expanded(
            child: summariesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Failed to load reports',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        e.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.appTextSecondaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              data: (summaries) {
                var filtered = summaries;

                // Apply status filter
                if (_statusFilter != null) {
                  filtered = filtered
                      .where((s) => s.reviewStatus == _statusFilter)
                      .toList();
                }

                // Apply sort
                if (_sortMode == 'most_reported') {
                  filtered = [...filtered]
                    ..sort((a, b) => b.reportCount.compareTo(a.reportCount));
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 56,
                          color: context.appDisabledColor,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No reported questions',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: context.appTextSecondaryColor,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _statusFilter != null
                              ? 'No reports with status "${_statusFilter!.displayLabel}"'
                              : 'All questions look good.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: context.appTextHintColor),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(reportSummariesProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm + 2),
                    itemBuilder: (context, index) {
                      return _ReportSummaryCard(
                        summary: filtered[index],
                        onTap: () => context.push(
                          RouteNames.reportDetail,
                          extra: filtered[index].questionId,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
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
}

// ═══════════════════════════════════════════════════════════════════════════════
// Report summary card
// ═══════════════════════════════════════════════════════════════════════════════

class _ReportSummaryCard extends StatelessWidget {
  const _ReportSummaryCard({required this.summary, required this.onTap});

  final QuestionReportSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _ReportListScreenState._statusColor(
      summary.reviewStatus,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
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
              // Question ID + status badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: context.appPrimarySurfaceColor,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      summary.questionId,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      summary.reviewStatus.displayLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + 2),

              // Question text preview
              Text(
                summary.questionTextPreview,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.appTextPrimaryColor,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Subject / subtopic
              Text(
                '${summary.subjectName} • ${summary.subtopicName}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.appTextHintColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm + 2),

              // Stats row
              Row(
                children: [
                  // Report count
                  _StatPill(
                    icon: Icons.flag_rounded,
                    text:
                        '${summary.reportCount} ${summary.reportCount == 1 ? "report" : "reports"}',
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _StatPill(
                    icon: Icons.people_outline_rounded,
                    text:
                        '${summary.uniqueReporterCount} ${summary.uniqueReporterCount == 1 ? "user" : "users"}',
                    color: context.appTextSecondaryColor,
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(summary.latestReportedAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appTextHintColor,
                    ),
                  ),
                ],
              ),

              // Issue type chips
              if (summary.topIssueTypes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm + 2),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: summary.topIssueTypes
                      .take(3)
                      .map(
                        (issue) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: context.appSurfaceColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            issue,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: context.appTextSecondaryColor,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final months = [
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
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.1)
                : context.appCardColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.4)
                  : context.appDividerColor,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? activeColor : context.appTextSecondaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
