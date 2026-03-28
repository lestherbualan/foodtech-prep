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
    final (
      bgColor,
      borderColor,
      borderWidth,
      avatarBg,
      avatarFg,
      textColor,
      trailingIcon,
    ) = _resolveStyle();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Letter badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: avatarBg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: trailingIcon != null
                      ? Icon(trailingIcon, size: 18, color: avatarFg)
                      : Text(
                          letter,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: avatarFg,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                // Choice text
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
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
    Color textColor,
    IconData? trailingIcon,
  )
  _resolveStyle() {
    return switch (optionState) {
      AnswerOptionState.idle => (
        AppColors.card,
        AppColors.divider,
        1.0,
        AppColors.surface,
        AppColors.textSecondary,
        AppColors.textPrimary,
        null,
      ),
      AnswerOptionState.selected => (
        AppColors.primary.withValues(alpha: 0.05),
        AppColors.primary,
        1.5,
        AppColors.primary,
        Colors.white,
        AppColors.textPrimary,
        null,
      ),
      AnswerOptionState.correct => (
        const Color(0xFFF0F9F1),
        const Color(0xFFA5D6A7),
        1.5,
        AppColors.success,
        Colors.white,
        AppColors.textPrimary,
        Icons.check_rounded,
      ),
      AnswerOptionState.incorrect => (
        const Color(0xFFFDF0F0),
        const Color(0xFFEF9A9A),
        1.5,
        AppColors.error,
        Colors.white,
        AppColors.textPrimary,
        Icons.close_rounded,
      ),
      AnswerOptionState.disabled => (
        AppColors.surface,
        AppColors.divider,
        1.0,
        AppColors.divider,
        AppColors.textHint,
        AppColors.textHint,
        null,
      ),
    };
  }
}
