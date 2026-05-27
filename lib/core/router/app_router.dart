import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_flow_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/main_shell_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/surah_mastery/screens/surah_list_screen.dart';
import '../../features/surah_mastery/screens/surah_detail_screen.dart';
import '../../features/surah_mastery/screens/quiz_screen.dart';
import '../../features/surah_mastery/screens/surah_reader_screen.dart';
import '../../features/audio_stories/screens/stories_list_screen.dart';
import '../../features/audio_stories/screens/audio_player_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/practice/screens/practice_screen.dart';
import '../../features/subscription/screens/renewal_paywall_screen.dart';

/// App route paths
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const surahs = '/surahs';
  static const surahDetail = '/surah/:id';
  static const quiz = '/quiz/:surahId';
  static const stories = '/stories';
  static const player = '/player/:id';
  static const profile = '/profile';
  static const practice = '/practice';
  static const practiceQuiz = '/practice-quiz/:category';
  static const dailyChallenge = '/daily-challenge';
  static const surahReader = '/surah/:id/read';
  static const renew = '/renew';
}

/// Smooth fade transition for all top-level navigation.
CustomTransitionPage<T> _fadePage<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
        child: child,
      );
    },
  );
}

/// Main app router configuration
final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (context, state) => _fadePage(state, const SplashScreen()),
    ),

    GoRoute(
      path: AppRoutes.login,
      pageBuilder: (context, state) => _fadePage(state, const LoginScreen()),
    ),

    GoRoute(
      path: AppRoutes.onboarding,
      pageBuilder: (context, state) =>
          _fadePage(state, const OnboardingFlowScreen()),
    ),

    GoRoute(
      path: AppRoutes.renew,
      pageBuilder: (context, state) =>
          _fadePage(state, const RenewalPaywallScreen()),
    ),

    // Main Shell with Bottom Navigation
    ShellRoute(
      builder: (context, state, child) => MainShellScreen(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.surahs,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SurahListScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.stories,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: StoriesListScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.profile,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.practice,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PracticeScreen(),
          ),
        ),
      ],
    ),

    GoRoute(
      path: AppRoutes.surahDetail,
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        return _fadePage(state, SurahDetailScreen(surahId: int.parse(id)));
      },
    ),
    GoRoute(
      path: AppRoutes.quiz,
      pageBuilder: (context, state) {
        final surahId = state.pathParameters['surahId']!;
        return _fadePage(state, QuizScreen(surahId: int.parse(surahId)));
      },
    ),

    GoRoute(
      path: AppRoutes.surahReader,
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        final name = (state.extra as String?) ?? 'Surah';
        return _fadePage(
          state,
          SurahReaderScreen(surahId: int.parse(id), surahName: name),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.player,
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        return _fadePage(state, AudioPlayerScreen(storyId: id));
      },
    ),

    GoRoute(
      path: AppRoutes.dailyChallenge,
      pageBuilder: (context, state) =>
          _fadePage(state, const QuizScreen(surahId: 0)),
    ),

    GoRoute(
      path: AppRoutes.practiceQuiz,
      pageBuilder: (context, state) {
        final category = state.pathParameters['category']!;
        return _fadePage(state, QuizScreen(surahId: 0, category: category));
      },
    ),
  ],
);
