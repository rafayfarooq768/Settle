import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/ui/auth_providers.dart';
import '../../features/auth/ui/reset_password_screen.dart';
import '../../features/auth/ui/sign_in_screen.dart';
import '../../features/auth/ui/sign_up_screen.dart';
import '../../features/groups/ui/create_group_screen.dart';
import '../../features/groups/ui/group_screen.dart';
import '../../features/groups/ui/group_settings_screen.dart';
import '../../features/groups/ui/invite_screen.dart';
import '../../features/groups/ui/join_screen.dart';
import '../../features/groups/ui/scan_code_screen.dart';
import '../../features/home/ui/home_screen.dart';
import '../../features/profile/ui/change_password_screen.dart';
import '../../features/profile/ui/payment_method_screen.dart';
import '../../features/profile/ui/settings_screen.dart';
import '../../features/activity/ui/activity_screen.dart';
import '../../features/expenses/ui/add_expense_screen.dart';
import '../../features/expenses/ui/expense_detail_screen.dart';
import '../../features/expenses/ui/expense_search_screen.dart';
import '../../features/expenses/ui/items_screen.dart';
import '../../features/expenses/ui/payers_screen.dart';
import '../../features/expenses/ui/split_screen.dart';

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
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'password',
            builder: (context, state) => const ChangePasswordScreen(),
          ),
          GoRoute(
            path: 'payment-methods/new',
            builder: (context, state) => const PaymentMethodScreen(),
          ),
          GoRoute(
            path: 'payment-methods/:methodId',
            builder: (context, state) =>
                PaymentMethodScreen(methodId: state.pathParameters['methodId']),
          ),
        ],
      ),
      GoRoute(
        path: '/groups/new',
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/groups/:id',
        builder: (context, state) =>
            GroupScreen(groupId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'settings',
            builder: (context, state) =>
                GroupSettingsScreen(groupId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'expenses/new',
            builder: (context, state) =>
                AddExpenseScreen(groupId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'expenses/:expenseId',
            builder: (context, state) => ExpenseDetailScreen(
              groupId: state.pathParameters['id']!,
              expenseId: state.pathParameters['expenseId']!,
            ),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => AddExpenseScreen(
                  groupId: state.pathParameters['id']!,
                  expenseId: state.pathParameters['expenseId'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'search',
            builder: (context, state) =>
                ExpenseSearchScreen(groupId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'activity',
            builder: (context, state) =>
                ActivityScreen(groupId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'split',
            builder: (context, state) => switch (state.extra) {
              final SplitArgs args => SplitScreen(
                groupId: state.pathParameters['id']!,
                args: args,
              ),
              // Opened without its arguments (e.g. restored after the app
              // was killed): go back to the group.
              _ => GroupScreen(groupId: state.pathParameters['id']!),
            },
          ),
          GoRoute(
            path: 'payers',
            builder: (context, state) => switch (state.extra) {
              final PayersArgs args => PayersScreen(
                groupId: state.pathParameters['id']!,
                args: args,
              ),
              _ => GroupScreen(groupId: state.pathParameters['id']!),
            },
          ),
          GoRoute(
            path: 'items',
            builder: (context, state) => switch (state.extra) {
              final ItemsArgs args => ItemsScreen(
                groupId: state.pathParameters['id']!,
                args: args,
              ),
              _ => GroupScreen(groupId: state.pathParameters['id']!),
            },
          ),
          GoRoute(
            path: 'invite',
            builder: (context, state) =>
                InviteScreen(groupId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/join',
        builder: (context, state) => const JoinScreen(),
        routes: [
          GoRoute(
            path: 'scan',
            builder: (context, state) => const ScanCodeScreen(),
          ),
        ],
      ),
    ],
  );
});

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(userChangesProvider, (_, _) => notifyListeners());
  }
}
