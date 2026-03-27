import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/question.dart';

/// State for a single question during practice.
class PracticeQuestionState {
  const PracticeQuestionState({this.selectedAnswer, this.isChecked = false});

  final String? selectedAnswer;
  final bool isChecked;

  bool get isCorrect => false; // Resolved via the question model externally
}

/// Full state for a practice session.
class PracticeSessionState {
  const PracticeSessionState({
    required this.questions,
    this.currentIndex = 0,
    this.questionStates = const {},
  });

  final List<Question> questions;
  final int currentIndex;

  /// Per-question state keyed by questionId.
  final Map<String, PracticeQuestionState> questionStates;

  Question get currentQuestion => questions[currentIndex];
  int get totalQuestions => questions.length;
  bool get isFirst => currentIndex == 0;
  bool get isLast => currentIndex >= questions.length - 1;

  PracticeQuestionState get currentQuestionState =>
      questionStates[currentQuestion.questionId] ??
      const PracticeQuestionState();

  PracticeSessionState copyWith({
    int? currentIndex,
    Map<String, PracticeQuestionState>? questionStates,
  }) {
    return PracticeSessionState(
      questions: questions,
      currentIndex: currentIndex ?? this.currentIndex,
      questionStates: questionStates ?? this.questionStates,
    );
  }
}

class PracticeSessionNotifier extends StateNotifier<PracticeSessionState> {
  PracticeSessionNotifier(List<Question> questions, int startIndex)
    : super(
        PracticeSessionState(questions: questions, currentIndex: startIndex),
      );

  void selectAnswer(String answer) {
    final qState = state.currentQuestionState;
    if (qState.isChecked) return; // Already checked, no changes allowed

    final updated = {
      ...state.questionStates,
      state.currentQuestion.questionId: PracticeQuestionState(
        selectedAnswer: answer,
        isChecked: false,
      ),
    };
    state = state.copyWith(questionStates: updated);
  }

  void checkAnswer() {
    final qState = state.currentQuestionState;
    if (qState.selectedAnswer == null || qState.isChecked) return;

    final updated = {
      ...state.questionStates,
      state.currentQuestion.questionId: PracticeQuestionState(
        selectedAnswer: qState.selectedAnswer,
        isChecked: true,
      ),
    };
    state = state.copyWith(questionStates: updated);
  }

  void goToNext() {
    if (!state.isLast) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void goToPrevious() {
    if (!state.isFirst) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  void goToIndex(int index) {
    if (index >= 0 && index < state.totalQuestions) {
      state = state.copyWith(currentIndex: index);
    }
  }
}

/// Arguments for launching a practice session.
class PracticeSessionArgs {
  const PracticeSessionArgs({required this.questions, this.startIndex = 0});

  final List<Question> questions;
  final int startIndex;
}

/// Provider for the active practice session.
/// Created with [PracticeSessionArgs] when navigating to practice.
final practiceSessionProvider =
    StateNotifierProvider.autoDispose<
      PracticeSessionNotifier,
      PracticeSessionState
    >((ref) {
      // This will be overridden when the practice screen is opened.
      // Default empty state — should never be used directly.
      return PracticeSessionNotifier([], 0);
    });
