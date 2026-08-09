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

  final authListenable = _AuthRefreshListenable(ref);
  ref.onDispose(authListenable.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: authListenable,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final loc = state.matchedLocation;
      final onSplash = loc == AppRoutes.splash;
      final loggingIn = loc == AppRoutes.signIn;

      // Do not mount the shell while auth is unresolved — that caused
      // shell mount/teardown thrash and Duplicate GlobalKey after login.
      if (auth.isLoading) {
        return onSplash ? null : AppRoutes.splash;
      }

      final signedIn = auth.asData?.value != null;

      if (!signedIn) {
        return loggingIn ? null : AppRoutes.signIn;
      }

      if (loggingIn || onSplash) return AppRoutes.home;
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

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this._ref) {
    _subscription = _ref.listen(authStateProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<AuthUser?>> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
