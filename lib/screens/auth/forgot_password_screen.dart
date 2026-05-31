import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../flavor/gym_flavor_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_error_banner.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gym_logo.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/stitch_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await AuthService.forFlavor(flavor).forgotPassword(
      flavor: flavor,
      email: _emailCtrl.text,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.ok) {
        _sent = true;
      } else {
        _error = result.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF000000),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
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
                  GymLogo(flavor: flavor, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'RESET PASSWORD',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  GlassPanel(
                    child: _sent
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Check your email',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'We sent reset instructions to ${_emailCtrl.text.trim()}. '
                                'Open the link on your phone, then use Return to app.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 20),
                              PillButton(
                                label: 'Back to sign in',
                                onPressed: () => context.go('/login'),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'FORGOT PASSWORD',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontSize: 28,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enter the email on your ${flavor.gymName} member account.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 20),
                              StitchTextField(
                                controller: _emailCtrl,
                                label: 'Email',
                                icon: Icons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(),
                              ),
                              AuthErrorBanner(message: _error),
                              const SizedBox(height: 20),
                              PillButton(
                                label: 'Send reset link',
                                loading: _loading,
                                onPressed: _submit,
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
