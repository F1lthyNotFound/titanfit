import 'package:go_router/go_router.dart';

import '../flavor/gym_flavor_service.dart';
import '../screens/account/account_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/bookings/bookings_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/onboarding/gym_select_screen.dart';
import '../screens/onboarding/member_onboarding_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/wallet/wallet_screen.dart';

class AppRouter {
  static GoRouter create() {
    final flavorService = GymFlavorService.instance;

    return GoRouter(
      initialLocation: '/onboard',
      refreshListenable: flavorService,
      redirect: (context, state) {
        final loc = state.matchedLocation;
        final hasFlavor = flavorService.hasFlavor;
        final loggedIn = flavorService.isLoggedIn;
        final onboarded = flavorService.onboardingComplete;

        if (!hasFlavor && !loc.startsWith('/onboard')) {
          return '/onboard';
        }
        if (hasFlavor && loc == '/onboard') {
          if (!loggedIn) return '/login';
          return onboarded ? '/home' : '/member-onboard';
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
          path: '/onboard',
          builder: (_, __) => const GymSelectScreen(),
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
          path: '/member-onboard',
          builder: (_, __) => const MemberOnboardingScreen(),
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
                  path: '/bookings',
                  builder: (_, __) => const BookingsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/wallet',
                  builder: (_, __) => const WalletScreen(),
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
        loc.startsWith('/bookings') ||
        loc.startsWith('/wallet') ||
        loc.startsWith('/account');
  }
}
