import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../flavor/gym_flavor.dart';
import '../../flavor/gym_flavor_service.dart';
import '../../services/auth_service.dart';
import '../../services/member_service.dart';
import '../../widgets/gym_logo.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/stitch_text_field.dart';

class MemberOnboardingScreen extends StatefulWidget {
  const MemberOnboardingScreen({super.key});

  @override
  State<MemberOnboardingScreen> createState() => _MemberOnboardingScreenState();
}

class _MemberOnboardingScreenState extends State<MemberOnboardingScreen> {
  int _step = 0;
  bool _loading = false;
  String? _error;
  bool _slideForward = true;

  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _igCtrl = TextEditingController();
  final _fbCtrl = TextEditingController();

  String _gender = '';
  String _day = '';
  String _month = '';
  String _year = '';
  Uint8List? _avatarBytes;

  static const _stepCount = 5;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) return;
    final member = MemberService.forFlavor(flavor);
    final profile = await member.fetchProfile();
    if (profile == null || !mounted) return;
    _firstCtrl.text = profile.firstName;
    _lastCtrl.text = profile.lastName;
    _phoneCtrl.text = profile.phone;
    _gender = profile.gender;
    if (profile.dateOfBirth.isNotEmpty) {
      final parts = profile.dateOfBirth.split('-');
      if (parts.length == 3) {
        _year = parts[0];
        _month = parts[1];
        _day = parts[2];
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _phoneCtrl.dispose();
    _igCtrl.dispose();
    _fbCtrl.dispose();
    super.dispose();
  }

  Future<Uint8List?> _compressAvatar(XFile file) async {
    final raw = await file.readAsBytes();
    final decoded = img.decodeImage(raw);
    if (decoded == null) return raw.length <= 2 * 1024 * 1024 ? raw : null;

    var working = decoded;
    const maxSide = 1024;
    if (working.width > maxSide || working.height > maxSide) {
      working = img.copyResize(
        working,
        width: working.width > working.height ? maxSide : null,
        height: working.height >= working.width ? maxSide : null,
      );
    }

    var quality = 85;
    Uint8List out = Uint8List.fromList(img.encodeJpg(working, quality: quality));
    while (out.length > 2 * 1024 * 1024 && quality > 40) {
      quality -= 10;
      out = Uint8List.fromList(img.encodeJpg(working, quality: quality));
    }
    return out;
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600);
    if (file == null) return;
    final bytes = await _compressAvatar(file);
    if (bytes == null) {
      setState(() => _error = 'Image must be under 2MB after compression');
      return;
    }
    setState(() {
      _avatarBytes = bytes;
      _error = null;
    });
  }

  void _goToStep(int next, {bool forward = true}) {
    setState(() {
      _slideForward = forward;
      _step = next;
    });
  }

  void _next() {
    if (_step < _stepCount - 1) _goToStep(_step + 1);
  }

  void _back() {
    if (_step > 0) {
      _goToStep(_step - 1, forward: false);
    } else {
      context.go('/login');
    }
  }

  String? _dobIso() {
    if (_year.isEmpty || _month.isEmpty || _day.isEmpty) return null;
    return '${_year.padLeft(4, '0')}-${_month.padLeft(2, '0')}-${_day.padLeft(2, '0')}';
  }

  Future<void> _saveStep({bool complete = false}) async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final member = MemberService(AuthService.forFlavor(flavor).client);
    final ok = await member.saveProfile(
      firstName: _step == 0 ? _firstCtrl.text.trim() : null,
      lastName: _step == 0 ? _lastCtrl.text.trim() : null,
      gender: _step == 1 ? _gender : null,
      dateOfBirth: _step == 2 ? _dobIso() : null,
      phone: _step == 3 ? _phoneCtrl.text.trim() : null,
      socialInstagram: _step == 3 ? _igCtrl.text.trim() : null,
      socialFacebook: _step == 3 ? _fbCtrl.text.trim() : null,
      avatarBytes: _step == 0 ? _avatarBytes : null,
      complete: complete,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (!ok) {
      setState(() => _error = 'Could not save — try again');
      return;
    }

    if (complete) {
      await GymFlavorService.instance.setOnboardingComplete(true);
      if (mounted) context.go('/home');
    } else {
      _next();
    }
  }

  Widget _header() {
    final primary = Theme.of(context).colorScheme.primary;
    final muted = Theme.of(context).dividerColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back)),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_stepCount, (i) {
                    final active = i == _step;
                    final done = i < _step;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: done || active ? primary : muted.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
              ),
              if (_step < _stepCount - 1)
                TextButton(onPressed: _next, child: const Text('Skip'))
              else
                const SizedBox(width: 64),
            ],
          ),
        ],
      ),
    );
  }

  Widget _animatedStep(Widget child) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (widget, animation) {
        final offset = _slideForward ? const Offset(0.08, 0) : const Offset(-0.08, 0);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: offset, end: Offset.zero).animate(animation),
            child: widget,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey<int>(_step), child: child),
    );
  }

  Widget _stepIcon(IconData icon) {
    return Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary);
  }

  Widget _genderTile(String value, IconData icon) {
    final selected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Icon(
            icon,
            size: 36,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _dobSelect(String hint, String value, List<String> items, ValueChanged<String> onChanged) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        initialValue: value.isEmpty ? null : value,
        decoration: InputDecoration(hintText: hint),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) => onChanged(v ?? ''),
      ),
    );
  }

  Widget _currentStep(GymFlavor flavor, List<String> days, List<String> months, List<String> years) {
    return switch (_step) {
      0 => _stepWho(flavor),
      1 => _stepGender(),
      2 => _stepDob(days, months, years),
      3 => _stepContact(),
      _ => _stepCongrats(flavor),
    };
  }

  @override
  Widget build(BuildContext context) {
    final flavor = GymFlavorService.instance.flavor!;
    final days = List.generate(31, (i) => '${i + 1}'.padLeft(2, '0'));
    final months = List.generate(12, (i) => '${i + 1}'.padLeft(2, '0'));
    final years = List.generate(80, (i) => '${DateTime.now().year - 18 - i}');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: _animatedStep(_currentStep(flavor, days, months, years)),
            ),
            if (_step < _stepCount - 1)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  16 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: PillButton(
                  label: 'Continue',
                  loading: _loading,
                  onPressed: () => _saveStep(complete: false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stepWho(GymFlavor flavor) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(child: _stepIcon(Icons.person_outline)),
        const SizedBox(height: 24),
        Text('Who are you?', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: _pickPhoto,
            child: CircleAvatar(
              radius: 56,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              backgroundImage: _avatarBytes != null ? MemoryImage(_avatarBytes!) : null,
              child: _avatarBytes == null
                  ? Icon(Icons.add_a_photo_outlined, size: 40, color: Theme.of(context).colorScheme.primary)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 24),
        StitchTextField(controller: _firstCtrl, label: 'First name', icon: Icons.badge_outlined),
        const SizedBox(height: 24),
        StitchTextField(controller: _lastCtrl, label: 'Last name', icon: Icons.badge_outlined),
        if (_error != null) ...[
          const SizedBox(height: 24),
          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ],
    );
  }

  Widget _stepGender() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(child: _stepIcon(Icons.wc_outlined)),
        const SizedBox(height: 24),
        Text('About you', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        Row(
          children: [
            _genderTile('female', Icons.female),
            const SizedBox(width: 12),
            _genderTile('male', Icons.male),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _genderTile('nonbinary', Icons.transgender),
            const SizedBox(width: 12),
            _genderTile('skip', Icons.remove_circle_outline),
          ],
        ),
      ],
    );
  }

  Widget _stepDob(List<String> days, List<String> months, List<String> years) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(child: _stepIcon(Icons.cake_outlined)),
        const SizedBox(height: 24),
        Text('Birthday', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        Row(
          children: [
            _dobSelect('Day', _day, days, (v) => setState(() => _day = v)),
            const SizedBox(width: 12),
            _dobSelect('Month', _month, months, (v) => setState(() => _month = v)),
            const SizedBox(width: 12),
            _dobSelect('Year', _year, years.map((e) => e.toString()).toList(), (v) => setState(() => _year = v)),
          ],
        ),
      ],
    );
  }

  Widget _stepContact() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(child: _stepIcon(Icons.contact_phone_outlined)),
        const SizedBox(height: 24),
        Text('Stay in touch', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        StitchTextField(
          controller: _phoneCtrl,
          label: 'Phone',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 24),
        StitchTextField(controller: _igCtrl, label: 'Instagram', icon: Icons.alternate_email),
        const SizedBox(height: 24),
        StitchTextField(controller: _fbCtrl, label: 'Facebook', icon: Icons.facebook),
      ],
    );
  }

  Widget _stepCongrats(GymFlavor flavor) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 40),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Center(child: GymLogo(flavor: flavor, size: 96)),
        ),
        const SizedBox(height: 24),
        Text(
          'You\'re in!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome to ${flavor.gymName}.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        PillButton(
          label: "Let's go",
          loading: _loading,
          onPressed: () => _saveStep(complete: true),
        ),
        if (_error != null) ...[
          const SizedBox(height: 24),
          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ],
    );
  }
}
