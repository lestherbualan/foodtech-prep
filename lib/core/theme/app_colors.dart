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
