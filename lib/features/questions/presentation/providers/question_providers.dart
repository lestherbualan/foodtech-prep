import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local_question_repository.dart';
import '../../data/question_repository.dart';
import '../../domain/question.dart';

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return LocalQuestionRepository();
});

final questionsProvider = FutureProvider<List<Question>>((ref) {
  return ref.watch(questionRepositoryProvider).loadQuestions();
});

final questionsBySubjectProvider =
    FutureProvider.family<List<Question>, String>((ref, subjectId) {
      return ref
          .watch(questionRepositoryProvider)
          .loadQuestionsBySubject(subjectId);
    });
