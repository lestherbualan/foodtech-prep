import '../domain/question.dart';

/// Abstraction for loading questions from any source.
abstract class QuestionRepository {
  Future<List<Question>> loadQuestions();
  Future<List<Question>> loadQuestionsBySubject(String subjectId);
}
