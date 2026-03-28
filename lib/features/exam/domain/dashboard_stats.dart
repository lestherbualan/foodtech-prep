import 'saved_exam_attempt.dart';

// ─── Trend direction ─────────────────────────────────────────────────────────

enum TrendDirection { improving, steady, declining, insufficient }

// ─── Subject aggregate ───────────────────────────────────────────────────────

/// Aggregated subject stats across multiple attempts.
class SubjectAggregate {
  const SubjectAggregate({
    required this.subjectName,
    required this.timesStrongest,
    required this.timesWeakest,
  });

  final String subjectName;
  final int timesStrongest;
  final int timesWeakest;
}

// ─── Dashboard stats ─────────────────────────────────────────────────────────

/// Lightweight aggregate computed from recent saved attempts.
class DashboardStats {
  const DashboardStats({
    required this.totalAttempts,
    required this.latestScore,
    required this.bestScore,
    required this.averageScore,
    required this.latestDate,
    required this.trend,
    required this.trendExplanation,
    this.strongestSubject,
    this.weakestSubject,
    this.mostFrequentWeakSubject,
    required this.focusAdvice,
    required this.recentAttempts,
  });

  final int totalAttempts;
  final double latestScore;
  final double bestScore;
  final double averageScore;
  final DateTime latestDate;
  final TrendDirection trend;
  final String trendExplanation;
  final String? strongestSubject;
  final String? weakestSubject;
  final String? mostFrequentWeakSubject;
  final List<String> focusAdvice;
  final List<SavedExamAttempt> recentAttempts;

  /// Computes dashboard stats from a list of attempts (newest-first).
  factory DashboardStats.compute(List<SavedExamAttempt> attempts) {
    if (attempts.isEmpty) {
      return DashboardStats(
        totalAttempts: 0,
        latestScore: 0,
        bestScore: 0,
        averageScore: 0,
        latestDate: DateTime.now(),
        trend: TrendDirection.insufficient,
        trendExplanation: 'Take your first exam to start tracking progress.',
        focusAdvice: const [],
        recentAttempts: const [],
      );
    }

    // Use last 10 attempts max for dashboard window
    final recent = attempts.length > 10 ? attempts.sublist(0, 10) : attempts;

    final latest = recent.first;
    final latestScore = latest.scorePercent;
    final bestScore = recent.fold<double>(
      0,
      (double best, SavedExamAttempt a) =>
          a.scorePercent > best ? a.scorePercent : best,
    );
    final avgScore =
        recent.fold<double>(
          0,
          (double sum, SavedExamAttempt a) => sum + a.scorePercent,
        ) /
        recent.length;

    // ── Trend: compare last 3 avg vs previous 3 avg ──
    final trend = _computeTrend(recent);

    // ── Subject aggregates ──
    final strongCounts = <String, int>{};
    final weakCounts = <String, int>{};
    for (final a in recent) {
      if (a.strongestSubject != null) {
        strongCounts[a.strongestSubject!] =
            (strongCounts[a.strongestSubject!] ?? 0) + 1;
      }
      if (a.weakestSubject != null) {
        weakCounts[a.weakestSubject!] =
            (weakCounts[a.weakestSubject!] ?? 0) + 1;
      }
    }

    final strongestSubject = strongCounts.isNotEmpty
        ? (strongCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key
        : null;

    final weakestSubject = weakCounts.isNotEmpty
        ? (weakCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key
        : null;

    // ── Focus advice ──
    final advice = _buildFocusAdvice(
      trend: trend,
      latestScore: latestScore,
      avgScore: avgScore,
      latest: latest,
      weakestSubject: weakestSubject,
      strongestSubject: strongestSubject,
      attemptCount: recent.length,
    );

    return DashboardStats(
      totalAttempts: recent.length,
      latestScore: latestScore,
      bestScore: bestScore,
      averageScore: avgScore,
      latestDate: latest.submittedAt,
      trend: trend.direction,
      trendExplanation: trend.explanation,
      strongestSubject: strongestSubject,
      weakestSubject: weakestSubject,
      mostFrequentWeakSubject: weakestSubject,
      focusAdvice: advice,
      recentAttempts: recent,
    );
  }

  static _TrendResult _computeTrend(List<SavedExamAttempt> recent) {
    if (recent.length < 2) {
      return _TrendResult(
        TrendDirection.insufficient,
        'Complete more exams to see your trend.',
      );
    }

    if (recent.length < 4) {
      // Compare latest vs rest
      final latestScore = recent.first.scorePercent;
      final restAvg =
          recent
              .skip(1)
              .fold<double>(
                0,
                (double s, SavedExamAttempt a) => s + a.scorePercent,
              ) /
          (recent.length - 1);
      return _classifyDiff(latestScore - restAvg);
    }

    // Compare last 3 avg vs previous 3 avg
    final recentThreeList = recent.take(3).toList();
    final prevThreeList = recent.skip(3).take(3).toList();
    final recentThreeAvg =
        recentThreeList.fold<double>(
          0,
          (double s, SavedExamAttempt a) => s + a.scorePercent,
        ) /
        recentThreeList.length;
    final prevThreeAvg =
        prevThreeList.fold<double>(
          0,
          (double s, SavedExamAttempt a) => s + a.scorePercent,
        ) /
        prevThreeList.length;

    return _classifyDiff(recentThreeAvg - prevThreeAvg);
  }

  static _TrendResult _classifyDiff(double diff) {
    if (diff > 5) {
      return _TrendResult(
        TrendDirection.improving,
        'Your recent scores are trending upward. Keep it up!',
      );
    } else if (diff < -5) {
      return _TrendResult(
        TrendDirection.declining,
        'Your recent scores dipped a bit. Stay consistent and review weak areas.',
      );
    } else {
      return _TrendResult(
        TrendDirection.steady,
        'Your performance is holding steady. Push for improvement!',
      );
    }
  }

  static List<String> _buildFocusAdvice({
    required _TrendResult trend,
    required double latestScore,
    required double avgScore,
    required SavedExamAttempt latest,
    required String? weakestSubject,
    required String? strongestSubject,
    required int attemptCount,
  }) {
    final tips = <String>[];

    if (weakestSubject != null) {
      tips.add('Focus next on $weakestSubject.');
    }

    if (strongestSubject != null) {
      tips.add('Your strongest area recently is $strongestSubject.');
    }

    if (latest.unansweredCount > 0) {
      tips.add(
        'You left ${latest.unansweredCount} item${latest.unansweredCount > 1 ? 's' : ''} unanswered last time. Try to attempt every question.',
      );
    }

    if (latestScore >= 75) {
      tips.add('Great recent score! Try a full-length timed exam next.');
    } else if (latestScore >= 50) {
      tips.add('Solid progress. Review incorrect items and try again.');
    } else {
      tips.add('Keep practicing — focus on one subject at a time.');
    }

    if (attemptCount < 3) {
      tips.add('Take a few more exams to build a clearer trend.');
    }

    return tips;
  }
}

class _TrendResult {
  const _TrendResult(this.direction, this.explanation);
  final TrendDirection direction;
  final String explanation;
}
