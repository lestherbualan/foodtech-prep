import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary palette — deep warm teal ──
  static const Color primary = Color(0xFF1A6B6A);
  static const Color primaryLight = Color(0xFF2A9D8F);
  static const Color primaryDark = Color(0xFF124E4E);
  static const Color primarySurface = Color(0xFFE8F5F3);

  // ── Secondary palette — warm amber/gold ──
  static const Color secondary = Color(0xFFD4914E);
  static const Color secondaryLight = Color(0xFFE8B882);
  static const Color secondaryDark = Color(0xFFB87730);
  static const Color secondarySurface = Color(0xFFFDF3E7);

  // ── Accent — dusty sage ──
  static const Color accent = Color(0xFF7BA08A);
  static const Color accentLight = Color(0xFFA3C4AF);
  static const Color accentSurface = Color(0xFFEDF5F0);

  // ── Tertiary — muted indigo for variety ──
  static const Color tertiary = Color(0xFF6C63AC);
  static const Color tertiarySurface = Color(0xFFF0EEF8);

  // ── Surface & background — warm cream with depth ──
  static const Color background = Color(0xFFFAF7F2);
  static const Color surface = Color(0xFFF5F1EA);
  static const Color surfaceHigh = Color(0xFFF0ECE4);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardElevated = Color(0xFFFFFDFA);

  // ── Text — dark slate, never pure black ──
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textHint = Color(0xFFB2BEC3);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Status — muted, mature tones ──
  static const Color error = Color(0xFFC0392B);
  static const Color errorLight = Color(0xFFFDEDEB);
  static const Color success = Color(0xFF27AE60);
  static const Color successLight = Color(0xFFE8F8F0);
  static const Color warning = Color(0xFFE67E22);
  static const Color warningLight = Color(0xFFFEF5E7);

  // ── Other ──
  static const Color divider = Color(0xFFE8E2D9);
  static const Color disabled = Color(0xFFC8C2B8);
  static const Color shimmer = Color(0xFFEDE8E0);
  static const Color outline = Color(0xFFD5CFC5);
  static const Color outlineVariant = Color(0xFFE8E2D9);

  // ── Gradient helpers ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1A6B6A), Color(0xFF2A9D8F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1A6B6A), Color(0xFF1B7E7D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFAF7F2), Color(0xFFF5F1EA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// Dark-mode surface and text colors.
/// Brand colors (primary, secondary, accent, etc.) are reused from [AppColors].
class AppDarkColors {
  AppDarkColors._();

  // ── Surface & background ──
  static const Color background = Color(0xFF121A1A);
  static const Color surface = Color(0xFF192020);
  static const Color surfaceHigh = Color(0xFF1E2828);
  static const Color card = Color(0xFF1E2828);
  static const Color cardElevated = Color(0xFF243030);

  // ── Text ──
  static const Color textPrimary = Color(0xFFE4ECEB);
  static const Color textSecondary = Color(0xFF90A8A5);
  static const Color textHint = Color(0xFF4E6665);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Status surfaces (dark variants) ──
  static const Color primarySurface = Color(0xFF142424);
  static const Color secondarySurface = Color(0xFF281E10);
  static const Color accentSurface = Color(0xFF162220);
  static const Color tertiarySurface = Color(0xFF1C1A2C);
  static const Color errorLight = Color(0xFF2A1614);
  static const Color successLight = Color(0xFF152A1E);
  static const Color warningLight = Color(0xFF2A1E10);

  // ── Borders & misc ──
  static const Color divider = Color(0xFF2A3838);
  static const Color disabled = Color(0xFF3A4A4A);
  static const Color shimmer = Color(0xFF1E2C2C);
  static const Color outline = Color(0xFF2E4040);
  static const Color outlineVariant = Color(0xFF2A3838);

  // ── Gradient helpers ──
  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFF121A1A), Color(0xFF192020)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Dark-mode hero gradient — smooth 2-stop vertical teal wash.
  /// No midpoint stop means no acceleration change, giving a
  /// seamless, continuous blend across the card.
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0D2E2E), Color(0xFF163C3C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Dark-mode primary gradient — very dark teal to mid teal.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0D3333), Color(0xFF1A6B6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// BuildContext extension — theme-aware color helpers
//
// Use these in [build] methods instead of referencing [AppColors] or
// [AppDarkColors] directly so the correct palette is used in both themes.
// ─────────────────────────────────────────────────────────────────────────────

extension AppThemeColors on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  Color get appBackgroundColor =>
      _isDark ? AppDarkColors.background : AppColors.background;
  Color get appSurfaceColor =>
      _isDark ? AppDarkColors.surface : AppColors.surface;
  Color get appSurfaceHighColor =>
      _isDark ? AppDarkColors.surfaceHigh : AppColors.surfaceHigh;
  Color get appCardColor => _isDark ? AppDarkColors.card : AppColors.card;
  Color get appCardElevatedColor =>
      _isDark ? AppDarkColors.cardElevated : AppColors.cardElevated;

  Color get appTextPrimaryColor =>
      _isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
  Color get appTextSecondaryColor =>
      _isDark ? AppDarkColors.textSecondary : AppColors.textSecondary;
  Color get appTextHintColor =>
      _isDark ? AppDarkColors.textHint : AppColors.textHint;

  Color get appDividerColor =>
      _isDark ? AppDarkColors.divider : AppColors.divider;
  Color get appOutlineColor =>
      _isDark ? AppDarkColors.outline : AppColors.outline;
  Color get appDisabledColor =>
      _isDark ? AppDarkColors.disabled : AppColors.disabled;

  Color get appPrimarySurfaceColor =>
      _isDark ? AppDarkColors.primarySurface : AppColors.primarySurface;
  Color get appSecondarySurfaceColor =>
      _isDark ? AppDarkColors.secondarySurface : AppColors.secondarySurface;
  Color get appAccentSurfaceColor =>
      _isDark ? AppDarkColors.accentSurface : AppColors.accentSurface;
  Color get appTertiarySurfaceColor =>
      _isDark ? AppDarkColors.tertiarySurface : AppColors.tertiarySurface;
  Color get appSuccessLightColor =>
      _isDark ? AppDarkColors.successLight : AppColors.successLight;
  Color get appWarningLightColor =>
      _isDark ? AppDarkColors.warningLight : AppColors.warningLight;
  Color get appErrorLightColor =>
      _isDark ? AppDarkColors.errorLight : AppColors.errorLight;

  /// Brand primary — slightly lighter in dark mode for better contrast.
  Color get appPrimaryColor =>
      _isDark ? AppColors.primaryLight : AppColors.primary;

  /// Hero gradient — darker/deeper teal in dark mode.
  LinearGradient get appHeroGradient =>
      _isDark ? AppDarkColors.heroGradient : AppColors.heroGradient;

  /// Primary gradient — darker teal in dark mode.
  LinearGradient get appPrimaryGradient =>
      _isDark ? AppDarkColors.primaryGradient : AppColors.primaryGradient;
}
