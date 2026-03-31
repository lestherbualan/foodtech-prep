import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/choice_randomizer.dart';
import '../../domain/question.dart';

/// State for a single question during practice.
class PracticeQuestionState {
  const PracticeQuestionState({
    this.selectedAnswer,
    this.isChecked = false,
    this.isCorrect = false,
  });

  final String? selectedAnswer;
  final bool isChecked;
  final bool isCorrect;
}

/// Full state for a practice session.
class PracticeSessionState {
  const PracticeSessionState({
    required this.questions,
    this.currentIndex = 0,
    this.questionStates = const {},
    this.choiceOrders = const {},
    this.displayCorrectAnswers = const {},
  });

  final List<Question> questions;
  final int currentIndex;

  /// Per-question state keyed by questionId.
  final Map<String, PracticeQuestionState> questionStates;

  /// Stable shuffled choice order per question (display position → original option index).
  final Map<String, List<int>> choiceOrders;

  /// Display-level correct answer per question after shuffle.
  final Map<String, String> displayCorrectAnswers;

  Question get currentQuestion => questions[currentIndex];
  int get totalQuestions => questions.length;
  bool get isFirst => currentIndex == 0;
  bool get isLast => currentIndex >= questions.length - 1;

  PracticeQuestionState get currentQuestionState =>
      questionStates[currentQuestion.questionId] ??
      const PracticeQuestionState();

  /// Returns the shuffled display order for the current question.
  List<int> get currentChoiceOrder =>
      choiceOrders[currentQuestion.questionId] ?? [0, 1, 2, 3];

  /// Display-level correct answer for the current question.
  String get currentDisplayCorrectAnswer =>
      displayCorrectAnswers[currentQuestion.questionId] ??
      currentQuestion.correctAnswerLabel;

  PracticeSessionState copyWith({
    int? currentIndex,
    Map<String, PracticeQuestionState>? questionStates,
    Map<String, List<int>>? choiceOrders,
    Map<String, String>? displayCorrectAnswers,
  }) {
    return PracticeSessionState(
      questions: questions,
      currentIndex: currentIndex ?? this.currentIndex,
      questionStates: questionStates ?? this.questionStates,
      choiceOrders: choiceOrders ?? this.choiceOrders,
      displayCorrectAnswers:
          displayCorrectAnswers ?? this.displayCorrectAnswers,
    );
  }
}

class PracticeSessionNotifier extends StateNotifier<PracticeSessionState> {
  PracticeSessionNotifier(List<Question> questions, int startIndex)
    : super(_initialState(questions, startIndex));

  static PracticeSessionState _initialState(
    List<Question> questions,
    int startIndex,
  ) {
    final mappings = generateChoiceMappings(questions);
    return PracticeSessionState(
      questions: questions,
      currentIndex: startIndex,
      choiceOrders: mappings.choiceOrders,
      displayCorrectAnswers: mappings.displayCorrectAnswers,
    );
  }

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

    final correct = qState.selectedAnswer == state.currentDisplayCorrectAnswer;
    final updated = {
      ...state.questionStates,
      state.currentQuestion.questionId: PracticeQuestionState(
        selectedAnswer: qState.selectedAnswer,
        isChecked: true,
        isCorrect: correct,
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
