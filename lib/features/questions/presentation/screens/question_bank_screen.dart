import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/question.dart';
import '../providers/practice_session_provider.dart';
import '../providers/question_providers.dart';

class QuestionBankScreen extends ConsumerWidget {
  const QuestionBankScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Question Bank')),
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

          // Group by subject for a cleaner browse experience
          final subjects = _groupBySubject(questions);

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subjectId = subjects.keys.elementAt(index);
              final group = subjects[subjectId]!;
              final subjectName = group.first.subjectName;

              return _SubjectSection(
                subjectName: subjectName,
                questions: group,
                onQuestionTap: (question) {
                  final index = questions.indexOf(question);
                  context.push(
                    RouteNames.practice,
                    extra: PracticeSessionArgs(
                      questions: questions,
                      startIndex: index >= 0 ? index : 0,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

Map<String, List<Question>> _groupBySubject(List<Question> questions) {
  final map = <String, List<Question>>{};
  for (final q in questions) {
    map.putIfAbsent(q.subjectId, () => []).add(q);
  }
  return map;
}

class _SubjectSection extends StatelessWidget {
  const _SubjectSection({
    required this.subjectName,
    required this.questions,
    required this.onQuestionTap,
  });

  final String subjectName;
  final List<Question> questions;
  final ValueChanged<Question> onQuestionTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  subjectName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '${questions.length}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        ...questions.map(
          (q) => _QuestionTile(question: q, onTap: () => onQuestionTap(q)),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({required this.question, required this.onTap});

  final Question question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _DifficultyChip(difficulty: question.difficulty),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      question.subtopicName,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                question.questionText,
                style: Theme.of(context).textTheme.bodyLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                question.questionId,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({required this.difficulty});

  final String difficulty;

  @override
  Widget build(BuildContext context) {
    final color = switch (difficulty) {
      'Easy' => AppColors.success,
      'Medium' => AppColors.warning,
      'Hard' => AppColors.error,
      _ => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        difficulty,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
