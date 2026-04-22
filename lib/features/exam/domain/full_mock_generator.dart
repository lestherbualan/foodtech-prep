import 'dart:math';

import '../../questions/domain/question.dart';
import 'board_exam_blueprint.dart';

/// Result of a full mock exam generation attempt.
class FullMockGenerationResult {
  const FullMockGenerationResult({
    required this.questions,
    required this.targetCount,
    required this.actualCount,
    required this.subjectCoverage,
    required this.subtopicCoverage,
    required this.difficultyBreakdown,
    required this.usedFallback,
    this.warnings = const [],
  });

  final List<Question> questions;
  final int targetCount;
  final int actualCount;

  /// Number of questions selected per subjectId.
  final Map<String, int> subjectCoverage;

  /// Number of questions selected per subtopicId.
  final Map<String, int> subtopicCoverage;

  final Map<String, int> difficultyBreakdown;
  final bool usedFallback;
  final List<String> warnings;

  bool get isFullCoverage => actualCount >= targetCount;
}

/// Generates a cross-subject 100-item Full Mock Exam.
///
/// ## How it works
///
/// 1. Uses [FullMockConfig.subjectAllocation] to determine how many
///    questions to draw from each subject (APP CONFIGURATION).
/// 2. Within each subject bucket, distributes questions across available
///    subtopicIds proportionally (TOS-informed).
/// 3. Applies difficulty preference as a soft target (TOS-grounded).
/// 4. If a subject has fewer questions than its allocation, the deficit
///    is redistributed to other subjects that have surplus.
/// 5. Final shuffle across all subjects.
///
/// The cross-subject split is **app-configured**, NOT official PRC.
/// The within-subject distribution is **TOS-informed**.
class FullMockGenerator {
  FullMockGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  FullMockGenerationResult generate({required List<Question> pool}) {
    final target = FullMockConfig.totalQuestions;
    final warnings = <String>[];
    final Set<String> usedIds = {};
    final List<Question> selected = [];
    final Map<String, int> subjectCoverage = {};
    final Map<String, int> subtopicCoverage = {};
    bool usedFallback = false;

    final diffTargets = TosDifficultyTargets.itemTargets(target);
    final Map<String, int> diffSelected = {
      'easy': 0,
      'moderate': 0,
      'difficult': 0,
    };

    // Group all questions by subjectId.
    final Map<String, List<Question>> bySubject = {};
    for (final q in pool) {
      bySubject.putIfAbsent(q.subjectId, () => []).add(q);
    }

    // Shuffle within each subject.
    for (final list in bySubject.values) {
      list.shuffle(_random);
    }

    // ── Pass 1: fill each subject bucket ──────────────────────────────────
    final Map<String, int> deficit = {};

    for (final subjectId in FullMockConfig.subjectOrder) {
      final allocation = FullMockConfig.subjectAllocation[subjectId] ?? 0;
      if (allocation == 0) continue;

      final subjectPool = bySubject[subjectId] ?? [];
      if (subjectPool.isEmpty) {
        warnings.add('No questions available for $subjectId.');
        deficit[subjectId] = allocation;
        subjectCoverage[subjectId] = 0;
        continue;
      }

      // Group by subtopicId within this subject.
      final Map<String, List<Question>> bySubtopic = {};
      for (final q in subjectPool) {
        bySubtopic.putIfAbsent(q.subtopicId, () => []).add(q);
      }

      final subtopicIds = bySubtopic.keys.toList()..shuffle(_random);
      final effectiveTarget = min(allocation, subjectPool.length);
      final quotas = _computeProportionalQuotas(
        subtopicIds: subtopicIds,
        bySubtopic: bySubtopic,
        totalTarget: effectiveTarget,
      );

      int subjectPicked = 0;

      // Fill each subtopic quota.
      final Map<String, int> subtopicDeficit = {};
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
        subjectPicked += picked.length;
        for (final q in picked) {
          subtopicCoverage[q.subtopicId] =
              (subtopicCoverage[q.subtopicId] ?? 0) + 1;
        }

        if (picked.length < quota) {
          subtopicDeficit[stId] = quota - picked.length;
        }
      }

      // Intra-subject redistribution of subtopic deficit.
      if (subtopicDeficit.isNotEmpty) {
        int totalSubtopicDeficit = subtopicDeficit.values.fold(
          0,
          (a, b) => a + b,
        );

        for (final stId in subtopicIds) {
          if (totalSubtopicDeficit <= 0) break;
          if (subtopicDeficit.containsKey(stId)) continue;

          final bucket = bySubtopic[stId]!;
          for (final q in bucket) {
            if (totalSubtopicDeficit <= 0) break;
            if (usedIds.contains(q.questionId)) continue;

            selected.add(q);
            usedIds.add(q.questionId);
            subjectPicked++;
            subtopicCoverage[q.subtopicId] =
                (subtopicCoverage[q.subtopicId] ?? 0) + 1;
            _trackDifficulty(q, diffSelected);
            totalSubtopicDeficit--;
          }
        }
      }

      subjectCoverage[subjectId] = subjectPicked;

      if (subjectPicked < allocation) {
        deficit[subjectId] = allocation - subjectPicked;
        warnings.add(
          'Only $subjectPicked/$allocation questions filled for $subjectId.',
        );
      }
    }

    // ── Pass 2: redistribute cross-subject deficit ───────────────────────
    if (deficit.isNotEmpty) {
      usedFallback = true;
      int totalDeficit = deficit.values.fold(0, (a, b) => a + b);

      for (final subjectId in FullMockConfig.subjectOrder) {
        if (totalDeficit <= 0) break;
        if (deficit.containsKey(subjectId)) continue;

        final subjectPool = bySubject[subjectId] ?? [];
        for (final q in subjectPool) {
          if (totalDeficit <= 0) break;
          if (usedIds.contains(q.questionId)) continue;

          selected.add(q);
          usedIds.add(q.questionId);
          subjectCoverage[subjectId] = (subjectCoverage[subjectId] ?? 0) + 1;
          subtopicCoverage[q.subtopicId] =
              (subtopicCoverage[q.subtopicId] ?? 0) + 1;
          _trackDifficulty(q, diffSelected);
          totalDeficit--;
        }
      }

      if (totalDeficit > 0) {
        warnings.add(
          'Could not fill $totalDeficit slots despite cross-subject '
          'redistribution. Available questions exhausted.',
        );
      }
    }

    // ── Final shuffle ────────────────────────────────────────────────────
    selected.shuffle(_random);

    return FullMockGenerationResult(
      questions: selected,
      targetCount: target,
      actualCount: selected.length,
      subjectCoverage: subjectCoverage,
      subtopicCoverage: subtopicCoverage,
      difficultyBreakdown: diffSelected,
      usedFallback: usedFallback,
      warnings: warnings,
    );
  }

  Map<String, int> _computeProportionalQuotas({
    required List<String> subtopicIds,
    required Map<String, List<Question>> bySubtopic,
    required int totalTarget,
  }) {
    final int n = subtopicIds.length;
    if (n == 0) return {};

    final int base = totalTarget ~/ n;
    int remainder = totalTarget - (base * n);

    final quotas = <String, int>{};
    for (final id in subtopicIds) {
      int q = base + (remainder > 0 ? 1 : 0);
      if (remainder > 0) remainder--;
      final poolSize = bySubtopic[id]?.length ?? 0;
      quotas[id] = min(q, poolSize);
    }

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

  List<Question> _pickWithDifficultyPreference({
    required List<Question> bucket,
    required int count,
    required Map<String, int> diffTargets,
    required Map<String, int> diffSelected,
    required Set<String> usedIds,
  }) {
    final result = <Question>[];
    final deferred = <Question>[];

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
