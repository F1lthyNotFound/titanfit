import 'package:go_router/go_router.dart';

import '../flavor/gym_flavor_service.dart';
import '../screens/account/account_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/membership/membership_screen.dart';
import '../screens/onboarding/flavor_bootstrap_screen.dart';
import '../screens/onboarding/member_onboarding_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/wallet/wallet_screen.dart';

class AppRouter {
  static GoRouter create() {
    final flavorService = GymFlavorService.instance;

    return GoRouter(
      initialLocation: '/bootstrap',
      refreshListenable: flavorService,
      redirect: (context, state) {
        final loc = state.matchedLocation;
        final hasFlavor = flavorService.hasFlavor;
        final loggedIn = flavorService.isLoggedIn;
        final onboarded = flavorService.onboardingComplete;

        if (!hasFlavor && loc != '/bootstrap') {
          return '/bootstrap';
        }
        if (hasFlavor && loc == '/bootstrap') {
          if (!loggedIn) return '/login';
          return onboarded ? '/home' : '/member-onboard';
        }
        if (hasFlavor && loggedIn && !onboarded && loc == '/login') {
          return '/member-onboard';
        }
        if (hasFlavor && loggedIn && !onboarded && _protected(loc) && loc != '/member-onboard') {
          return '/member-onboard';
        }
        if (hasFlavor && loggedIn && onboarded && (loc == '/login' || loc == '/register' || loc == '/member-onboard')) {
          return '/home';
        }
        if (hasFlavor && !loggedIn && _protected(loc)) {
          return '/login';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/bootstrap',
          builder: (_, __) => const FlavorBootstrapScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (_, __) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/member-onboard',
          builder: (_, __) => const MemberOnboardingScreen(),
        ),
        GoRoute(
          path: '/wallet',
          builder: (_, __) => const WalletScreen(),
        ),
        GoRoute(
          path: '/membership',
          builder: (_, __) => const MembershipScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (_, __) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/history',
                  builder: (_, __) => const HistoryScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/account',
                  builder: (_, __) => const AccountScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static bool _protected(String loc) {
    return loc.startsWith('/home') ||
        loc.startsWith('/history') ||
        loc.startsWith('/account') ||
        loc.startsWith('/wallet') ||
        loc.startsWith('/membership');
  }
}
