import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../flavor/gym_flavor_service.dart';
import '../../services/member_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/member_card_modal.dart';
import '../../widgets/fade_slide_in.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  MemberDashboard? _dashboard;
  MemberProfile? _profile;
  bool _loading = true;
  String? _selectedDate;
  final _scrollController = ScrollController();
  final _alertsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
    }
  }

  Future<void> _load() async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) return;
    final member = MemberService.forFlavor(flavor);
    final results = await Future.wait([
      member.fetchDashboard(),
      member.fetchProfile(),
    ]);
    if (!mounted) return;
    final dash = results[0] as MemberDashboard?;
    final profile = results[1] as MemberProfile?;
    final restricted = dash?.isWalletRefundOnly == true || profile?.isWalletRefundOnly == true;
    await GymFlavorService.instance.setClientRestricted(restricted);
    if (!mounted) return;
    if (restricted) {
      context.go('/wallet');
      return;
    }
    setState(() {
      _dashboard = dash;
      _profile = profile;
      _loading = false;
      if (_selectedDate == null && dash != null) {
        final today = dash.weekDays.where((d) => d.isToday).map((d) => d.date).firstOrNull;
        _selectedDate = today ?? (dash.weekDays.isNotEmpty ? dash.weekDays.first.date : null);
      }
    });
  }

  void _scrollToAlerts() {
    final ctx = _alertsKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    }
  }

  void _showMemberCard() {
    final flavor = GymFlavorService.instance.flavor!;
    final profile = _profile;
    final name = profile != null && '${profile.firstName} ${profile.lastName}'.trim().isNotEmpty
        ? '${profile.firstName} ${profile.lastName}'.trim()
        : flavor.gymName;
    showMemberCardModal(
      context,
      memberName: name,
      gymName: flavor.gymName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dash = _dashboard;
    final branch = dash?.branchName.isNotEmpty == true
        ? dash!.branchName.toUpperCase()
        : GymFlavorService.instance.flavor!.gymName.toUpperCase();
    final sessions = dash?.sessionsByDate[_selectedDate] ?? const <MemberDashboardSession>[];

    return Scaffold(
      backgroundColor: isDark ? TitanTheme.canvasDark : TitanTheme.canvasLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Membership',
                        onPressed: () => context.push('/membership'),
                        icon: const Icon(Icons.card_membership_outlined),
                      ),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              final switched = await context.push<bool>('/branch');
                              if (switched == true && mounted) {
                                await _load();
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      branch,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.expand_more,
                                    size: 18,
                                    color: theme.colorScheme.outline,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Alerts',
                        onPressed: _scrollToAlerts,
                        icon: Badge(
                          isLabelVisible: (dash?.alerts.length ?? 0) > 0,
                          child: const Icon(Icons.notifications_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _StatusCard(
                    loading: _loading,
                    dashboard: dash,
                    onWalletTap: () => context.push('/wallet'),
                    onMembershipTap: () => context.push('/membership'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: OutlinedButton.icon(
                    onPressed: _showMemberCard,
                    icon: const Icon(Icons.badge_outlined, size: 18),
                    label: const Text('Member card'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: Row(
                    children: [
                      Text('Schedule', style: theme.textTheme.titleMedium),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.push('/bookings'),
                        child: const Text('VIEW ALL →'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _WeekStrip(
                    days: dash?.weekDays ?? const [],
                    selectedDate: _selectedDate,
                    onSelect: (date) => setState(() => _selectedDate = date),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _SessionList(loading: _loading, sessions: sessions),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                  child: Column(
                    key: _alertsKey,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text('Alerts', style: theme.textTheme.titleMedium),
                          if ((dash?.alerts.length ?? 0) > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      _AlertsList(loading: _loading, alerts: dash?.alerts ?? const []),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.loading,
    required this.dashboard,
    required this.onWalletTap,
    required this.onMembershipTap,
  });

  final bool loading;
  final MemberDashboard? dashboard;
  final VoidCallback onWalletTap;
  final VoidCallback onMembershipTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? TitanTheme.surfaceContainerDark : TitanTheme.surfaceContainerLight;
    final border = isDark ? TitanTheme.borderDark : TitanTheme.borderLight;
    final inside = dashboard?.isInside ?? false;
    final balance = dashboard?.balance ?? 0;
    final memb = dashboard?.membershipName;
    final membDays = dashboard?.membershipDaysLeft ?? 0;
    final membLabel = loading
        ? '—'
        : (memb?.isNotEmpty == true
            ? (membDays > 0 ? '$memb · ${membDays}d left' : memb!)
            : 'No plan');

    return AspectRatio(
      aspectRatio: 3 / 2.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 16,
              top: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onWalletTap,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AVAILABLE CREDITS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              loading ? '—' : balance.toStringAsFixed(0).replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (m) => '${m[1]},',
                                  ),
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.account_balance_wallet_outlined, size: 16, color: theme.colorScheme.outline),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.15), width: 2),
                    ),
                    child: Icon(
                      inside ? Icons.check_circle_outline : Icons.logout,
                      size: 32,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loading ? '…' : (inside ? 'CLEARED' : 'OUTSIDE'),
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loading ? '' : (dashboard?.checkInSubtext ?? 'Not checked in').toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onMembershipTap,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'STATUS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          membLabel,
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.days,
    required this.selectedDate,
    required this.onSelect,
  });

  final List<MemberDashboardDay> days;
  final String? selectedDate;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (days.isEmpty) {
      return Text('No schedule this week.', style: theme.textTheme.bodyMedium);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: days.map((d) {
          final selected = d.date == selectedDate;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: selected
                  ? theme.colorScheme.onSurface
                  : (isDark ? TitanTheme.surfaceDark : TitanTheme.surfaceLight),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onSelect(d.date),
                child: Container(
                  width: 56,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Text(
                        d.weekday,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: selected ? theme.colorScheme.surface : theme.colorScheme.outline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${d.day}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: selected ? theme.colorScheme.surface : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SessionList extends StatelessWidget {
  const _SessionList({required this.loading, required this.sessions});

  final bool loading;
  final List<MemberDashboardSession> sessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    if (sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('No sessions this day.', style: theme.textTheme.bodyMedium),
      );
    }

    return Column(
      children: sessions.map((s) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? TitanTheme.surfaceDark : TitanTheme.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? TitanTheme.borderDark : TitanTheme.borderLight),
          ),
          child: Row(
            children: [
              Text(
                s.time,
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(s.label, style: theme.textTheme.bodyLarge)),
              Icon(Icons.add, size: 18, color: theme.colorScheme.outline),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AlertsList extends StatelessWidget {
  const _AlertsList({required this.loading, required this.alerts});

  final bool loading;
  final List<MemberDashboardAlert> alerts;

  IconData _iconFor(String kind) => switch (kind) {
        'wallet' => Icons.account_balance_wallet_outlined,
        'membership' => Icons.card_membership_outlined,
        'id' => Icons.badge_outlined,
        _ => Icons.info_outline,
      };

  void _onTap(BuildContext context, MemberDashboardAlert alert) {
    switch (alert.kind) {
      case 'id':
        context.push('/id-verification');
      case 'wallet':
        context.push('/wallet');
      case 'membership':
        context.push('/membership');
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (loading) {
      return const LinearProgressIndicator(minHeight: 2);
    }
    if (alerts.isEmpty) {
      return Text('No alerts right now.', style: theme.textTheme.bodyMedium);
    }

    return Column(
      children: alerts.asMap().entries.map((entry) {
        final i = entry.key;
        final a = entry.value;
        final tappable = a.kind == 'id' || a.kind == 'wallet' || a.kind == 'membership';
        return FadeSlideIn(
          delay: Duration(milliseconds: 50 * i),
          child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: tappable ? () => _onTap(context, a) : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? TitanTheme.surfaceDark : TitanTheme.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? TitanTheme.borderDark : TitanTheme.borderLight),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_iconFor(a.kind), size: 20, color: theme.colorScheme.onSurface),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(a.message, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
                      ],
                    ),
                  ),
                  if (tappable) Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.outline),
                ],
              ),
            ),
          ),
        ),
        );
      }).toList(),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
