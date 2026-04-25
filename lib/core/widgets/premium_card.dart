import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';

/// A premium card wrapper with consistent warm styling.
class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderColor,
    this.borderRadius,
    this.onTap,
    this.elevated = false,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final double? borderRadius;
  final VoidCallback? onTap;
  final bool elevated;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppSpacing.radiusLg;

    final decoration = BoxDecoration(
      color: gradient == null ? (color ?? context.appCardColor) : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: borderColor != null
          ? Border.all(color: borderColor!, width: 1)
          : null,
      boxShadow: elevated
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            width: double.infinity,
            padding: padding ?? const EdgeInsets.all(AppSpacing.md),
            decoration: decoration,
            child: child,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: decoration,
      child: child,
    );
  }
}
