import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/exam/domain/exam_models.dart';
import '../../features/exam/presentation/providers/timed_exam_provider.dart';
import '../../features/exam/presentation/screens/exam_history_screen.dart';
import '../../features/exam/presentation/screens/dashboard_screen.dart';
import '../../features/exam/domain/saved_exam_attempt.dart';
import '../../features/exam/presentation/screens/attempt_detail_screen.dart';
import '../../features/exam/presentation/screens/exam_result_screen.dart';
import '../../features/exam/presentation/screens/exam_review_screen.dart';
import '../../features/exam/presentation/screens/exam_setup_screen.dart';
import '../../features/exam/presentation/screens/subject_breakdown_screen.dart';
import '../../features/exam/presentation/screens/timed_exam_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/onboarding/presentation/screens/welcome_screen.dart';
import '../../features/questions/domain/question.dart';
import '../../features/questions/presentation/providers/practice_session_provider.dart';
import '../../features/questions/presentation/screens/practice_question_screen.dart';
import '../../features/questions/presentation/screens/question_bank_screen.dart';
import '../../features/questions/presentation/screens/question_bank_subject_screen.dart';
import '../../features/questions/presentation/screens/question_detail_screen.dart';
import '../../features/questions/presentation/screens/subject_practice_screen.dart';
import '../../features/questions/presentation/screens/weak_areas_screen.dart';
import 'route_names.dart';

/// Notifier that triggers GoRouter redirect re-evaluation when auth state changes.
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<User?>>(authStateProvider, (_, _) {
      notifyListeners();
    });
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);
    final currentPath = state.matchedLocation;
    final isOnSplash = currentPath == RouteNames.splash;
    final isOnAuthRoute =
        currentPath == RouteNames.login || currentPath == RouteNames.welcome;

    // While loading auth state, stay on splash
    if (authState.isLoading) {
      return isOnSplash ? null : RouteNames.splash;
    }

    final user = authState.valueOrNull;

    // Not authenticated → send to welcome (unless already on auth route)
    if (user == null) {
      return isOnAuthRoute ? null : RouteNames.welcome;
    }

    // Authenticated → send to home (if still on splash or auth route)
    if (isOnSplash || isOnAuthRoute) {
      return RouteNames.home;
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: RouteNames.splash,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteNames.questionBank,
        builder: (context, state) => const QuestionBankScreen(),
      ),
      GoRoute(
        path: RouteNames.questionDetail,
        builder: (context, state) {
          final question = state.extra! as Question;
          return QuestionDetailScreen(question: question);
        },
      ),
      GoRoute(
        path: RouteNames.practice,
        builder: (context, state) {
          final args = state.extra! as PracticeSessionArgs;
          return ProviderScope(
            overrides: [
              practiceSessionProvider.overrideWith(
                (ref) =>
                    PracticeSessionNotifier(args.questions, args.startIndex),
              ),
            ],
            child: const PracticeQuestionScreen(),
          );
        },
      ),
      GoRoute(
        path: RouteNames.examSetup,
        builder: (context, state) => const ExamSetupScreen(),
      ),
      GoRoute(
        path: RouteNames.timedExam,
        builder: (context, state) {
          final args = state.extra! as TimedExamArgs;
          return ProviderScope(
            overrides: [
              timedExamProvider.overrideWith(
                (ref) =>
                    TimedExamNotifier(args.questions, args.durationMinutes),
              ),
            ],
            child: const TimedExamScreen(),
          );
        },
      ),
      GoRoute(
        path: RouteNames.examResult,
        builder: (context, state) {
          final result = state.extra! as ExamResult;
          return ExamResultScreen(result: result);
        },
      ),
      GoRoute(
        path: RouteNames.examReview,
        builder: (context, state) {
          final result = state.extra! as ExamResult;
          return ExamReviewScreen(result: result);
        },
      ),
      GoRoute(
        path: RouteNames.examHistory,
        builder: (context, state) => const ExamHistoryScreen(),
      ),
      GoRoute(
        path: RouteNames.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.subjectPractice,
        builder: (context, state) => const SubjectPracticeScreen(),
      ),
      GoRoute(
        path: RouteNames.weakAreas,
        builder: (context, state) => const WeakAreasScreen(),
      ),
      GoRoute(
        path: RouteNames.subjectBreakdown,
        builder: (context, state) => const SubjectBreakdownScreen(),
      ),
      GoRoute(
        path: RouteNames.questionBankSubject,
        builder: (context, state) {
          final subjectId = state.extra! as String;
          return QuestionBankSubjectScreen(subjectId: subjectId);
        },
      ),
      GoRoute(
        path: RouteNames.attemptDetail,
        builder: (context, state) {
          final attempt = state.extra! as SavedExamAttempt;
          return AttemptDetailScreen(attempt: attempt);
        },
      ),
      GoRoute(
        path: RouteNames.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
