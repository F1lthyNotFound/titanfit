import 'package:flutter/material.dart';

import '../../flavor/gym_flavor_service.dart';
import '../../services/member_service.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/pill_button.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
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
    final wallet = await MemberService.forFlavor(flavor).fetchWallet();
    if (!mounted) return;
    setState(() {
      _wallet = wallet;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final flavor = GymFlavorService.instance.flavor!;
    final plan = _wallet?.membershipName;
    final hasPlan = plan != null && plan.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: const Text('Membership'),
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
                  Text(
                    'YOUR PLAN',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  else if (hasPlan) ...[
                    Text(
                      plan,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 28,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Active at ${flavor.gymName}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ] else
                    Text(
                      'No active membership',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BENEFITS', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 12),
                  _BenefitRow(
                    icon: Icons.fitness_center,
                    label: 'Gym floor access',
                    active: hasPlan,
                  ),
                  _BenefitRow(
                    icon: Icons.calendar_month_outlined,
                    label: 'Class bookings',
                    active: hasPlan,
                  ),
                  _BenefitRow(
                    icon: Icons.badge_outlined,
                    label: 'Member ID perks',
                    active: hasPlan,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Need a plan?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ask front desk to assign or upgrade your membership.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  PillButton(
                    label: 'Contact gym',
                    onPressed: () {},
                    icon: Icons.support_agent_outlined,
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

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outline;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
          Icon(
            active ? Icons.check_circle_outline : Icons.lock_outline,
            size: 18,
            color: color,
          ),
        ],
      ),
    );
  }
}
