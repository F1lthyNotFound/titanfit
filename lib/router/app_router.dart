import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../flavor/gym_flavor_service.dart';
import '../screens/account/id_submission_screen.dart';
import '../screens/account/account_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/bookings/bookings_screen.dart';
import '../screens/bookings/appointment_flow_screen.dart';
import '../screens/branch/branch_screen.dart';
import '../screens/membership/membership_screen.dart';
import '../screens/onboarding/flavor_bootstrap_screen.dart';
import '../screens/onboarding/member_onboarding_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/wallet/wallet_screen.dart';

class AppRouter {
  static CustomTransitionPage<void> _fadeSlide(Widget child) {
    return CustomTransitionPage<void>(
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

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
        final emailVerified = flavorService.emailVerified;
        final restricted = flavorService.clientRestricted;

        if (!hasFlavor && loc != '/bootstrap') {
          return '/bootstrap';
        }
        if (hasFlavor && loc == '/bootstrap') {
          if (!loggedIn) return '/login';
          if (!emailVerified) return '/verify-email';
          if (restricted) return '/wallet';
          return onboarded ? '/home' : '/member-onboard';
        }
        if (hasFlavor && loggedIn && restricted) {
          const allowed = {'/wallet', '/bootstrap'};
          if (!allowed.contains(loc)) {
            return '/wallet';
          }
        }
        if (hasFlavor && loggedIn && !emailVerified && loc != '/verify-email') {
          return '/verify-email';
        }
        if (hasFlavor && loggedIn && emailVerified && loc == '/verify-email') {
          if (restricted) return '/wallet';
          return onboarded ? '/home' : '/member-onboard';
        }
        if (hasFlavor && loggedIn && emailVerified && !onboarded && (loc == '/login' || loc == '/register')) {
          return '/member-onboard';
        }
        if (hasFlavor && !loggedIn && loc == '/member-onboard') {
          return '/login';
        }
        if (hasFlavor && loggedIn && !onboarded && _protected(loc) && loc != '/member-onboard') {
          return '/member-onboard';
        }
        if (hasFlavor && loggedIn && onboarded && (loc == '/login' || loc == '/register' || loc == '/member-onboard')) {
          return restricted ? '/wallet' : '/home';
        }
        if (hasFlavor && !loggedIn && _protected(loc)) {
          return '/login';
        }
        if (hasFlavor && !loggedIn && loc == '/verify-email') {
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
          path: '/verify-email',
          builder: (_, __) => const VerifyEmailScreen(),
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
          pageBuilder: (_, __) => _fadeSlide(const WalletScreen()),
        ),
        GoRoute(
          path: '/membership',
          pageBuilder: (_, __) => _fadeSlide(const MembershipScreen()),
        ),
        GoRoute(
          path: '/bookings',
          pageBuilder: (_, __) => _fadeSlide(const BookingsScreen()),
        ),
        GoRoute(
          path: '/appointment',
          pageBuilder: (_, __) => _fadeSlide(const AppointmentFlowScreen()),
        ),
        GoRoute(
          path: '/branch',
          pageBuilder: (_, __) => _fadeSlide(const BranchScreen()),
        ),
        GoRoute(
          path: '/id-verification',
          pageBuilder: (_, __) => _fadeSlide(const IdSubmissionScreen()),
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
        loc.startsWith('/membership') ||
        loc.startsWith('/bookings') ||
        loc.startsWith('/appointment') ||
        loc.startsWith('/branch') ||
        loc.startsWith('/id-verification');
  }
}
