import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../flavor/gym_flavor_service.dart';
import '../../services/member_service.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/stitch_text_field.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  String? _message;
  bool _messageOk = false;

  @override
  void initState() {
    super.initState();
    _sendCode(silent: true);
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode({bool silent = false}) async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) return;
    if (!silent) setState(() => _resending = true);
    final result = await MemberService.forFlavor(flavor).sendVerificationCode();
    if (!mounted) return;
    setState(() {
      _resending = false;
      if (!silent) {
        _message = result.message;
        _messageOk = result.ok;
      }
    });
  }

  Future<void> _verify() async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) return;
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() {
        _message = 'Enter the 6-digit code';
        _messageOk = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _message = null;
    });
    final result = await MemberService.forFlavor(flavor).verifyEmailCode(code);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.ok) {
      await GymFlavorService.instance.setEmailVerified(true);
      if (!mounted) return;
      context.go('/member-onboard');
      return;
    }
    setState(() {
      _message = result.message;
      _messageOk = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final flavor = GymFlavorService.instance.flavor;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Verify email')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'CHECK YOUR INBOX',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    flavor != null
                        ? 'We sent a 6-digit code to confirm your ${flavor.gymName} account.'
                        : 'Enter the verification code from your email.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  StitchTextField(
                    controller: _codeCtrl,
                    label: 'Verification code',
                    icon: Icons.mark_email_read_outlined,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _verify(),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _message!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _messageOk ? Colors.greenAccent : Colors.orangeAccent,
                          ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  PillButton(
                    label: 'Verify email',
                    loading: _loading,
                    onPressed: _verify,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _resending ? null : () => _sendCode(),
                    child: Text(_resending ? 'Sending…' : 'Resend code'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
