import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../flavor/gym_flavor_service.dart';
import '../../services/member_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pill_button.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  MemberCatalog? _catalog;
  bool _loading = true;
  final _selectedTfByCat = <int, String>{};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) return;
    final catalog = await MemberService.forFlavor(flavor).fetchMembershipCatalog();
    if (!mounted) return;
    setState(() {
      _catalog = catalog;
      _loading = false;
      if (catalog != null) {
        for (final cat in catalog.categories) {
          if (cat.timeframes.isNotEmpty && !_selectedTfByCat.containsKey(cat.id)) {
            _selectedTfByCat[cat.id] = cat.timeframes.first.id;
          }
        }
      }
    });
  }

  Future<void> _purchasePlan(MembershipCategory cat, MembershipPlan plan) async {
    final tfId = _selectedTfByCat[cat.id];
    if (tfId == null || tfId.isEmpty) {
      setState(() => _error = 'Select a duration first');
      return;
    }
    final flavor = GymFlavorService.instance.flavor!;
    final member = MemberService.forFlavor(flavor);

    final preview = await member.purchaseMembership(
      planId: plan.id,
      timeframeId: tfId,
      dryRun: true,
    );
    if (!mounted) return;
    if (!preview.ok || preview.preview == null) {
      setState(() => _error = preview.message);
      return;
    }

    final p = preview.preview!;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => _PurchaseSheet(
        planName: plan.name,
        categoryName: cat.name,
        preview: p,
        balance: _catalog?.balance ?? 0,
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _error = null);
    final result = await member.purchaseMembership(
      planId: plan.id,
      timeframeId: tfId,
      isUpgrade: p.action == 'upgrade',
      oldMembershipId: p.oldMembershipId,
    );
    if (!mounted) return;
    if (result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message.isNotEmpty ? result.message : 'Membership updated')),
      );
      await _load();
    } else {
      setState(() => _error = result.message);
      if (result.message.toLowerCase().contains('insufficient')) {
        if (context.mounted) context.push('/wallet');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catalog = _catalog;

    return Scaffold(
      backgroundColor: isDark ? TitanTheme.canvasDark : TitanTheme.canvasLight,
      appBar: AppBar(
        title: const Text('Membership'),
        backgroundColor: isDark ? TitanTheme.canvasDark : TitanTheme.canvasLight,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (catalog != null) ...[
              ..._activeMembershipBanners(catalog, theme, isDark),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? TitanTheme.surfaceContainerDark : TitanTheme.surfaceContainerLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? TitanTheme.borderDark : TitanTheme.borderLight),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('WALLET', style: theme.textTheme.labelSmall),
                          Text(
                            '₱${catalog.balance.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    TextButton(onPressed: () => context.push('/wallet'), child: const Text('Top up')),
                  ],
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(strokeWidth: 2)))
            else if (catalog == null || catalog.categories.isEmpty)
              Text('No membership plans available.', style: theme.textTheme.bodyMedium)
            else
              ...catalog.categories.map((cat) => _CategorySection(
                    category: cat,
                    selectedTfId: _selectedTfByCat[cat.id],
                    onTfChanged: (id) => setState(() => _selectedTfByCat[cat.id] = id),
                    onSelectPlan: (plan) => _purchasePlan(cat, plan),
                  )),
          ],
        ),
      ),
    );
  }

  List<Widget> _activeMembershipBanners(
    MemberCatalog catalog,
    ThemeData theme,
    bool isDark,
  ) {
    final active = catalog.categories
        .where((c) => c.activeMembership != null && c.activeMembership!.planName.isNotEmpty)
        .map((c) => MapEntry(c.name, c.activeMembership!))
        .toList();
    if (active.isEmpty) return const [];

    return active.map((entry) {
      final plan = entry.value;
      final days = plan.daysRemaining;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? TitanTheme.surfaceContainerDark : TitanTheme.surfaceContainerLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.verified_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ACTIVE · ${entry.key.toUpperCase()}', style: theme.textTheme.labelSmall),
                  Text(
                    plan.planName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (days > 0)
                    Text(
                      '$days day${days == 1 ? '' : 's'} remaining',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.selectedTfId,
    required this.onTfChanged,
    required this.onSelectPlan,
  });

  final MembershipCategory category;
  final String? selectedTfId;
  final ValueChanged<String> onTfChanged;
  final ValueChanged<MembershipPlan> onSelectPlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final active = category.activeMembership;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(category.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              if (active != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    active.planName,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
            ],
          ),
          if (active != null && active.daysRemaining > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${active.daysRemaining} days left',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
            ),
          if (category.timeframes.isNotEmpty) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: category.timeframes.map((tf) {
                  final selected = tf.id == selectedTfId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(tf.label),
                      selected: selected,
                      onSelected: (_) => onTfChanged(tf.id),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (category.plans.isEmpty)
            Text('No plans in this category.', style: theme.textTheme.bodyMedium)
          else
            ...category.plans.map((plan) {
              final price = selectedTfId != null ? plan.priceFor(selectedTfId!) : null;
              final isCurrent = active?.planId == plan.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? TitanTheme.surfaceDark : TitanTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCurrent ? theme.colorScheme.primary : (isDark ? TitanTheme.borderDark : TitanTheme.borderLight),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plan.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                          if (plan.description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(plan.description, style: theme.textTheme.bodySmall),
                            ),
                          if (price != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '₱${price.toStringAsFixed(2)}',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isCurrent)
                      Text('Active', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary))
                    else
                      FilledButton(
                        onPressed: price != null ? () => onSelectPlan(plan) : null,
                        child: const Text('Select'),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _PurchaseSheet extends StatelessWidget {
  const _PurchaseSheet({
    required this.planName,
    required this.categoryName,
    required this.preview,
    required this.balance,
  });

  final String planName;
  final String categoryName;
  final MembershipPurchasePreview preview;
  final double balance;

  String get _actionLabel => switch (preview.action) {
        'extend' => 'Extend membership',
        'upgrade' => 'Upgrade membership',
        _ => 'Purchase membership',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAfford = balance + 0.001 >= preview.amountToPay;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_actionLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('$categoryName · $planName', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          if (preview.action == 'upgrade' && preview.remainingCredit > 0)
            Text('Credit from current plan: ₱${preview.remainingCredit.toStringAsFixed(2)}'),
          Text(
            'Amount due: ₱${preview.amountToPay.toStringAsFixed(2)}',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text('Wallet: ₱${balance.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium),
          if (!canAfford) ...[
            const SizedBox(height: 8),
            Text('Insufficient balance', style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 20),
          PillButton(
            label: canAfford ? 'Confirm purchase' : 'Top up wallet',
            onPressed: () => Navigator.pop(context, canAfford),
          ),
        ],
      ),
    );
  }
}
