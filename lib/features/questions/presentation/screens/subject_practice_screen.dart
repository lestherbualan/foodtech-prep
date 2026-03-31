import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/secondary_screen_header.dart';
import '../../../exam/domain/exam_subject.dart';
import '../../domain/question.dart';
import '../providers/question_providers.dart';

/// Manual subject-selection entry point for practice.
///
/// Lets the user explicitly choose which subject to study.
/// This is intentionally different from the Weak Areas screen,
/// which is recommendation-driven.
class SubjectPracticeScreen extends ConsumerWidget {
  const SubjectPracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: questionsAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading subjects…'),
        error: (error, _) =>
            Center(child: Text('Failed to load questions.\n$error')),
        data: (questions) {
          final subjectGroups = _groupBySubjectId(questions);

          return CustomScrollView(
            slivers: [
              // Header
              const SliverToBoxAdapter(
                child: SecondaryScreenHeader(
                  title: 'Subject Practice',
                  subtitle: 'Choose what you want to study.',
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

              // Intro card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md + 2),
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
                            Icons.menu_book_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Select a subject group below to practice questions at your own pace.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

              // Subject cards
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final subjectOptions = ExamSubject.options
                          .where((s) => !s.isAll)
                          .toList();
                      final subject = subjectOptions[index];
                      final qs = subjectGroups[subject.id] ?? [];

                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.sm + 4,
                        ),
                        child: _SubjectCard(
                          subject: subject,
                          questionCount: qs.length,
                          color: _subjectColor(index),
                          icon: _subjectIcon(index),
                          onTap: () {
                            if (qs.isEmpty) return;
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

  Map<String, List<Question>> _groupBySubjectId(List<Question> questions) {
    final map = <String, List<Question>>{};
    for (final q in questions) {
      map.putIfAbsent(q.subjectId, () => []).add(q);
    }
    return map;
  }
}

// ─── Subject card ────────────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
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
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

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
