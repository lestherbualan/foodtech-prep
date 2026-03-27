import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/question.dart';
import 'question_repository.dart';

class LocalQuestionRepository implements QuestionRepository {
  LocalQuestionRepository({
    this.assetPath =
        'assets/data/questions/foodtech-prep-starter-question-bank-batch-1.json',
  });

  final String assetPath;

  List<Question>? _cachedQuestions;

  @override
  Future<List<Question>> loadQuestions() async {
    if (_cachedQuestions != null) return _cachedQuestions!;

    final jsonString = await rootBundle.loadString(assetPath);
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

    _cachedQuestions = jsonList
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();

    return _cachedQuestions!;
  }

  @override
  Future<List<Question>> loadQuestionsBySubject(String subjectId) async {
    final all = await loadQuestions();
    return all.where((q) => q.subjectId == subjectId).toList();
  }
}
