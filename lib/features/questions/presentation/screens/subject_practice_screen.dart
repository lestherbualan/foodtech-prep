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
      body: questionsAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading subjects…'),
        error: (error, _) =>
            Center(child: Text('Failed to load questions.\n$error')),
        data: (questions) {
          final subjectGroups = _groupBySubjectId(questions);

          return Column(
            children: [
              const SecondaryScreenHeader(
                title: 'Subject Practice',
                subtitle: 'Pick a subject to get started.',
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.sm),
                    ),

                    // Intro card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md + 2),
                          decoration: BoxDecoration(
                            color: context.appPrimarySurfaceColor.withValues(
                              alpha: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLg,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: context.appPrimaryGradient,
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
                                  'Choose a subject, then pick your study mode.',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xl),
                    ),

                    // Subject cards
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
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
                                  _showSubjectModeSheet(
                                    context,
                                    subject,
                                    qs.length,
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

                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xxl),
                    ),
                  ],
                ),
              ),
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
            color: context.appCardColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: context.appDividerColor),
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
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subject.subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.appSurfaceHighColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: isEmpty
                      ? context.appDisabledColor
                      : context.appTextHintColor,
                ),
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

// ─── Subject mode chooser ─────────────────────────────────────────────────────

void _showSubjectModeSheet(
  BuildContext context,
  ExamSubject subject,
  int questionCount,
) {
  showModalBottomSheet<void>(
    context: context,
    builder: (sheetCtx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appDividerColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              subject.label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Pick a study mode to begin.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            _StudyModeOption(
              icon: Icons.menu_book_rounded,
              color: AppColors.primary,
              title: 'Practice Mode',
              subtitle: 'Browse questions at your own pace',
              onTap: () {
                Navigator.of(sheetCtx).pop();
                context.push(RouteNames.questionBankSubject, extra: subject.id);
              },
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            _StudyModeOption(
              icon: Icons.school_rounded,
              color: const Color(0xFF6D28D9),
              title: 'TOS Mock',
              subtitle: '100 questions · official TOS format',
              onTap: () {
                Navigator.of(sheetCtx).pop();
                context.push(RouteNames.boardExamSetup, extra: subject.id);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    ),
  );
}

class _StudyModeOption extends StatelessWidget {
  const _StudyModeOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md + 2),
          decoration: BoxDecoration(
            color: context.appSurfaceHighColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: context.appDividerColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: context.appTextHintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
