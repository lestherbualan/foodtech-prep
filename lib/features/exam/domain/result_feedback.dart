import 'exam_models.dart';

/// Score-aware feedback for the result screen.
class ResultFeedback {
  const ResultFeedback({required this.headline, required this.subtitle});

  final String headline;
  final String subtitle;

  factory ResultFeedback.from(ExamResult result) {
    final pct = result.scorePercent;

    if (pct >= 85) {
      return const ResultFeedback(
        headline: 'Excellent Work!',
        subtitle: 'You have a strong command of this material.',
      );
    }
    if (pct >= 70) {
      return const ResultFeedback(
        headline: 'Great Job!',
        subtitle: 'Solid performance — just a few areas to sharpen.',
      );
    }
    if (pct >= 50) {
      return const ResultFeedback(
        headline: 'Good Effort!',
        subtitle: 'You\'re on the right track. Review the topics you missed.',
      );
    }
    if (pct >= 30) {
      return const ResultFeedback(
        headline: 'Keep Going!',
        subtitle: 'Focus on your weak subjects and try again.',
      );
    }
    return const ResultFeedback(
      headline: 'Keep Practicing!',
      subtitle: 'Every attempt helps you improve. Review and retry.',
    );
  }
}

/// Generates concise, actionable study tips from the exam result.
List<String> buildStudyGuidance(ExamResult result) {
  final tips = <String>[];
  final breakdown = result.performanceBreakdown;

  // Weakest subject tip
  if (breakdown.subjects.length >= 2) {
    final weakest = breakdown.weakest!;
    tips.add(
      'Focus next on ${weakest.subjectName} '
      '(${weakest.scorePercent.round()}% score).',
    );
  }

  // Subject with most incorrect
  final subjectsWithErrors =
      breakdown.subjects.where((s) => s.incorrect > 0).toList()
        ..sort((a, b) => b.incorrect.compareTo(a.incorrect));
  if (subjectsWithErrors.isNotEmpty) {
    final worst = subjectsWithErrors.first;
    if (breakdown.weakest == null ||
        worst.subjectName != breakdown.weakest!.subjectName) {
      tips.add(
        'You had ${worst.incorrect} incorrect '
        '${worst.incorrect == 1 ? 'answer' : 'answers'} '
        'in ${worst.subjectName}.',
      );
    }
  }

  // Unanswered emphasis
  if (result.unansweredCount > 0) {
    tips.add(
      'You left ${result.unansweredCount} '
      '${result.unansweredCount == 1 ? 'question' : 'questions'} '
      'unanswered — completing all items can boost your score.',
    );
  }

  // Strongest subject encouragement
  if (breakdown.subjects.length >= 2) {
    final strongest = breakdown.strongest!;
    if (strongest.scorePercent >= 70) {
      tips.add('Great work in ${strongest.subjectName} — keep it up!');
    }
  }

  return tips;
}
