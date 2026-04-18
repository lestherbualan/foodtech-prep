import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/question.dart';
import '../domain/question_bank.dart';
import 'question_repository.dart';

/// Reads questions from the active Firestore question bank.
class FirestoreQuestionRepository implements QuestionRepository {
  FirestoreQuestionRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  List<Question>? _cachedQuestions;
  QuestionBank? _cachedBank;

  CollectionReference<Map<String, dynamic>> get _bankCollection =>
      _firestore.collection('questionBanks');

  /// Finds the first active question bank.
  Future<QuestionBank> loadActiveBank() async {
    if (_cachedBank != null) return _cachedBank!;

    final snapshot = await _bankCollection
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('No active question bank found in Firestore.');
    }

    final doc = snapshot.docs.first;
    _cachedBank = QuestionBank.fromFirestore(doc.id, doc.data());
    debugPrint(
      'Active bank: ${_cachedBank!.id} '
      '(${_cachedBank!.questionCount} questions, v${_cachedBank!.version})',
    );
    return _cachedBank!;
  }

  @override
  Future<List<Question>> loadQuestions() async {
    if (_cachedQuestions != null) return _cachedQuestions!;

    final bank = await loadActiveBank();

    final snapshot = await _bankCollection
        .doc(bank.id)
        .collection('questions')
        .get();

    _cachedQuestions = snapshot.docs
        .map((doc) => Question.fromFirestore(doc.id, doc.data()))
        .toList();

    debugPrint('Loaded ${_cachedQuestions!.length} questions from Firestore.');
    return _cachedQuestions!;
  }

  @override
  Future<List<Question>> loadQuestionsBySubject(String subjectId) async {
    final all = await loadQuestions();
    return all.where((q) => q.subjectId == subjectId).toList();
  }

  /// Clears the in-memory cache so the next load fetches fresh data.
  void clearCache() {
    _cachedQuestions = null;
    _cachedBank = null;
  }

  /// Returns the active bank ID (loading it first if needed).
  Future<String> getActiveBankId() async {
    final bank = await loadActiveBank();
    return bank.id;
  }

  /// Updates a question document in the active bank.
  Future<void> updateQuestion(
    String questionId,
    Map<String, dynamic> data,
  ) async {
    final bank = await loadActiveBank();
    await _bankCollection
        .doc(bank.id)
        .collection('questions')
        .doc(questionId)
        .update(data);
    // Invalidate cache so next load picks up the change.
    _cachedQuestions = null;
    debugPrint('Updated question $questionId in bank ${bank.id}');
  }
}
