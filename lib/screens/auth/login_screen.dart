import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../flavor/gym_flavor_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/gym_logo.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/stitch_text_field.dart';

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
      context.go('/onboard');
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
      context.go(result.needsOnboarding ? '/member-onboard' : '/home');
      return;
    }
    setState(() => _error = result.message);
  }

  @override
  Widget build(BuildContext context) {
    final flavor = GymFlavorService.instance.flavor!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  GymLogo(flavor: flavor, size: 64),
                  const SizedBox(height: 16),
                  Text(flavor.gymName, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 24),
                  GlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Sign in', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Use the username from your gym account.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        StitchTextField(
                          controller: _userCtrl,
                          label: 'Username',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 12),
                        StitchTextField(
                          controller: _passCtrl,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          obscureText: true,
                          onSubmitted: (_) => _login(),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ],
                        const SizedBox(height: 20),
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
                        TextButton(
                          onPressed: () => context.go('/onboard'),
                          child: const Text('Change gym'),
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
    );
  }
}
