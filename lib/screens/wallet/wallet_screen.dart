import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../flavor/gym_flavor_service.dart';
import '../../services/member_service.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/stitch_text_field.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  MemberWallet? _wallet;
  bool _loading = true;
  bool _busy = false;
  String? _message;
  bool _messageOk = false;
  final _topUpCtrl = TextEditingController(text: '500');
  final _refundAmtCtrl = TextEditingController();
  final _refundReasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _topUpCtrl.dispose();
    _refundAmtCtrl.dispose();
    _refundReasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) return;
    final wallet = await MemberService.forFlavor(flavor).fetchWallet();
    if (!mounted) return;
    setState(() {
      _wallet = wallet;
      _loading = false;
    });
  }

  void _flash(String msg, {bool ok = false}) {
    setState(() {
      _message = msg;
      _messageOk = ok;
    });
  }

  Future<void> _topUpPayMongo() async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) return;
    final amount = double.tryParse(_topUpCtrl.text.trim()) ?? 0;
    if (amount < 50) {
      _flash('Minimum top-up is ₱50');
      return;
    }
    setState(() => _busy = true);
    final result = await MemberService.forFlavor(flavor).requestTopUp(amount);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!result.ok || result.checkoutUrl == null) {
      _flash(result.message.isNotEmpty ? result.message : 'Could not start payment');
      return;
    }
    final uri = Uri.parse(result.checkoutUrl!);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _flash('Could not open payment page');
      return;
    }
    _flash('Complete payment in browser, then pull to refresh.', ok: true);
  }

  Future<void> _requestRefund() async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) return;
    final amount = double.tryParse(_refundAmtCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      _flash('Enter refund amount');
      return;
    }
    setState(() => _busy = true);
    final result = await MemberService.forFlavor(flavor).requestRefund(
      amount: amount,
      reason: _refundReasonCtrl.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    _flash(result.message, ok: result.ok);
    if (result.ok) {
      _refundAmtCtrl.clear();
      _refundReasonCtrl.clear();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final flavor = GymFlavorService.instance.flavor!;
    final balance = _wallet?.balance ?? 0;
    final qrPayload = 'titanfit://gym/${flavor.gymSlug}?member=1';

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: const Text('Wallet'),
        backgroundColor: const Color(0xFF000000),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('BALANCE', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 8),
                  if (_loading)
                    const SizedBox(
                      height: 40,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else
                    Text(
                      '₱${balance.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                    ),
                ],
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              GlassPanel(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _message!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _messageOk ? Colors.greenAccent : Colors.orangeAccent,
                      ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('TOP UP', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 12),
                  StitchTextField(
                    controller: _topUpCtrl,
                    label: 'Amount (PHP)',
                    icon: Icons.payments_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  PillButton(
                    label: 'Pay with PayMongo',
                    loading: _busy,
                    onPressed: _topUpPayMongo,
                    icon: Icons.open_in_new,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('REFUND REQUEST', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 12),
                  StitchTextField(
                    controller: _refundAmtCtrl,
                    label: 'Amount',
                    icon: Icons.receipt_long_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  StitchTextField(
                    controller: _refundReasonCtrl,
                    label: 'Reason',
                    icon: Icons.notes_outlined,
                  ),
                  const SizedBox(height: 12),
                  PillButton(
                    label: 'Send refund request',
                    loading: _busy,
                    onPressed: _requestRefund,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Staff reviews requests — balance updates after approval.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassPanel(
              child: Column(
                children: [
                  QrImageView(
                    data: qrPayload,
                    version: QrVersions.auto,
                    size: 160,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text('Digital pass', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Show at ${flavor.gymName} front desk.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
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
