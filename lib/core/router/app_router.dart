import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/ui/auth_providers.dart';
import '../../features/auth/ui/reset_password_screen.dart';
import '../../features/auth/ui/sign_in_screen.dart';
import '../../features/auth/ui/sign_up_screen.dart';
import '../../features/home/ui/home_screen.dart';

const _authRoutes = {'/sign-in', '/sign-up', '/reset-password'};

/// Built once. Auth changes only re-run [GoRouter.redirect] (via
/// [_AuthRefresh]), so the navigation stack isn't thrown away.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      // After Firebase.initializeApp the persisted user is available
      // synchronously on Android, so there's no signed-out flash on start.
      final isSignedIn = ref.read(authRepositoryProvider).currentUser != null;
      final isAuthRoute = _authRoutes.contains(state.matchedLocation);

      if (!isSignedIn && !isAuthRoute) return '/sign-in';
      if (isSignedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    ],
  );
});

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authStateChangesProvider, (_, _) => notifyListeners());
  }
}
