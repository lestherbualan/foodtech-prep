import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';

/// Responsive layout and typography helpers for the app.
///
/// Breakpoints (logical screen width):
///   phone        < 600 px   → scale 1.00 (unchanged)
///   small tablet 600–899    → scale 1.15
///   tablet       900–1199   → scale 1.22
///   large tablet ≥ 1200     → scale 1.25
///
/// Font scaling is always capped at 1.25× the base size so fonts never
/// become excessively large.
extension ResponsiveUtils on BuildContext {
  double get _screenWidth => MediaQuery.sizeOf(this).width;

  // ── Scale factors ──────────────────────────────────────────────────────────

  double get _primaryScale {
    final w = _screenWidth;
    if (w >= 1200) return 1.25;
    if (w >= 900) return 1.22;
    if (w >= 600) return 1.15;
    return 1.0;
  }

  double get _secondaryScale {
    final w = _screenWidth;
    if (w >= 1200) return 1.15;
    if (w >= 900) return 1.12;
    if (w >= 600) return 1.08;
    return 1.0;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// `true` when the screen width is ≥ 600 logical pixels (tablet).
  bool get isTablet => _screenWidth >= 600;

  /// Returns a responsive font size for primary / headline text.
  ///
  /// The phone layout is preserved exactly: the returned value equals [base]
  /// when width < 600. Result is capped at [base] × 1.25.
  double responsiveFontSize(double base) =>
      (base * _primaryScale).clamp(base, base * 1.25);

  /// Returns a responsive font size for secondary / metadata text.
  ///
  /// Scales more modestly than [responsiveFontSize]; capped at [base] × 1.15.
  double responsiveSecondaryFontSize(double base) =>
      (base * _secondaryScale).clamp(base, base * 1.15);

  /// Maximum body content width for page layouts.
  ///
  ///   phone (< 600):          no cap → [double.infinity]
  ///   small tablet (600–899): 720 px
  ///   tablet (≥ 900):         800 px
  double get contentMaxWidth {
    final w = _screenWidth;
    if (w >= 900) return 800.0;
    if (w >= 600) return 720.0;
    return double.infinity;
  }

  /// The horizontal inset that centers page content within [contentMaxWidth].
  ///
  /// Falls back to [AppSpacing.lg] on phone screens, so the current phone
  /// layout is preserved exactly.
  double get pageHorizontalPad {
    final w = _screenWidth;
    final maxW = contentMaxWidth;
    if (maxW.isInfinite) return AppSpacing.lg;
    return ((w - maxW) / 2).clamp(AppSpacing.lg, double.infinity);
  }
}
