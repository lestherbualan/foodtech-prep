/// TOS-grounded board exam blueprint configuration.
///
/// This file contains:
/// - APP-CONFIGURED simulation constants (clearly labelled)
/// - TOS-GROUNDED subtopic allocations per subject
/// - TOS-GROUNDED difficulty distribution targets
/// - TOS-GROUNDED Bloom taxonomy awareness (not yet enforceable)
/// - APP-CONFIGURED full mock cross-subject allocation
///
/// Source: PRC TOS Weight Blueprint (Board of Food Technology, September 2022).
/// Extracted from TOS.md provided with this project.
///
/// ## Interpretation rules
///
/// The TOS defines four major subjects, each as its own 100-item exam.
/// There is NO official overall cross-subject percentage split in the TOS.
///
/// This app offers two mock exam modes:
/// 1. **Subject TOS Mock** — per-subject, confidently TOS-based.
/// 2. **Full Mock Exam** — cross-subject 100-item simulation using
///    an APP-CONFIGURED subject allocation (not official PRC weighting).
///
/// The full mock uses TOS-informed subtopic logic inside each subject
/// bucket, but the overall A+B+C+D split is app configuration.
library;

import 'package:flutter/material.dart' show IconData, Icons;

// ═══════════════════════════════════════════════════════════════════════════════
// APP CONFIGURATION — Simulation constants (not official PRC rules)
// ═══════════════════════════════════════════════════════════════════════════════

/// App-configured constants for the Subject TOS Mock simulation.
///
/// These values are chosen to simulate a realistic board exam experience.
/// They are NOT claimed to be official PRC exam specifications.
class BoardExamConfig {
  const BoardExamConfig._();

  /// APP CONFIGURATION: Total questions in one Subject TOS Mock simulation.
  static const int totalQuestions = 100;

  /// APP CONFIGURATION: Time limit in minutes for one simulation.
  static const int durationMinutes = 100;
}

// ═══════════════════════════════════════════════════════════════════════════════
// APP CONFIGURATION — Full Mock Exam cross-subject allocation
// ═══════════════════════════════════════════════════════════════════════════════

/// APP-CONFIGURED cross-subject allocation for the Full Mock Exam.
///
/// **IMPORTANT**: The TOS does NOT provide an official combined 100-item
/// cross-subject split. The allocation below is an app simulation rule
/// designed to give balanced coverage. It is NOT claimed to be official
/// PRC weighting.
///
/// Inside each subject bucket the generator uses TOS-informed subtopic
/// distribution logic, so the internal distribution IS TOS-grounded.
class FullMockConfig {
  const FullMockConfig._();

  /// APP CONFIGURATION: Total questions in one Full Mock Exam.
  static const int totalQuestions = 100;

  /// APP CONFIGURATION: Time limit in minutes.
  static const int durationMinutes = 100;

  /// APP CONFIGURATION: Per-subject item allocation.
  ///
  /// Equal 25-item allocation across all four subjects for balanced coverage.
  /// This is an app design choice, not an official PRC specification.
  static const Map<String, int> subjectAllocation = {
    'PCBMP': 25,
    'FLR': 25,
    'FPPE': 25,
    'QSSEF': 25,
  };

  /// Display order for subjects in the full mock UI.
  static const List<String> subjectOrder = ['PCBMP', 'FLR', 'FPPE', 'QSSEF'];
}

// ═══════════════════════════════════════════════════════════════════════════════
// TOS-GROUNDED — Difficulty distribution targets
// ═══════════════════════════════════════════════════════════════════════════════

/// Difficulty distribution from the TOS common blueprint.
///
/// Source: TOS.md § "Common blueprint for all four main topics"
///   Easy     : 30 %
///   Moderate : 40 %
///   Difficult: 30 %
///
/// The question bank uses a `difficulty` field with values like
/// 'Easy', 'Medium', 'Hard'. This class defines the TOS targets
/// and a normalisation mapping for the bank's actual values.
class TosDifficultyTargets {
  const TosDifficultyTargets._();

  /// TOS-GROUNDED difficulty weights.
  static const Map<String, double> weights = {
    'easy': 0.30,
    'moderate': 0.40,
    'difficult': 0.30,
  };

  /// Maps question bank difficulty values to TOS difficulty categories.
  ///
  /// APP CONFIGURATION: This mapping depends on how the question bank
  /// labels difficulty. Update if the bank uses different values.
  static String normaliseDifficulty(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'easy':
        return 'easy';
      case 'medium':
      case 'moderate':
        return 'moderate';
      case 'hard':
      case 'difficult':
        return 'difficult';
      default:
        return 'moderate'; // safe default for unknown values
    }
  }

  /// Computes target item counts for each difficulty level.
  static Map<String, int> itemTargets(int totalItems) {
    final targets = <String, int>{};
    int assigned = 0;
    final entries = weights.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      if (i == entries.length - 1) {
        targets[entries[i].key] = totalItems - assigned;
      } else {
        final count = (entries[i].value * totalItems).round();
        targets[entries[i].key] = count;
        assigned += count;
      }
    }
    return targets;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TOS-GROUNDED — Bloom taxonomy awareness (NOT yet enforceable)
// ═══════════════════════════════════════════════════════════════════════════════

/// Bloom taxonomy distribution from the TOS common blueprint.
///
/// Source: TOS.md § "Common blueprint for all four main topics"
///
/// LIMITATION: The current question bank does NOT reliably tag questions
/// with Bloom taxonomy levels. This class preserves the TOS structure
/// for future use when Bloom metadata becomes available.
/// Do NOT claim exact Bloom enforcement until that happens.
class TosBloomTargets {
  const TosBloomTargets._();

  /// TOS-GROUNDED Bloom taxonomy weights (for awareness / future use).
  static const Map<String, double> weights = {
    'Remembering': 0.15,
    'Understanding': 0.15,
    'Applying': 0.40,
    'Analyzing': 0.10,
    'Evaluating': 0.10,
    'Creating': 0.10,
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// TOS-GROUNDED — Per-subject subtopic blueprints
// ═══════════════════════════════════════════════════════════════════════════════

/// A single TOS subtopic within a major subject.
class TosSubtopic {
  const TosSubtopic({
    required this.code,
    required this.name,
    required this.targetItems,
    required this.weightPercent,
  });

  /// TOS subtopic code (e.g. 'A1', 'B3', 'C5').
  final String code;

  /// TOS subtopic name (verbatim from TOS.md).
  final String name;

  /// Target item count for this subtopic (from TOS).
  /// For a 100-item subject exam, this equals the weight percentage.
  final int targetItems;

  /// Weight as a percentage within the subject (from TOS).
  final int weightPercent;
}

/// TOS blueprint for a single major subject.
///
/// Each subject is a self-contained 100-item exam in the actual board exam.
/// The subtopics and their weights come directly from TOS.md.
class SubjectBlueprint {
  const SubjectBlueprint({
    required this.subjectId,
    required this.abbreviation,
    required this.tosFullName,
    required this.icon,
    required this.subtopics,
  });

  /// Database subject ID (e.g. 'PCBMP').
  final String subjectId;

  /// Short display name.
  final String abbreviation;

  /// Full subject name from TOS.md.
  final String tosFullName;

  /// Icon representing this subject in the UI.
  final IconData icon;

  /// TOS subtopic breakdown with target item counts.
  final List<TosSubtopic> subtopics;

  /// Total target items (should always be 100 for a complete TOS subject).
  int get totalTargetItems =>
      subtopics.fold(0, (sum, s) => sum + s.targetItems);
}

/// All TOS-grounded subject blueprints.
///
/// Source: TOS.md tables A1, B1, C1, D1.
///
/// Each subject is defined as its own 100-item exam with specific
/// subtopic allocations. The item counts below come directly from
/// the "No. of Items" column in each TOS subject table.
class BoardExamBlueprint {
  const BoardExamBlueprint._();

  // ── Subject A: PCBMP ───────────────────────────────────────────────────────
  // Source: TOS.md § "A1. Main topic and subtopics summary"
  static const pcbmp = SubjectBlueprint(
    subjectId: 'PCBMP',
    abbreviation: 'PCBMP',
    tosFullName:
        'Physical, Chemical, Biological, and Microbiological Principles',
    icon: Icons.science_rounded,
    subtopics: [
      TosSubtopic(
        code: 'A1',
        name: 'Food Chemistry I',
        targetItems: 25,
        weightPercent: 25,
      ),
      TosSubtopic(
        code: 'A2',
        name: 'Food Chemistry II',
        targetItems: 25,
        weightPercent: 25,
      ),
      TosSubtopic(
        code: 'A3',
        name: 'General Microbiology',
        targetItems: 25,
        weightPercent: 25,
      ),
      TosSubtopic(
        code: 'A4',
        name: 'Food Microbiology',
        targetItems: 25,
        weightPercent: 25,
      ),
    ],
  );

  // ── Subject B: FLR ─────────────────────────────────────────────────────────
  // Source: TOS.md § "B1. Main topic and subtopics summary"
  // Note: TOS full name is "Food Laws and Regulations and Concepts of Food
  // Science and Technology, Food Safety, Food Analysis, Food Research, and
  // Nutrition". The app abbreviates this to "FLR".
  static const flr = SubjectBlueprint(
    subjectId: 'FLR',
    abbreviation: 'FLR',
    tosFullName:
        'Food Laws and Regulations and Concepts of Food Science and '
        'Technology, Food Safety, Food Analysis, Food Research, and Nutrition',
    icon: Icons.gavel_rounded,
    subtopics: [
      TosSubtopic(
        code: 'B1',
        name: 'Food Laws',
        targetItems: 15,
        weightPercent: 15,
      ),
      TosSubtopic(
        code: 'B2',
        name: 'Introduction to Food Science and Technology',
        targetItems: 4,
        weightPercent: 4,
      ),
      TosSubtopic(
        code: 'B3',
        name: 'Food Safety',
        targetItems: 15,
        weightPercent: 15,
      ),
      TosSubtopic(
        code: 'B4',
        name: 'Food Analysis',
        targetItems: 24,
        weightPercent: 24,
      ),
      TosSubtopic(
        code: 'B5',
        name: 'Methods of Research / Thesis',
        targetItems: 27,
        weightPercent: 27,
      ),
      TosSubtopic(
        code: 'B6',
        name: 'Basic Nutrition',
        targetItems: 15,
        weightPercent: 15,
      ),
    ],
  );

  // ── Subject C: FPPE ────────────────────────────────────────────────────────
  // Source: TOS.md § "C1. Main topic and subtopics summary"
  static const fppe = SubjectBlueprint(
    subjectId: 'FPPE',
    abbreviation: 'FPPE',
    tosFullName: 'Food Processing, Preservation, and Food Engineering',
    icon: Icons.precision_manufacturing_rounded,
    subtopics: [
      TosSubtopic(
        code: 'C1',
        name: 'Food Processing I',
        targetItems: 13,
        weightPercent: 13,
      ),
      TosSubtopic(
        code: 'C2',
        name: 'Food Processing II / OJT II',
        targetItems: 29,
        weightPercent: 29,
      ),
      TosSubtopic(
        code: 'C3',
        name: 'Food Packaging and Labeling',
        targetItems: 13,
        weightPercent: 13,
      ),
      TosSubtopic(
        code: 'C4',
        name: 'Food Engineering',
        targetItems: 19,
        weightPercent: 19,
      ),
      TosSubtopic(
        code: 'C5',
        name: 'Postharvest Handling and Technology',
        targetItems: 13,
        weightPercent: 13,
      ),
      TosSubtopic(
        code: 'C6',
        name: 'Basic Food Preparation',
        targetItems: 13,
        weightPercent: 13,
      ),
    ],
  );

  // ── Subject D: QSSEF ──────────────────────────────────────────────────────
  // Source: TOS.md § "D1. Main topic and subtopics summary"
  // Note: TOS full name is "Food Quality Assurance and Sensory Evaluation
  // and Other Aspects of Food Manufacturing". The app abbreviates to "QSSEF".
  static const qssef = SubjectBlueprint(
    subjectId: 'QSSEF',
    abbreviation: 'QSSEF',
    tosFullName:
        'Food Quality Assurance and Sensory Evaluation and Other Aspects '
        'of Food Manufacturing',
    icon: Icons.verified_rounded,
    subtopics: [
      TosSubtopic(
        code: 'D1',
        name: 'Food Quality Assurance',
        targetItems: 20,
        weightPercent: 20,
      ),
      TosSubtopic(
        code: 'D2',
        name: 'Sensory Evaluation',
        targetItems: 20,
        weightPercent: 20,
      ),
      TosSubtopic(
        code: 'D3',
        name: 'Food Product Development and Innovation',
        targetItems: 20,
        weightPercent: 20,
      ),
      TosSubtopic(
        code: 'D4',
        name: 'Environmental Sustainability in the Food Industry',
        targetItems: 20,
        weightPercent: 20,
      ),
      TosSubtopic(
        code: 'D5',
        name: 'Business Management and Entrepreneurship',
        targetItems: 20,
        weightPercent: 20,
      ),
    ],
  );

  /// All subject blueprints in display order.
  static const List<SubjectBlueprint> allSubjects = [pcbmp, fppe, qssef, flr];

  /// Looks up a blueprint by subject ID. Returns null if not found.
  static SubjectBlueprint? forSubject(String subjectId) {
    for (final bp in allSubjects) {
      if (bp.subjectId == subjectId) return bp;
    }
    return null;
  }

  /// Human-readable display names for mode labels.
  static String subjectDisplayName(String subjectId) {
    return forSubject(subjectId)?.abbreviation ?? subjectId;
  }
}
