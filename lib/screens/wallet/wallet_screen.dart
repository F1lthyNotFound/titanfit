import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../flavor/gym_flavor_service.dart';
import '../../services/auth_service.dart';
import '../../services/member_service.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/stitch_text_field.dart';
import 'payment_checkout_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with WidgetsBindingObserver {
  MemberWallet? _wallet;
  bool _loading = true;
  bool _busy = false;
  String? _message;
  bool _messageOk = false;
  int? _pendingTopUpId;
  final _topUpCtrl = TextEditingController(text: '500');
  final _refundAmtCtrl = TextEditingController();
  final _refundReasonCtrl = TextEditingController();
  final _payoutDetailsCtrl = TextEditingController();
  String _refundMethod = 'card';

  bool get _restricted => _wallet?.isWalletRefundOnly == true || GymFlavorService.instance.clientRestricted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _topUpCtrl.dispose();
    _refundAmtCtrl.dispose();
    _refundReasonCtrl.dispose();
    _payoutDetailsCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _pollPendingTopUp();
    }
  }

  Future<void> _load() async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) return;
    final wallet = await MemberService.forFlavor(flavor).fetchWallet();
    if (!mounted) return;
    if (wallet != null) {
      await GymFlavorService.instance.setClientRestricted(wallet.isWalletRefundOnly);
    }
    setState(() {
      _wallet = wallet;
      _loading = false;
      if (wallet != null && wallet.refundMethods.isNotEmpty) {
        final hasMethod = wallet.refundMethods.any((m) => m.id == _refundMethod);
        if (!hasMethod) {
          _refundMethod = wallet.refundMethods.first.id;
        }
      }
      if (wallet != null && wallet.availableRefund > 0 && _refundAmtCtrl.text.isEmpty) {
        _refundAmtCtrl.text = wallet.availableRefund.toStringAsFixed(2);
      }
    });
  }

  Future<void> _pollPendingTopUp() async {
    final topupId = _pendingTopUpId;
    if (topupId == null) {
      await _load();
      return;
    }
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) return;
    final status = await MemberService.forFlavor(flavor).pollTopUpStatus(topupId);
    if (!mounted) return;
    if (status.paid) {
      setState(() {
        _pendingTopUpId = null;
        if (status.balance != null && _wallet != null) {
          _wallet = MemberWallet(
            balance: status.balance!,
            currency: _wallet!.currency,
            clientStatus: _wallet!.clientStatus,
            accessMode: _wallet!.accessMode,
            refundMethods: _wallet!.refundMethods,
            pendingRefund: _wallet!.pendingRefund,
          );
        }
      });
      _flash('Top-up successful!', ok: true);
      await _load();
      return;
    }
    await _load();
  }

  void _flash(String msg, {bool ok = false}) {
    setState(() {
      _message = msg;
      _messageOk = ok;
    });
  }

  RefundPaymentMethod? get _selectedRefundMethod {
    final methods = _wallet?.refundMethods ?? const <RefundPaymentMethod>[];
    for (final method in methods) {
      if (method.id == _refundMethod) return method;
    }
    return methods.isNotEmpty ? methods.first : null;
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
    _pendingTopUpId = result.topupId;
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentCheckoutScreen(checkoutUrl: result.checkoutUrl!),
      ),
    );
    if (!mounted) return;
    if (completed == false) {
      _flash('Payment cancelled');
      return;
    }
    await _pollPendingTopUp();
    if (!mounted) return;
    if (_pendingTopUpId == null) {
      return;
    }
    _flash('Payment processing — pull to refresh if balance has not updated yet.', ok: true);
  }

  Future<void> _requestRefund() async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) return;
    final amount = double.tryParse(_refundAmtCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      _flash('Enter refund amount');
      return;
    }
    final method = _selectedRefundMethod;
    if (method == null) {
      _flash('Choose a refund method');
      return;
    }
    if (method.requiresDetails && _payoutDetailsCtrl.text.trim().isEmpty) {
      _flash('Enter ${method.detailsLabel.toLowerCase()}');
      return;
    }
    setState(() => _busy = true);
    final result = await MemberService.forFlavor(flavor).requestRefund(
      amount: amount,
      reason: _refundReasonCtrl.text,
      paymentMethod: method.id,
      payoutDetails: _payoutDetailsCtrl.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    _flash(result.message, ok: result.ok);
    if (result.ok) {
      _refundReasonCtrl.clear();
      _payoutDetailsCtrl.clear();
      await _load();
    }
  }

  Future<void> _logout() async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) return;
    await AuthService.forFlavor(flavor).logout();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final wallet = _wallet;
    final balance = wallet?.balance ?? 0;
    final available = wallet?.availableRefund ?? balance;
    final methods = wallet?.refundMethods ?? const <RefundPaymentMethod>[];
    final selectedMethod = _selectedRefundMethod;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: Text(_restricted ? 'Wallet refund' : 'Wallet'),
        backgroundColor: const Color(0xFF000000),
        actions: [
          if (_restricted)
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              tooltip: 'Sign out',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _pollPendingTopUp,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_restricted)
              GlassPanel(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orangeAccent.shade200, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'ACCOUNT DEACTIVATED',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.orangeAccent.shade200,
                                letterSpacing: 1.1,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your gym membership is inactive. You can still access your Titan Labs wallet here and request a refund to your preferred payout method.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            if (_restricted) const SizedBox(height: 16),
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
                  else ...[
                    Text(
                      '₱${balance.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                    ),
                    if ((wallet?.pendingRefund ?? 0) > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        '₱${wallet!.pendingRefund.toStringAsFixed(2)} pending refund · ₱${available.toStringAsFixed(2)} available',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
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
            if (!_restricted) ...[
              const SizedBox(height: 16),
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('TOP UP', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 8),
                    Text(
                      'Credits go to your Titan Labs platform wallet and can be used across participating gyms.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
                      icon: Icons.payment,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('REFUND REQUEST', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how Titan Labs should return your wallet balance.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  if (methods.isEmpty)
                    Text('Loading refund methods…', style: Theme.of(context).textTheme.bodyMedium)
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: methods.map((method) {
                        final selected = method.id == _refundMethod;
                        return ChoiceChip(
                          label: Text(method.label),
                          selected: selected,
                          onSelected: (_) => setState(() => _refundMethod = method.id),
                        );
                      }).toList(),
                    ),
                  if (selectedMethod != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      selectedMethod.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                  StitchTextField(
                    controller: _refundAmtCtrl,
                    label: 'Amount',
                    icon: Icons.receipt_long_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  if (selectedMethod?.requiresDetails == true) ...[
                    const SizedBox(height: 12),
                    StitchTextField(
                      controller: _payoutDetailsCtrl,
                      label: selectedMethod!.detailsLabel,
                      icon: Icons.account_balance_outlined,
                    ),
                  ],
                  const SizedBox(height: 12),
                  StitchTextField(
                    controller: _refundReasonCtrl,
                    label: 'Reason (optional)',
                    icon: Icons.notes_outlined,
                  ),
                  const SizedBox(height: 12),
                  PillButton(
                    label: 'Submit refund request',
                    loading: _busy,
                    onPressed: _requestRefund,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Titan Labs reviews requests and processes payouts to your selected method.',
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
