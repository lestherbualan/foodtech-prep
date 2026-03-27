import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';

enum AnswerOptionState {
  /// Default unselected state.
  idle,

  /// User has selected this option but hasn't checked yet.
  selected,

  /// After check: this is the correct answer (whether or not user picked it).
  correct,

  /// After check: user picked this but it is wrong.
  incorrect,

  /// After check: option not selected and not the correct answer.
  disabled,
}

class AnswerOptionCard extends StatelessWidget {
  const AnswerOptionCard({
    super.key,
    required this.letter,
    required this.text,
    required this.optionState,
    required this.onTap,
  });

  final String letter;
  final String text;
  final AnswerOptionState optionState;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (bgColor, borderColor, borderWidth, avatarBg, avatarFg, icon) =
        _resolveStyle();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: borderColor, width: borderWidth),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: avatarBg,
                child:
                    icon ??
                    Text(
                      letter,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: avatarFg,
                      ),
                    ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (
    Color bg,
    Color border,
    double width,
    Color avatarBg,
    Color avatarFg,
    Widget? icon,
  )
  _resolveStyle() {
    return switch (optionState) {
      AnswerOptionState.idle => (
        AppColors.card,
        AppColors.divider,
        1.0,
        AppColors.textHint.withValues(alpha: 0.2),
        AppColors.textPrimary,
        null,
      ),
      AnswerOptionState.selected => (
        AppColors.primary.withValues(alpha: 0.06),
        AppColors.primary,
        1.5,
        AppColors.primary,
        Colors.white,
        null,
      ),
      AnswerOptionState.correct => (
        AppColors.success.withValues(alpha: 0.08),
        AppColors.success,
        1.5,
        AppColors.success,
        Colors.white,
        const Icon(Icons.check_rounded, size: 16, color: Colors.white),
      ),
      AnswerOptionState.incorrect => (
        AppColors.error.withValues(alpha: 0.08),
        AppColors.error,
        1.5,
        AppColors.error,
        Colors.white,
        const Icon(Icons.close_rounded, size: 16, color: Colors.white),
      ),
      AnswerOptionState.disabled => (
        AppColors.card,
        AppColors.divider,
        1.0,
        AppColors.textHint.withValues(alpha: 0.15),
        AppColors.textHint,
        null,
      ),
    };
  }
}
