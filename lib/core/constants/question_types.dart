import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Single source of truth for canonical question types and alias normalization.
class QuestionTypes {
  QuestionTypes._();

  // ── Canonical values ────────────────────────────────────────────────
  static const String definition = 'Definition';
  static const String distinction = 'Distinction';
  static const String classification = 'Classification';
  static const String conceptApplication = 'Concept Application';
  static const String scenarioBased = 'Scenario-Based';
  static const String sequence = 'Sequence';

  static const List<String> canonical = [
    definition,
    distinction,
    classification,
    conceptApplication,
    scenarioBased,
    sequence,
  ];

  // ── Alias → canonical mapping ───────────────────────────────────────
  static const Map<String, String> _aliases = {
    'Fact Retrieval': definition,
    'Process Principle': conceptApplication,
    'Rule/Regulation': definition,
    'Recall': definition,
  };

  /// Returns the canonical question type for a raw value.
  ///
  /// - Canonical values pass through unchanged.
  /// - Known aliases are mapped to their canonical equivalent.
  /// - Unknown non-null values are returned as-is (safe fallback).
  /// - Null input returns null.
  static String? normalizeQuestionType(String? raw) {
    if (raw == null) return null;
    if (canonical.contains(raw)) return raw;
    return _aliases[raw] ?? raw;
  }

  /// Whether [value] is one of the 6 canonical question types.
  static bool isCanonical(String? value) =>
      value != null && canonical.contains(value);

  /// Color associated with a question type for UI chips/badges.
  static Color color(String? questionType) {
    return switch (questionType) {
      definition => const Color(0xFF5C8DDB),
      distinction => const Color(0xFFD4813B),
      classification => const Color(0xFF6BAF6E),
      conceptApplication => const Color(0xFF9B6CC2),
      scenarioBased => const Color(0xFFCB5E5E),
      sequence => const Color(0xFF4DA6A6),
      _ => AppColors.textSecondary,
    };
  }
}
