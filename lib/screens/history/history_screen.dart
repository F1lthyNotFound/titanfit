import 'package:flutter/material.dart';

import '../../flavor/gym_flavor_service.dart';
import '../../services/member_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fade_slide_in.dart';

enum _HistoryFilter { all, checkIn, topUp, booking }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<MemberHistoryItem> _items = [];
  _HistoryFilter _filter = _HistoryFilter.all;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final items = await MemberService.forFlavor(flavor).fetchHistory();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  List<MemberHistoryItem> get _filtered {
    return switch (_filter) {
      _HistoryFilter.all => _items,
      _HistoryFilter.checkIn => _items.where((e) => e.isCheckIn).toList(),
      _HistoryFilter.topUp => _items.where((e) => e.isTopUp).toList(),
      _HistoryFilter.booking => _items.where((e) => e.isBooking).toList(),
    };
  }

  IconData _iconFor(MemberHistoryItem item) {
    return switch (item.iconHint) {
      'check_in' => Icons.login_rounded,
      'wallet' => Icons.account_balance_wallet_outlined,
      'booking' => Icons.event_available_outlined,
      'shop' => Icons.shopping_bag_outlined,
      'refund' => Icons.replay_outlined,
      _ => Icons.history_rounded,
    };
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final min = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, ${local.year} · $hour:$min $ampm';
  }

  String _amountLabel(MemberHistoryItem item) {
    if (item.amount == null) return '';
    final prefix = item.type == 'refund' ? '−' : '+';
    return '$prefix₱${item.amount!.toStringAsFixed(2)}';
  }

  Widget _chip(String label, _HistoryFilter value) {
    final selected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      showCheckmark: false,
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
      selectedColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _emptyState() {
    final (icon, title, subtitle) = switch (_filter) {
      _HistoryFilter.checkIn => (
          Icons.login_rounded,
          'No check-ins yet',
          'Visits show here after you scan in at the gym.',
        ),
      _HistoryFilter.topUp => (
          Icons.account_balance_wallet_outlined,
          'No top-ups yet',
          'Wallet payments appear here once you add funds.',
        ),
      _HistoryFilter.booking => (
          Icons.event_available_outlined,
          'No bookings yet',
          'Class and session payments will show up here.',
        ),
      _HistoryFilter.all => (
          Icons.history_rounded,
          'Nothing here yet',
          'Check-ins, top-ups, and bookings appear as you use the app.',
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _row(MemberHistoryItem item, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final amount = _amountLabel(item);

    return FadeSlideIn(
      delay: Duration(milliseconds: 35 * (index % 12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? TitanTheme.surfaceDark : TitanTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? TitanTheme.borderDark : TitanTheme.borderLight),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_iconFor(item), size: 24, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(_formatDate(item.date), style: theme.textTheme.bodySmall),
                    if (item.status.isNotEmpty && item.status != 'completed')
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.status.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ),
                  ],
                ),
              ),
              if (amount.isNotEmpty)
                Text(amount, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _chip('All', _HistoryFilter.all),
                const SizedBox(width: 8),
                _chip('Check-in', _HistoryFilter.checkIn),
                const SizedBox(width: 8),
                _chip('Top-up', _HistoryFilter.topUp),
                const SizedBox(width: 8),
                _chip('Booking', _HistoryFilter.booking),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: filtered.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [SizedBox(height: MediaQuery.sizeOf(context).height * 0.35, child: _emptyState())],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) => _row(filtered[i], i),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
