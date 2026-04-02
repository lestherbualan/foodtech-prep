import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';

/// Standardised header for **all** drill-down / secondary screens.
///
/// Provides a consistent back button, title, optional subtitle,
/// and optional trailing action widget.
///
/// ### Design tokens (single source of truth)
/// | Element        | Value           |
/// |----------------|-----------------|
/// | Back button    | 42 × 42, r14    |
/// | Back icon      | 16 px           |
/// | Title          | headlineSmall / w800 / -0.4 ls |
/// | Subtitle       | bodySmall / textSecondary       |
/// | Horizontal pad | AppSpacing.lg (24)              |
/// | Top pad        | AppSpacing.md (16)              |
/// | Bottom pad     | AppSpacing.md (16)              |
class SecondaryScreenHeader extends StatelessWidget {
  const SecondaryScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
    this.showBack = true,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showBack;

  /// Override the default back-navigation behaviour.
  final VoidCallback? onBack;

  // ── Design constants ──
  static const double _btnSize = 42;
  static const double _btnRadius = 14;
  static const double _iconSize = 16;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, // 24 left
          AppSpacing.md, // 16 top (from safe-area edge)
          AppSpacing.lg, // 24 right
          AppSpacing.md, // 16 bottom before content
        ),
        child: Row(
          children: [
            // ── Back button ──
            if (showBack) ...[
              GestureDetector(
                onTap: onBack ?? () => context.pop(),
                child: Container(
                  width: _btnSize,
                  height: _btnSize,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(_btnRadius),
                    border: Border.all(
                      color: AppColors.divider.withValues(alpha: 0.6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: _iconSize,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],

            // ── Title + subtitle ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Optional trailing action ──
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }

  /// Convenience factory for a trailing icon button that matches the header's
  /// back-button visual language (same container size, radius, shadow).
  static Widget trailingIconButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: _btnSize,
          height: _btnSize,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(_btnRadius),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
