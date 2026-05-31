import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../flavor/gym_flavor_service.dart';

/// Resolves gym flavor from install bundle — no manual gym code entry.
class FlavorBootstrapScreen extends StatefulWidget {
  const FlavorBootstrapScreen({super.key});

  @override
  State<FlavorBootstrapScreen> createState() => _FlavorBootstrapScreenState();
}

class _FlavorBootstrapScreenState extends State<FlavorBootstrapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final ok = await GymFlavorService.instance.bootstrapFlavor();
    if (!mounted) return;
    if (ok) {
      context.go('/login');
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final service = GymFlavorService.instance;
    final error = service.bootstrapError;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (service.isLoading || error == null) ...[
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Connecting to your gym',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          letterSpacing: 0.02,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Loading your branded app…',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFC4C7C8),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 20),
                  Text(
                    'Could not link this install',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    error,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFC4C7C8),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: service.isLoading ? null : _run,
                    child: const Text('Try again'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
