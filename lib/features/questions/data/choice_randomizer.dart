import 'dart:math';

import '../domain/question.dart';

/// Generates a stable shuffled choice-letter order for each question.
/// Returns `{questionId: ['C', 'A', 'D', 'B'], ...}`.
Map<String, List<String>> generateChoiceOrders(
  List<Question> questions, {
  int? seed,
}) {
  final rng = Random(seed);
  final orders = <String, List<String>>{};

  for (final q in questions) {
    final letters = q.choices.keys.toList()..shuffle(rng);
    orders[q.questionId] = letters;
  }

  return orders;
}
