import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';

/// A set of retry action buttons displayed on the result screen.
class RetryActionsSection extends StatelessWidget {
  const RetryActionsSection({
    super.key,
    required this.incorrectCount,
    required this.unansweredCount,
    required this.onRetryFull,
    required this.onRetryIncorrect,
    required this.onRetryUnanswered,
  });

  final int incorrectCount;
  final int unansweredCount;
  final VoidCallback onRetryFull;
  final VoidCallback? onRetryIncorrect;
  final VoidCallback? onRetryUnanswered;

  @override
  Widget build(BuildContext context) {
    final hasIncorrect = incorrectCount > 0;
    final hasUnanswered = unansweredCount > 0;

    // If nothing to retry selectively, only show full retry
    if (!hasIncorrect && !hasUnanswered) {
      return _RetryButton(
        icon: Icons.refresh_rounded,
        label: 'Retry Full Exam',
        onPressed: onRetryFull,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Try Again',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (hasIncorrect)
          _RetryButton(
            icon: Icons.replay_rounded,
            label: 'Practice Incorrect ($incorrectCount)',
            onPressed: onRetryIncorrect,
          ),
        if (hasUnanswered) ...[
          const SizedBox(height: AppSpacing.sm),
          _RetryButton(
            icon: Icons.skip_next_rounded,
            label: 'Practice Unanswered ($unansweredCount)',
            onPressed: onRetryUnanswered,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        _RetryButton(
          icon: Icons.refresh_rounded,
          label: 'Retry Full Exam',
          onPressed: onRetryFull,
        ),
      ],
    );
  }
}

class _RetryButton extends StatelessWidget {
  const _RetryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.divider),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
        ),
      ),
    );
  }
}
