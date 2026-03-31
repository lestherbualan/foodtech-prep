import 'dart:math';

import '../domain/question.dart';

/// Fixed display labels for answer choices.
const kDisplayLabels = ['A', 'B', 'C', 'D'];

/// Generates stable display mappings for shuffled choices.
///
/// [choiceOrders]: `{questionId: [origOptionIndex0, origOptionIndex1, ...]}`.
///   Display slot 0 (label A) shows `options[choiceOrders[qId][0]]`, etc.
/// [displayCorrectAnswers]: `{questionId: displayLabel}` — which display
///   label (A/B/C/D) holds the correct option after shuffle.
({
  Map<String, List<int>> choiceOrders,
  Map<String, String> displayCorrectAnswers,
})
generateChoiceMappings(List<Question> questions, {int? seed}) {
  final rng = Random(seed);
  final choiceOrders = <String, List<int>>{};
  final displayCorrectAnswers = <String, String>{};

  for (final q in questions) {
    final indices = List.generate(q.options.length, (i) => i)..shuffle(rng);
    choiceOrders[q.questionId] = indices;

    // Which display position received the correct option?
    for (var displayIdx = 0; displayIdx < indices.length; displayIdx++) {
      if (q.options[indices[displayIdx]].isCorrect) {
        displayCorrectAnswers[q.questionId] = kDisplayLabels[displayIdx];
        break;
      }
    }
  }

  return (
    choiceOrders: choiceOrders,
    displayCorrectAnswers: displayCorrectAnswers,
  );
}
