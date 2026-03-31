import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/secondary_screen_header.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../exam/domain/exam_subject.dart';
import '../../domain/question.dart';
import '../providers/question_providers.dart';

/// Level 1 of the Question Bank — a scalable subject explorer.
///
/// Shows the 4 official subject groups as distinct cards.
/// Tapping a subject navigates to the Level 2 subtopic screen.
class QuestionBankScreen extends ConsumerWidget {
  const QuestionBankScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: questionsAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading questions…'),
        error: (error, _) => ErrorStateWidget(
          message: 'Failed to load questions.\n$error',
          onRetry: () => ref.invalidate(questionsProvider),
        ),
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(child: Text('No questions found.'));
          }

          final counts = _countBySubjectId(questions);

          return CustomScrollView(
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(
                child: SecondaryScreenHeader(
                  title: 'Question Bank',
                  subtitle: 'Browse questions by subject and topic.',
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

              // ── Total count banner ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md + 2,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.library_books_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${questions.length} Total Questions',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Browse by subject to start practicing',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

              // ── Subject group section ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: SectionHeader(
                    title: 'Subject Groups',
                    trailingText: '${counts.length} subjects',
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final subjectOptions = ExamSubject.options
                          .where((s) => !s.isAll)
                          .toList();
                      final subject = subjectOptions[index];
                      final count = counts[subject.id] ?? 0;

                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.sm + 4,
                        ),
                        child: _SubjectExplorerCard(
                          subject: subject,
                          questionCount: count,
                          color: _subjectColor(index),
                          icon: _subjectIcon(index),
                          onTap: () {
                            if (count == 0) return;
                            context.push(
                              RouteNames.questionBankSubject,
                              extra: subject.id,
                            );
                          },
                        ),
                      );
                    },
                    childCount: ExamSubject.options
                        .where((s) => !s.isAll)
                        .length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          );
        },
      ),
    );
  }
}

Map<String, int> _countBySubjectId(List<Question> questions) {
  final map = <String, int>{};
  for (final q in questions) {
    map[q.subjectId] = (map[q.subjectId] ?? 0) + 1;
  }
  return map;
}

Color _subjectColor(int index) {
  const colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    Color(0xFF7B68EE),
  ];
  return colors[index % colors.length];
}

IconData _subjectIcon(int index) {
  const icons = [
    Icons.science_rounded,
    Icons.restaurant_rounded,
    Icons.verified_rounded,
    Icons.gavel_rounded,
  ];
  return icons[index % icons.length];
}

class _SubjectExplorerCard extends StatelessWidget {
  const _SubjectExplorerCard({
    required this.subject,
    required this.questionCount,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final ExamSubject subject;
  final int questionCount;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isEmpty = questionCount == 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEmpty ? null : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md + 4),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subject.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isEmpty
                          ? AppColors.surface
                          : color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    child: Text(
                      '$questionCount',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isEmpty ? AppColors.textHint : color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'questions',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textHint,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
