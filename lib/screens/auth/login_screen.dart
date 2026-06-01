import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../flavor/gym_flavor_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_error_banner.dart';
import '../../widgets/gym_logo.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/stitch_text_field.dart';
import '../../widgets/theme_toggle_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) {
      context.go('/bootstrap');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = AuthService.forFlavor(flavor);
    final result = await auth.login(
      username: _userCtrl.text,
      password: _passCtrl.text,
      flavor: flavor,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.ok) {
      if (result.needsEmailVerification) {
        context.go('/verify-email');
        return;
      }
      if (result.walletRefundOnly) {
        context.go('/wallet');
        return;
      }
      context.go(result.needsOnboarding ? '/member-onboard' : '/home');
      return;
    }
    setState(() => _error = result.message);
  }

  @override
  Widget build(BuildContext context) {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: ThemeToggleButton(),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    16 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      children: [
                        GymLogo(flavor: flavor, size: 72),
                        const SizedBox(height: 20),
                        Text(
                          flavor.gymName.toUpperCase(),
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        GlassPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'SIGN IN',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontSize: 28,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Use the username from your gym account.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 24),
                              StitchTextField(
                                controller: _userCtrl,
                                label: 'Username',
                                hint: 'Registered username',
                                icon: Icons.person_outline,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                              ),
                              const SizedBox(height: 16),
                              StitchTextField(
                                controller: _passCtrl,
                                label: 'Password',
                                hint: 'Your password',
                                icon: Icons.lock_outline,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _login(),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _loading ? null : () => context.push('/forgot-password'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Theme.of(context).colorScheme.primary,
                                  ),
                                  child: const Text('Forgot password?'),
                                ),
                              ),
                              AuthErrorBanner(message: _error),
                              const SizedBox(height: 12),
                              PillButton(
                                label: 'Sign in',
                                loading: _loading,
                                onPressed: _login,
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => context.push('/register'),
                                child: const Text('Create member account'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
