import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralised score-band classification used across the app.
///
/// Thresholds are aligned with the dashboard's passing model:
///   ≥ 75 %  →  passing  (green / success)
///   ≥ 50 %  →  borderline (amber / warning)
///   < 50 %  →  failing  (red / error)
abstract final class ScoreBand {
  /// Threshold at or above which a score is considered passing.
  static const double passingThreshold = 75;

  /// Threshold at or above which a score is considered borderline.
  static const double borderlineThreshold = 50;

  // ── Solid colours ──

  static Color color(double? score) {
    if (score == null) return AppColors.textHint;
    if (score >= passingThreshold) return AppColors.success;
    if (score >= borderlineThreshold) return AppColors.warning;
    return AppColors.error;
  }

  // ── Light / surface colours ──

  static Color surface(double? score) {
    if (score == null) return AppColors.surface;
    if (score >= passingThreshold) return AppColors.successLight;
    if (score >= borderlineThreshold) return AppColors.warningLight;
    return AppColors.errorLight;
  }

  // ── Dark surface variants ──

  static Color surfaceDark(double? score) {
    if (score == null) return AppDarkColors.surface;
    if (score >= passingThreshold) return AppDarkColors.successLight;
    if (score >= borderlineThreshold) return AppDarkColors.warningLight;
    return AppDarkColors.errorLight;
  }

  /// Context-aware surface — returns [surfaceDark] in dark mode, [surface] in light.
  static Color surfaceFor(BuildContext context, double? score) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceDark(score)
        : surface(score);
  }

  // ── Foreground text on the surface variant ──

  static Color foregroundOnSurface(double? score) {
    if (score == null) return AppColors.textSecondary;
    if (score >= passingThreshold) return AppColors.success;
    if (score >= borderlineThreshold) return AppColors.warning;
    return AppColors.error;
  }
}
