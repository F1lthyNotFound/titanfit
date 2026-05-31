import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../flavor/gym_flavor_service.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/stitch_text_field.dart';

class GymSelectScreen extends StatefulWidget {
  const GymSelectScreen({super.key});

  @override
  State<GymSelectScreen> createState() => _GymSelectScreenState();
}

class _GymSelectScreenState extends State<GymSelectScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  String? _error;
  late final AnimationController _entry;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _prefillFromCachedFlavor();
  }

  void _prefillFromCachedFlavor() {
    final slug = GymFlavorService.instance.flavor?.gymSlug;
    if (slug != null && slug.isNotEmpty) _controller.text = slug;
  }

  @override
  void dispose() {
    _controller.dispose();
    _entry.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    final slug = _controller.text.trim().toLowerCase();
    if (slug.isEmpty) {
      setState(() => _error = 'Enter your gym code');
      return;
    }
    final flavor = await GymFlavorService.instance.resolveFlavor(slug);
    if (!mounted) return;
    if (flavor == null) {
      setState(() => _error = 'Gym not found — check code from your gym page');
      return;
    }
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final loading = GymFlavorService.instance.isLoading;
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _entry, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
                .animate(CurvedAnimation(parent: _entry, curve: Curves.easeOut)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Spacer(),
                  Icon(Icons.all_inclusive, size: 48, color: Theme.of(context).colorScheme.onSurface),
                  const SizedBox(height: 12),
                  Text('TitanFit', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Connect to your gym',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  GlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Gym code',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'From your gym download link or landing page.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        StitchTextField(
                          controller: _controller,
                          hint: 'e.g. ironworks-gym',
                          icon: Icons.tag,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ],
                        const SizedBox(height: 20),
                        PillButton(
                          label: 'Connect',
                          loading: loading,
                          onPressed: loading ? null : _submit,
                          icon: Icons.arrow_forward,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
