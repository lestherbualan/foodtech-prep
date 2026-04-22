import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../questions/data/choice_randomizer.dart';
import '../../../questions/domain/question.dart';
import '../../domain/exam_models.dart';

/// Status of the timed exam session.
enum ExamStatus { notStarted, inProgress, submitted }

/// State for a timed exam session.
class TimedExamState {
  const TimedExamState({
    required this.questions,
    this.currentIndex = 0,
    this.answers = const {},
    this.remainingSeconds = 0,
    this.totalDurationSeconds = 0,
    this.status = ExamStatus.notStarted,
    this.wasAutoSubmitted = false,
    this.result,
    this.choiceOrders = const {},
    this.displayCorrectAnswers = const {},
    this.mode = 'timed',
  });

  final List<Question> questions;
  final int currentIndex;
  final Map<String, String> answers; // questionId → selected display label
  final int remainingSeconds;
  final int totalDurationSeconds;
  final ExamStatus status;
  final bool wasAutoSubmitted;
  final ExamResult? result;
  final Map<String, List<int>>
  choiceOrders; // questionId → [origOptionIndex0, ...]
  final Map<String, String>
  displayCorrectAnswers; // questionId → display correct label
  final String mode;

  Question get currentQuestion => questions[currentIndex];
  int get totalQuestions => questions.length;
  bool get isFirst => currentIndex == 0;
  bool get isLast => currentIndex >= questions.length - 1;
  bool get isInProgress => status == ExamStatus.inProgress;
  bool get isSubmitted => status == ExamStatus.submitted;
  int get answeredCount => answers.length;
  int get unansweredCount => totalQuestions - answeredCount;

  String? selectedAnswerFor(String questionId) => answers[questionId];

  /// Returns the shuffled display order for the current question.
  List<int> get currentChoiceOrder =>
      choiceOrders[currentQuestion.questionId] ?? [0, 1, 2, 3];

  String get formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  TimedExamState copyWith({
    int? currentIndex,
    Map<String, String>? answers,
    int? remainingSeconds,
    ExamStatus? status,
    bool? wasAutoSubmitted,
    ExamResult? result,
    Map<String, List<int>>? choiceOrders,
    Map<String, String>? displayCorrectAnswers,
  }) {
    return TimedExamState(
      questions: questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalDurationSeconds: totalDurationSeconds,
      status: status ?? this.status,
      wasAutoSubmitted: wasAutoSubmitted ?? this.wasAutoSubmitted,
      result: result ?? this.result,
      choiceOrders: choiceOrders ?? this.choiceOrders,
      displayCorrectAnswers:
          displayCorrectAnswers ?? this.displayCorrectAnswers,
      mode: mode,
    );
  }
}

/// Notifier for a timed exam session with countdown timer.
class TimedExamNotifier extends StateNotifier<TimedExamState> {
  TimedExamNotifier(
    List<Question> questions,
    int durationMinutes, {
    String mode = 'timed',
  }) : super(_initialState(questions, durationMinutes, mode));

  static TimedExamState _initialState(
    List<Question> questions,
    int durationMinutes,
    String mode,
  ) {
    final mappings = generateChoiceMappings(questions);
    return TimedExamState(
      questions: questions,
      remainingSeconds: durationMinutes * 60,
      totalDurationSeconds: durationMinutes * 60,
      choiceOrders: mappings.choiceOrders,
      displayCorrectAnswers: mappings.displayCorrectAnswers,
      mode: mode,
    );
  }

  Timer? _timer;

  void startExam() {
    if (state.status != ExamStatus.notStarted) return;

    state = state.copyWith(status: ExamStatus.inProgress);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
  }

  void _tick() {
    if (!state.isInProgress) return;

    final next = state.remainingSeconds - 1;
    if (next <= 0) {
      _submitExam(autoSubmitted: true);
    } else {
      state = state.copyWith(remainingSeconds: next);
    }
  }

  void selectAnswer(String questionId, String letter) {
    if (!state.isInProgress) return;

    final updated = {...state.answers, questionId: letter};
    state = state.copyWith(answers: updated);
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

  void submitExam() => _submitExam(autoSubmitted: false);

  void _submitExam({required bool autoSubmitted}) {
    _timer?.cancel();
    _timer = null;

    final elapsed = state.totalDurationSeconds - state.remainingSeconds;

    final result = ExamResult.compute(
      questions: state.questions,
      answers: state.answers,
      durationSeconds: elapsed,
      wasAutoSubmitted: autoSubmitted,
      timeLimitSeconds: state.totalDurationSeconds,
      choiceOrders: state.choiceOrders,
      displayCorrectAnswers: state.displayCorrectAnswers,
      mode: state.mode,
    );

    state = state.copyWith(
      status: ExamStatus.submitted,
      wasAutoSubmitted: autoSubmitted,
      remainingSeconds: 0,
      result: result,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provider for the active timed exam session.
final timedExamProvider =
    StateNotifierProvider.autoDispose<TimedExamNotifier, TimedExamState>((ref) {
      // Overridden when navigating to the exam screen.
      return TimedExamNotifier([], 0);
    });
