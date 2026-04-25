import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';

enum AnswerOptionState { idle, selected, correct, incorrect, disabled }

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
    ) = _resolveStyle(
      context,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md + 2,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: avatarBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: trailingIcon != null
                      ? Icon(trailingIcon, size: 18, color: avatarFg)
                      : Text(
                          letter,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: avatarFg,
                          ),
                        ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: textColor,
                      fontWeight: optionState == AnswerOptionState.selected
                          ? FontWeight.w600
                          : FontWeight.w400,
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
  _resolveStyle(BuildContext context) {
    return switch (optionState) {
      AnswerOptionState.idle => (
        context.appCardColor,
        context.appDividerColor,
        1.0,
        context.appSurfaceColor,
        context.appTextSecondaryColor,
        context.appTextPrimaryColor,
        null,
      ),
      AnswerOptionState.selected => (
        context.appPrimarySurfaceColor,
        context.appPrimaryColor,
        2.0,
        context.appPrimaryColor,
        Colors.white,
        context.appTextPrimaryColor,
        null,
      ),
      AnswerOptionState.correct => (
        context.appSuccessLightColor,
        AppColors.success.withValues(alpha: 0.4),
        2.0,
        AppColors.success,
        Colors.white,
        context.appTextPrimaryColor,
        Icons.check_rounded,
      ),
      AnswerOptionState.incorrect => (
        context.appErrorLightColor,
        AppColors.error.withValues(alpha: 0.4),
        2.0,
        AppColors.error,
        Colors.white,
        context.appTextPrimaryColor,
        Icons.close_rounded,
      ),
      AnswerOptionState.disabled => (
        context.appSurfaceColor,
        context.appDividerColor,
        1.0,
        context.appDividerColor,
        context.appTextHintColor,
        context.appTextHintColor,
        null,
      ),
    };
  }
}
