import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../flavor/gym_flavor_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/gym_logo.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor != null) {
      await AuthService.forFlavor(flavor).logout();
    }
    if (context.mounted) context.go('/login');
  }

  Future<void> _resetGym(BuildContext context) async {
    await GymFlavorService.instance.clearFlavor();
    if (context.mounted) context.go('/onboard');
  }

  @override
  Widget build(BuildContext context) {
    final flavor = GymFlavorService.instance.flavor!;
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: GymLogo(flavor: flavor, size: 80)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              flavor.gymName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Gym code: ${flavor.gymSlug}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('App theme'),
            subtitle: Text(flavor.themeSlug),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => _logout(context),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Switch gym'),
            onTap: () => _resetGym(context),
          ),
        ],
      ),
    );
  }
}
