import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/chamatkar/presentation/chamatkar_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/posters/presentation/posters_screen.dart';
import '../../features/premium/presentation/feature_screens.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/story/presentation/story_screen.dart';
import '../../features/subscription/presentation/paywall_screen.dart';
import '../config/app_features.dart';
import 'app_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authListenable = _AuthRefreshListenable(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    refreshListenable: authListenable,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final loggingIn = state.matchedLocation == AppRoutes.signIn;

      if (auth.isLoading) return null;

      final user = auth.asData?.value;
      final signedIn = user != null;

      if (!signedIn && !loggingIn) return AppRoutes.signIn;
      if (signedIn && loggingIn) return AppRoutes.home;
      return null;
    },
    routes: [
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
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.story,
                builder: (context, state) => const StoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chamatkar,
                builder: (context, state) => const ChamatkarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.posters,
                builder: (context, state) => const PostersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.paywall,
                builder: (context, state) => const PaywallScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
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
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}
