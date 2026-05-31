import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/api_config.dart';
import '../../flavor/gym_flavor_service.dart';
import '../../services/member_service.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gym_logo.dart';
import '../../widgets/home_module_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MemberProfile? _profile;
  MemberWallet? _wallet;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) return;
    final member = MemberService.forFlavor(flavor);
    final results = await Future.wait([
      member.fetchProfile(),
      member.fetchWallet(),
    ]);
    if (!mounted) return;
    setState(() {
      _profile = results[0] as MemberProfile?;
      _wallet = results[1] as MemberWallet?;
      _loading = false;
    });
  }

  String get _avatarUrl {
    final path = _profile?.avatarUrl ?? '';
    if (path.isEmpty) return '';
    final flavor = GymFlavorService.instance.flavor;
    final base = flavor?.apiBase.isNotEmpty == true
        ? flavor!.apiBase
        : ApiConfig.defaultApiBase;
    return path.startsWith('http') ? path : '$base$path';
  }

  String get _displayName {
    if (_profile == null) return GymFlavorService.instance.flavor!.gymName;
    final full = '${_profile!.firstName} ${_profile!.lastName}'.trim();
    if (full.isNotEmpty) return full;
    if (_profile!.username.isNotEmpty) return '@${_profile!.username}';
    return GymFlavorService.instance.flavor!.gymName;
  }

  @override
  Widget build(BuildContext context) {
    final flavor = GymFlavorService.instance.flavor!;
    final membership = _wallet?.membershipName;
    final hasMembership = membership != null && membership.isNotEmpty;
    final balance = _wallet?.balance ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: Text(flavor.gymName),
        backgroundColor: const Color(0xFF000000),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                if (_avatarUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: CachedNetworkImage(
                      imageUrl: _avatarUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => GymLogo(flavor: flavor, size: 56),
                    ),
                  )
                else
                  GymLogo(flavor: flavor, size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back', style: Theme.of(context).textTheme.bodyMedium),
                      Text(_displayName, style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('MODULES', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 12),
            HomeModuleCard(
              title: 'Wallet',
              subtitle: _loading
                  ? 'Loading balance…'
                  : '₱${balance.toStringAsFixed(2)} available',
              icon: Icons.account_balance_wallet_outlined,
              onTap: () => context.push('/wallet'),
            ),
            const SizedBox(height: 12),
            HomeModuleCard(
              title: 'Membership',
              subtitle: hasMembership ? membership : 'View plan & benefits',
              icon: Icons.card_membership_outlined,
              onTap: () => context.push('/membership'),
            ),
            const SizedBox(height: 24),
            if (!_loading) ...[
              GlassPanel(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.insights_outlined,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Check History for visits and bookings once your gym links attendance.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
