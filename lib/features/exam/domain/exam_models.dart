import '../../questions/domain/question.dart';

/// Configuration for starting a timed exam.
class ExamConfig {
  const ExamConfig({
    required this.durationMinutes,
    required this.questionCount,
  });

  final int durationMinutes;
  final int questionCount;

  /// Default exam config for the current phase.
  static const defaultConfig = ExamConfig(
    durationMinutes: 40,
    questionCount: 60,
  );
}

/// Arguments passed when navigating to the timed exam screen.
class TimedExamArgs {
  const TimedExamArgs({required this.questions, required this.durationMinutes});

  final List<Question> questions;
  final int durationMinutes;
}

/// The result of a completed timed exam.
class ExamResult {
  const ExamResult({
    required this.totalQuestions,
    required this.answeredCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.unansweredCount,
    required this.scorePercent,
    required this.durationSeconds,
    required this.wasAutoSubmitted,
    required this.questions,
    required this.answers,
    this.timeLimitSeconds,
    this.choiceOrders = const {},
    this.displayCorrectAnswers = const {},
  });

  final int totalQuestions;
  final int answeredCount;
  final int correctCount;
  final int incorrectCount;
  final int unansweredCount;
  final double scorePercent;
  final int durationSeconds;
  final bool wasAutoSubmitted;
  final List<Question> questions;
  final Map<String, String> answers; // questionId → selected display label
  final int? timeLimitSeconds;
  final Map<String, List<int>> choiceOrders;
  final Map<String, String> displayCorrectAnswers;

  factory ExamResult.compute({
    required List<Question> questions,
    required Map<String, String> answers,
    required int durationSeconds,
    required bool wasAutoSubmitted,
    int? timeLimitSeconds,
    Map<String, List<int>> choiceOrders = const {},
    Map<String, String> displayCorrectAnswers = const {},
  }) {
    int correct = 0;
    int incorrect = 0;
    int unanswered = 0;

    for (final q in questions) {
      final selected = answers[q.questionId];
      final correctAnswer =
          displayCorrectAnswers[q.questionId] ?? q.correctAnswerLabel;
      if (selected == null) {
        unanswered++;
      } else if (selected == correctAnswer) {
        correct++;
      } else {
        incorrect++;
      }
    }

    final total = questions.length;
    final percent = total > 0 ? (correct / total) * 100 : 0.0;

    return ExamResult(
      totalQuestions: total,
      answeredCount: correct + incorrect,
      correctCount: correct,
      incorrectCount: incorrect,
      unansweredCount: unanswered,
      scorePercent: percent,
      durationSeconds: durationSeconds,
      wasAutoSubmitted: wasAutoSubmitted,
      questions: questions,
      answers: answers,
      timeLimitSeconds: timeLimitSeconds,
      choiceOrders: choiceOrders,
      displayCorrectAnswers: displayCorrectAnswers,
    );
  }

  /// Computes a subject-based performance breakdown from this result.
  ExamPerformanceBreakdown get performanceBreakdown =>
      ExamPerformanceBreakdown.fromResult(this);

  /// Questions the user answered incorrectly.
  List<Question> get incorrectQuestions => questions.where((q) {
    final sel = answers[q.questionId];
    final correct = displayCorrectAnswers[q.questionId] ?? q.correctAnswerLabel;
    return sel != null && sel != correct;
  }).toList();

  /// Questions the user did not answer.
  List<Question> get unansweredQuestions =>
      questions.where((q) => answers[q.questionId] == null).toList();
}

// ─── Subject-level performance ───────────────────────────────────────────────

/// Performance statistics for a single subject within an exam attempt.
class SubjectPerformance {
  const SubjectPerformance({
    required this.subjectName,
    required this.total,
    required this.correct,
    required this.incorrect,
    required this.unanswered,
  });

  final String subjectName;
  final int total;
  final int correct;
  final int incorrect;
  final int unanswered;

  double get scorePercent => total > 0 ? (correct / total) * 100 : 0.0;
}

/// Aggregated performance breakdown across all subjects in an exam attempt.
class ExamPerformanceBreakdown {
  const ExamPerformanceBreakdown({required this.subjects});

  final List<SubjectPerformance> subjects;

  /// Strongest subject by score%, tie-broken by higher total, then alphabetical.
  SubjectPerformance? get strongest =>
      subjects.isEmpty ? null : _sorted().first;

  /// Weakest subject by score%, tie-broken by higher total (more weight), then alphabetical.
  SubjectPerformance? get weakest => subjects.isEmpty ? null : _sorted().last;

  List<SubjectPerformance> _sorted() {
    final sorted = List<SubjectPerformance>.from(subjects);
    sorted.sort((a, b) {
      final cmp = b.scorePercent.compareTo(a.scorePercent);
      if (cmp != 0) return cmp;
      final totalCmp = b.total.compareTo(a.total);
      if (totalCmp != 0) return totalCmp;
      return a.subjectName.compareTo(b.subjectName);
    });
    return sorted;
  }

  factory ExamPerformanceBreakdown.fromResult(ExamResult result) {
    final Map<String, _SubjectAccumulator> accumulators = {};

    for (final q in result.questions) {
      final acc = accumulators.putIfAbsent(
        q.subjectName,
        () => _SubjectAccumulator(q.subjectName),
      );
      final selected = result.answers[q.questionId];
      final correctAnswer =
          result.displayCorrectAnswers[q.questionId] ?? q.correctAnswerLabel;
      if (selected == null) {
        acc.unanswered++;
      } else if (selected == correctAnswer) {
        acc.correct++;
      } else {
        acc.incorrect++;
      }
    }

    final subjects =
        accumulators.values
            .map(
              (a) => SubjectPerformance(
                subjectName: a.subjectName,
                total: a.correct + a.incorrect + a.unanswered,
                correct: a.correct,
                incorrect: a.incorrect,
                unanswered: a.unanswered,
              ),
            )
            .toList()
          ..sort((a, b) => b.scorePercent.compareTo(a.scorePercent));

    return ExamPerformanceBreakdown(subjects: subjects);
  }
}

class _SubjectAccumulator {
  _SubjectAccumulator(this.subjectName);
  final String subjectName;
  int correct = 0;
  int incorrect = 0;
  int unanswered = 0;
}
