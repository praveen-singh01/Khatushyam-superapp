import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_user.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/chamatkar/presentation/chamatkar_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/posters/presentation/posters_screen.dart';
import '../../features/premium/presentation/feature_screens.dart';
import '../../features/profile/domain/app_profile.dart';
import '../../features/profile/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_providers.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/story/presentation/story_screen.dart';
import '../../features/subscription/presentation/paywall_screen.dart';
import '../config/app_features.dart';
import '../theme/app_colors.dart';
import 'app_routes.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
  final storyNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'story');
  final chamatkarNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'chamatkar',
  );
  final postersNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'posters');
  final profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

  final refresh = _RouterRefreshListenable(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final loc = state.matchedLocation;
      final onSplash = loc == AppRoutes.splash;
      final loggingIn = loc == AppRoutes.signIn;
      final onboarding = loc == AppRoutes.onboarding;

      if (auth.isLoading) {
        return onSplash ? null : AppRoutes.splash;
      }

      final signedIn = auth.asData?.value != null;
      if (!signedIn) {
        return loggingIn ? null : AppRoutes.signIn;
      }

      final profileAsync = ref.read(appProfileProvider);
      if (profileAsync.isLoading) {
        return onSplash ? null : AppRoutes.splash;
      }

      final profile = profileAsync.asData?.value;
      final needsOnboarding = profile?.onboardingCompleted != true;

      if (needsOnboarding) {
        return onboarding ? null : AppRoutes.onboarding;
      }

      if (onboarding || loggingIn || onSplash) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder:
            (context, state) => const Scaffold(
              backgroundColor: AppColors.canvas,
              body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: homeNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: storyNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.story,
                builder: (context, state) => const StoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: chamatkarNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.chamatkar,
                builder: (context, state) => const ChamatkarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: postersNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.posters,
                builder: (context, state) => const PostersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: profileNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.paywall,
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.feature,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final feature = AppFeatureAccess.fromRouteSegment(id);
          return FeatureHostScreen(feature: feature);
        },
      ),
    ],
  );
});

class _RouterRefreshListenable extends ChangeNotifier {
  _RouterRefreshListenable(this._ref) {
    _authSub = _ref.listen<AsyncValue<AuthUser?>>(authStateProvider, (_, __) {
      notifyListeners();
    });
    _profileSub = _ref.listen<AsyncValue<AppProfile?>>(appProfileProvider, (
      _,
      __,
    ) {
      notifyListeners();
    });
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<AuthUser?>> _authSub;
  late final ProviderSubscription<AsyncValue<AppProfile?>> _profileSub;

  @override
  void dispose() {
    _authSub.close();
    _profileSub.close();
    super.dispose();
  }
}
