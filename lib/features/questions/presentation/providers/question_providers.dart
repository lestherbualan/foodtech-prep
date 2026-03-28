import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/firestore_question_repository.dart';
import '../../data/local_question_repository.dart';
import '../../data/question_repository.dart';
import '../../domain/question.dart';

/// Firestore-backed repository (primary source).
final firestoreQuestionRepositoryProvider =
    Provider<FirestoreQuestionRepository>((ref) {
      return FirestoreQuestionRepository();
    });

/// Local JSON repository (fallback / dev source).
final localQuestionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return LocalQuestionRepository();
});

/// Main question repository — defaults to Firestore.
final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return ref.watch(firestoreQuestionRepositoryProvider);
});

/// Loads questions from Firestore, falling back to local JSON on failure.
final questionsProvider = FutureProvider<List<Question>>((ref) async {
  try {
    final questions = await ref
        .watch(firestoreQuestionRepositoryProvider)
        .loadQuestions();
    if (questions.isNotEmpty) return questions;
  } catch (e) {
    debugPrint('Firestore load failed, falling back to local JSON: $e');
  }
  return ref.watch(localQuestionRepositoryProvider).loadQuestions();
});

final questionsBySubjectProvider =
    FutureProvider.family<List<Question>, String>((ref, subjectId) async {
      final all = await ref.watch(questionsProvider.future);
      return all.where((q) => q.subjectId == subjectId).toList();
    });
