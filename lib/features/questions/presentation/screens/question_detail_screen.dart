import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/question_types.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/question.dart';

class QuestionDetailScreen extends ConsumerWidget {
  const QuestionDetailScreen({super.key, required this.question});

  final Question question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const labels = ['A', 'B', 'C', 'D'];
    final permissions = ref.watch(userPermissionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(question.questionId)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject & subtopic header
            _MetaRow(label: 'Subject', value: question.subjectName),
            const SizedBox(height: AppSpacing.xs),
            _MetaRow(label: 'Subtopic', value: question.subtopicName),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                _MetaChip(
                  label: question.difficulty,
                  color: _difficultyColor(question.difficulty),
                ),
                if (question.questionType != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _MetaChip(
                    label: question.questionType!,
                    color: QuestionTypes.color(question.questionType),
                  ),
                ],
              ],
            ),

            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // Question text
            Text(
              question.questionText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Choices
            ...List.generate(question.options.length, (i) {
              final option = question.options[i];
              return _ChoiceCard(
                letter: i < labels.length ? labels[i] : '${i + 1}',
                text: option.text,
                isCorrect: option.isCorrect,
              );
            }),

            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // Correct answer
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Correct Answer: ${question.correctAnswerLabel}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppColors.success),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Explanation
            _SectionCard(
              title: 'Explanation',
              icon: Icons.lightbulb_outline_rounded,
              content: question.explanation,
            ),

            if (question.studyNote != null) ...[
              const SizedBox(height: AppSpacing.md),
              _SectionCard(
                title: 'Study Note',
                icon: Icons.school_outlined,
                content: question.studyNote!,
              ),
            ],

            if (question.recommendationText != null) ...[
              const SizedBox(height: AppSpacing.md),
              _SectionCard(
                title: 'Recommendation',
                icon: Icons.tips_and_updates_outlined,
                content: question.recommendationText!,
              ),
            ],

            if (question.sourceReference != null &&
                permissions.canViewQuestionSource) ...[
              const SizedBox(height: AppSpacing.md),
              _MetaRow(label: 'Source', value: question.sourceReference!),
            ],

            if (question.sourceFile != null &&
                permissions.canViewQuestionSource) ...[
              const SizedBox(height: AppSpacing.xs),
              _MetaRow(label: 'File', value: question.sourceFile!),
            ],

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

Color _difficultyColor(String difficulty) {
  return switch (difficulty) {
    'Easy' => AppColors.success,
    'Medium' => AppColors.warning,
    'Hard' => AppColors.error,
    _ => AppColors.textSecondary,
  };
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.appTextHintColor),
          ),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.letter,
    required this.text,
    required this.isCorrect,
  });

  final String letter;
  final String text;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: isCorrect ? AppColors.success.withValues(alpha: 0.06) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: isCorrect ? AppColors.success : context.appDividerColor,
          width: isCorrect ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isCorrect
                  ? AppColors.success
                  : context.appTextHintColor.withValues(alpha: 0.2),
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isCorrect ? Colors.white : context.appTextPrimaryColor,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.content,
  });

  final String title;
  final IconData icon;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.appDividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            content,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
