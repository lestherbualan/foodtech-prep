import 'dart:math';

import '../../questions/domain/question.dart';
import 'board_exam_blueprint.dart';

/// Result of a board exam generation attempt.
///
/// Contains the selected questions plus metadata about how well
/// the TOS targets were met, including coverage warnings.
class BoardExamGenerationResult {
  const BoardExamGenerationResult({
    required this.questions,
    required this.subjectId,
    required this.targetCount,
    required this.actualCount,
    required this.subtopicCoverage,
    required this.difficultyBreakdown,
    required this.usedFallback,
    this.warnings = const [],
  });

  /// The selected questions, randomised and ready for use.
  final List<Question> questions;

  /// Subject this exam was generated for.
  final String subjectId;

  /// How many questions were targeted (usually [BoardExamConfig.totalQuestions]).
  final int targetCount;

  /// How many questions were actually selected.
  final int actualCount;

  /// Per-subtopicId coverage: subtopicId → count selected.
  final Map<String, int> subtopicCoverage;

  /// Difficulty breakdown: normalised difficulty → count.
  final Map<String, int> difficultyBreakdown;

  /// Whether intra-subject fallback was used to fill shortages.
  final bool usedFallback;

  /// Human-readable warnings about coverage gaps.
  final List<String> warnings;

  /// True if the full target count was reached.
  bool get isFullCoverage => actualCount >= targetCount;
}

/// Generates a TOS-distributed question set for a Board Exam Style exam.
///
/// This generator is **subject-scoped**: it produces a 100-item exam
/// from a single selected major subject, using that subject's internal
/// TOS subtopic allocation table.
///
/// ## Algorithm
///
/// 1. Filter eligible questions to the selected subject.
/// 2. Group questions by their database `subtopicId`.
/// 3. Compute target allocation per subtopicId group, distributed
///    proportionally across available groups (capped at pool size).
/// 4. Within each subtopicId group, apply difficulty distribution
///    as a soft preference (TOS: Easy 30%, Moderate 40%, Difficult 30%).
/// 5. If a subtopicId group is short, redistribute unfilled slots
///    to other subtopicId groups within the SAME subject.
/// 6. Final shuffle. No duplicates guaranteed via usedIds set.
///
/// ## Subtopic mapping limitation
///
/// The TOS defines subtopics at a level (e.g. "Food Chemistry I")
/// that may not correspond 1:1 with the question bank's `subtopicId`
/// values (which may be more granular, e.g. "PCBMP-FC1-CARBS").
///
/// Until a reliable mapping from database subtopicIds to TOS subtopic
/// codes is established, this generator distributes proportionally
/// across all available subtopicId groups within the subject. This
/// prevents overrepresentation of any single subtopicId and stays
/// within the spirit of TOS-fair distribution.
///
/// The TOS subtopic blueprints are preserved in [BoardExamBlueprint]
/// and can be used for exact allocation once the mapping is available.
///
/// ## Fallback rules
///
/// - Intra-subject fallback: YES — redistribution within the same subject.
/// - Cross-subject fallback: NEVER — no questions from other subjects.
/// - If the entire subject pool has fewer questions than the target,
///   the exam is generated with fewer questions and a coverage warning.
class BoardExamGenerator {
  BoardExamGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Generates a board exam for the given [subjectId].
  ///
  /// [pool] should contain ALL eligible questions (the generator will
  /// filter to the correct subject internally).
  BoardExamGenerationResult generate({
    required String subjectId,
    required List<Question> pool,
  }) {
    final target = BoardExamConfig.totalQuestions;
    final warnings = <String>[];

    // ── 1. Filter to the selected subject ────────────────────────────────
    final subjectPool = pool.where((q) => q.subjectId == subjectId).toList();

    if (subjectPool.isEmpty) {
      return BoardExamGenerationResult(
        questions: [],
        subjectId: subjectId,
        targetCount: target,
        actualCount: 0,
        subtopicCoverage: {},
        difficultyBreakdown: {},
        usedFallback: false,
        warnings: ['No questions available for subject $subjectId.'],
      );
    }

    if (subjectPool.length < target) {
      warnings.add(
        'Only ${subjectPool.length} questions available for $subjectId '
        '(target: $target). Exam will have fewer items.',
      );
    }

    // ── 2. Group by subtopicId ───────────────────────────────────────────
    final Map<String, List<Question>> bySubtopic = {};
    for (final q in subjectPool) {
      bySubtopic.putIfAbsent(q.subtopicId, () => []).add(q);
    }

    // Shuffle within each group for randomisation.
    for (final list in bySubtopic.values) {
      list.shuffle(_random);
    }

    // ── 3. Compute per-subtopicId quotas ─────────────────────────────────
    // Distribute proportionally across available subtopicId groups,
    // capped at each group's pool size.
    final subtopicIds = bySubtopic.keys.toList()..shuffle(_random);
    final effectiveTarget = min(target, subjectPool.length);
    final quotas = _computeProportionalQuotas(
      subtopicIds: subtopicIds,
      bySubtopic: bySubtopic,
      totalTarget: effectiveTarget,
    );

    // ── 4. Select questions with difficulty preference ───────────────────
    final Set<String> usedIds = {};
    final List<Question> selected = [];
    final Map<String, int> subtopicCoverage = {};
    bool usedFallback = false;

    // Difficulty targets (TOS-GROUNDED).
    final diffTargets = TosDifficultyTargets.itemTargets(effectiveTarget);
    final Map<String, int> diffSelected = {
      'easy': 0,
      'moderate': 0,
      'difficult': 0,
    };

    // First pass — fill each subtopicId up to its quota.
    final Map<String, int> deficit = {};
    for (final stId in subtopicIds) {
      final quota = quotas[stId] ?? 0;
      if (quota == 0) continue;

      final bucket = bySubtopic[stId]!;
      final picked = _pickWithDifficultyPreference(
        bucket: bucket,
        count: quota,
        diffTargets: diffTargets,
        diffSelected: diffSelected,
        usedIds: usedIds,
      );

      selected.addAll(picked);
      subtopicCoverage[stId] = picked.length;

      if (picked.length < quota) {
        deficit[stId] = quota - picked.length;
      }
    }

    // Second pass — redistribute deficit from surplus subtopicIds
    // (intra-subject only, NEVER cross-subject).
    if (deficit.isNotEmpty) {
      usedFallback = true;
      int totalDeficit = deficit.values.fold(0, (a, b) => a + b);

      for (final stId in subtopicIds) {
        if (totalDeficit <= 0) break;
        if (deficit.containsKey(stId)) continue;

        final bucket = bySubtopic[stId]!;
        for (final q in bucket) {
          if (totalDeficit <= 0) break;
          if (usedIds.contains(q.questionId)) continue;

          selected.add(q);
          usedIds.add(q.questionId);
          subtopicCoverage[stId] = (subtopicCoverage[stId] ?? 0) + 1;
          _trackDifficulty(q, diffSelected);
          totalDeficit--;
        }
      }

      if (totalDeficit > 0) {
        warnings.add(
          'Could not fill $totalDeficit slots despite intra-subject '
          'redistribution. Available questions exhausted.',
        );
      }
    }

    // ── 5. Final shuffle ─────────────────────────────────────────────────
    selected.shuffle(_random);

    return BoardExamGenerationResult(
      questions: selected,
      subjectId: subjectId,
      targetCount: target,
      actualCount: selected.length,
      subtopicCoverage: subtopicCoverage,
      difficultyBreakdown: diffSelected,
      usedFallback: usedFallback,
      warnings: warnings,
    );
  }

  /// Computes per-subtopicId quotas.
  ///
  /// Distributes [totalTarget] proportionally across all subtopicId groups,
  /// capped at each group's available pool size. Any slack from capped
  /// groups is redistributed to uncapped groups.
  Map<String, int> _computeProportionalQuotas({
    required List<String> subtopicIds,
    required Map<String, List<Question>> bySubtopic,
    required int totalTarget,
  }) {
    final int n = subtopicIds.length;
    if (n == 0) return {};

    // Start with even distribution.
    final int base = totalTarget ~/ n;
    int remainder = totalTarget - (base * n);

    final quotas = <String, int>{};
    for (final id in subtopicIds) {
      int q = base + (remainder > 0 ? 1 : 0);
      if (remainder > 0) remainder--;
      // Cap at available pool size.
      final poolSize = bySubtopic[id]?.length ?? 0;
      quotas[id] = min(q, poolSize);
    }

    // Redistribute any slack (from capped quotas) to uncapped groups.
    int totalAssigned = quotas.values.fold(0, (a, b) => a + b);
    int slack = totalTarget - totalAssigned;
    if (slack > 0) {
      for (final id in subtopicIds) {
        if (slack <= 0) break;
        final poolSize = bySubtopic[id]?.length ?? 0;
        final current = quotas[id]!;
        final canTakeMore = poolSize - current;
        if (canTakeMore > 0) {
          final extra = min(canTakeMore, slack);
          quotas[id] = current + extra;
          slack -= extra;
        }
      }
    }

    return quotas;
  }

  /// Picks [count] questions from [bucket], preferring questions that
  /// help meet the TOS difficulty distribution targets.
  ///
  /// This is a **soft** preference: if the exact difficulty mix isn't
  /// available, it takes whatever is available. TOS difficulty targets
  /// are best-effort, not hard constraints.
  List<Question> _pickWithDifficultyPreference({
    required List<Question> bucket,
    required int count,
    required Map<String, int> diffTargets,
    required Map<String, int> diffSelected,
    required Set<String> usedIds,
  }) {
    final result = <Question>[];
    final deferred = <Question>[];

    // First: prefer questions that help fill under-represented difficulties.
    for (final q in bucket) {
      if (result.length >= count) break;
      if (usedIds.contains(q.questionId)) continue;

      final normDiff = TosDifficultyTargets.normaliseDifficulty(q.difficulty);
      final targetForDiff = diffTargets[normDiff] ?? 0;
      final selectedForDiff = diffSelected[normDiff] ?? 0;

      if (selectedForDiff < targetForDiff) {
        result.add(q);
        usedIds.add(q.questionId);
        diffSelected[normDiff] = selectedForDiff + 1;
      } else {
        deferred.add(q);
      }
    }

    // Second: fill remainder regardless of difficulty.
    for (final q in deferred) {
      if (result.length >= count) break;
      if (usedIds.contains(q.questionId)) continue;

      result.add(q);
      usedIds.add(q.questionId);
      _trackDifficulty(q, diffSelected);
    }

    return result;
  }

  void _trackDifficulty(Question q, Map<String, int> diffSelected) {
    final normDiff = TosDifficultyTargets.normaliseDifficulty(q.difficulty);
    diffSelected[normDiff] = (diffSelected[normDiff] ?? 0) + 1;
  }
}
