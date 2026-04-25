import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/secondary_screen_header.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../exam/domain/exam_subject.dart';
import '../../domain/question.dart';
import '../providers/practice_session_provider.dart';
import '../providers/question_providers.dart';
import 'subtopic_review_screen.dart';

/// Level 2 of the Question Bank explorer.
///
/// Shows subtopics within a specific subject, with question counts.
/// Tapping a subtopic starts practice with those questions.
class QuestionBankSubjectScreen extends ConsumerWidget {
  const QuestionBankSubjectScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionsBySubjectProvider(subjectId));

    // Resolve the display label
    final subjectOpt = ExamSubject.options.firstWhere(
      (s) => s.id == subjectId,
      orElse: () => ExamSubject(id: subjectId, label: subjectId, subtitle: ''),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: questionsAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading questions…'),
        error: (error, _) =>
            Center(child: Text('Failed to load questions.\n$error')),
        data: (questions) {
          if (questions.isEmpty) {
            return Column(
              children: [
                SecondaryScreenHeader(
                  title: subjectOpt.label,
                  subtitle: subjectOpt.subtitle,
                ),
                const Expanded(
                  child: Center(
                    child: Text('No questions available for this subject.'),
                  ),
                ),
              ],
            );
          }

          final subtopics = _groupBySubtopic(questions);

          return Column(
            children: [
              SecondaryScreenHeader(
                title: subjectOpt.label,
                subtitle: subjectOpt.subtitle,
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.sm),
                    ),

                    // ── Practice All button ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: _PracticeAllCard(
                          onTap: () {
                            final shuffled = List<Question>.from(questions)
                              ..shuffle();
                            context.push(
                              RouteNames.practice,
                              extra: PracticeSessionArgs(
                                questions: shuffled,
                                startIndex: 0,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xl),
                    ),

                    // ── Subtopic section header ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: SectionHeader(
                          title: 'Subtopics',
                          trailingText: '${subtopics.length} topics',
                        ),
                      ),
                    ),

                    // ── Subtopic cards ──
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final subtopicName = subtopics.keys.elementAt(index);
                          final qs = subtopics[subtopicName]!;

                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm + 2,
                            ),
                            child: _SubtopicCard(
                              subtopicName: subtopicName,
                              questionCount: qs.length,
                              color: _subtopicColor(index),
                              onTap: () {
                                context.push(
                                  RouteNames.subtopicReview,
                                  extra: SubtopicReviewArgs(
                                    questions: qs,
                                    subtopicName: subtopicName,
                                    subjectName: subjectOpt.label,
                                  ),
                                );
                              },
                            ),
                          );
                        }, childCount: subtopics.length),
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

  Map<String, List<Question>> _groupBySubtopic(List<Question> questions) {
    final map = <String, List<Question>>{};
    for (final q in questions) {
      map.putIfAbsent(q.subtopicName, () => []).add(q);
    }
    return map;
  }
}

// ─── Practice All card ───────────────────────────────────────────────────────

class _PracticeAllCard extends StatelessWidget {
  const _PracticeAllCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md + 4),
      gradient: AppColors.heroGradient,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Start Subject Review',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Shuffled order · all topics included',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white.withValues(alpha: 0.7),
            size: 20,
          ),
        ],
      ),
    );
  }
}

// ─── Subtopic card ───────────────────────────────────────────────────────────

class _SubtopicCard extends StatelessWidget {
  const _SubtopicCard({
    required this.subtopicName,
    required this.questionCount,
    required this.color,
    required this.onTap,
  });

  final String subtopicName;
  final int questionCount;
  final Color color;
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
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.topic_rounded, size: 20, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtopicName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
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

// ─── Helpers ─────────────────────────────────────────────────────────────────

Color _subtopicColor(int index) {
  const colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    Color(0xFF7B68EE),
    AppColors.success,
    Color(0xFFE8836B),
    AppColors.warning,
    Color(0xFF5B9BD5),
  ];
  return colors[index % colors.length];
}
