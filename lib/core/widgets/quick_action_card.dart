import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';
import '../theme/responsive_utils.dart';

/// A quick-action card with icon, title, and optional subtitle.
class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconColor,
    this.iconBgColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;
  final Color? iconColor;
  final Color? iconBgColor;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primary;
    final bgColor = iconBgColor ?? color.withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md + 2,
          ),
          decoration: BoxDecoration(
            color: context.appCardColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: context.responsiveFontSize(14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: context.appSurfaceHighColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: context.appTextHintColor,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
