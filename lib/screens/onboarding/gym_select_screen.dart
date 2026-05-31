import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../flavor/gym_flavor_service.dart';

class GymSelectScreen extends StatefulWidget {
  const GymSelectScreen({super.key});

  @override
  State<GymSelectScreen> createState() => _GymSelectScreenState();
}

class _GymSelectScreenState extends State<GymSelectScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefillFromCachedFlavor();
  }

  void _prefillFromCachedFlavor() {
    final slug = GymFlavorService.instance.flavor?.gymSlug;
    if (slug != null && slug.isNotEmpty) {
      _controller.text = slug;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
    });
    final slug = _controller.text.trim().toLowerCase();
    if (slug.isEmpty) {
      setState(() => _error = 'Enter your gym code');
      return;
    }
    final flavor = await GymFlavorService.instance.resolveFlavor(slug);
    if (!mounted) return;
    if (flavor == null) {
      setState(() => _error = 'Gym not found — check code from your gym');
      return;
    }
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final loading = GymFlavorService.instance.isLoading;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 1),
              Text(
                'TitanFit',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the gym code from your landing page download link.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Gym code',
                  hintText: 'e.g. ironworks-gym',
                ),
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: loading ? null : _submit,
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Connect to gym'),
              ),
              const Spacer(flex: 2),
              Text(
                'Install from your gym\'s page to auto-apply branding.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
