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
  final _pageCtrl = PageController();
  int _step = 0;
  bool _loading = false;
  String? _error;

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
    _pageCtrl.dispose();
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

  void _next() {
    if (_step < 4) {
      setState(() => _step++);
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
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
    final progress = (_step + 1) / 5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back)),
              Expanded(
                child: Text(
                  'Step ${_step + 1} of 5',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              if (_step < 4)
                TextButton(onPressed: _next, child: const Text('Skip'))
              else
                const SizedBox(width: 64),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              widthFactor: progress,
              alignment: Alignment.centerLeft,
              child: Container(
                height: 4,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 4,
            child: Container(color: Theme.of(context).dividerColor),
          ),
        ],
      ),
    );
  }

  Widget _genderTile(String value, String label, IconData icon) {
    final selected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dobSelect(String label, String value, List<String> items, ValueChanged<String> onChanged) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        value: value.isEmpty ? null : value,
        decoration: InputDecoration(labelText: label),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) => onChanged(v ?? ''),
      ),
    );
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
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _stepWho(flavor),
                  _stepGender(),
                  _stepDob(days, months, years),
                  _stepContact(),
                  _stepCongrats(flavor),
                ],
              ),
            ),
            if (_step < 4)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  16 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: PillButton(
                  label: _step == 3 ? 'Continue' : 'Continue',
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
      padding: const EdgeInsets.all(20),
      children: [
        Text('Who are you?', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('Add your name and a profile photo.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: _pickPhoto,
            child: CircleAvatar(
              radius: 52,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              backgroundImage: _avatarBytes != null ? MemoryImage(_avatarBytes!) : null,
              child: _avatarBytes == null
                  ? const Icon(Icons.add_a_photo_outlined, size: 36)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('Tap to upload (max 2MB)', style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(height: 24),
        StitchTextField(controller: _firstCtrl, label: 'First name', icon: Icons.badge_outlined),
        const SizedBox(height: 12),
        StitchTextField(controller: _lastCtrl, label: 'Last name', icon: Icons.badge_outlined),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ],
    );
  }

  Widget _stepGender() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Tell us about yourself', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('This helps personalize your experience.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        Row(
          children: [
            _genderTile('female', 'Female', Icons.female),
            const SizedBox(width: 8),
            _genderTile('male', 'Male', Icons.male),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _genderTile('nonbinary', 'Non-binary', Icons.transgender),
            const SizedBox(width: 8),
            _genderTile('skip', 'Skip', Icons.remove_circle_outline),
          ],
        ),
      ],
    );
  }

  Widget _stepDob(List<String> days, List<String> months, List<String> years) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('When were you born?', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('Used for age-appropriate programs.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        Row(
          children: [
            _dobSelect('Day', _day, days, (v) => setState(() => _day = v)),
            const SizedBox(width: 8),
            _dobSelect('Month', _month, months, (v) => setState(() => _month = v)),
            const SizedBox(width: 8),
            _dobSelect('Year', _year, years.map((e) => e.toString()).toList(), (v) => setState(() => _year = v)),
          ],
        ),
      ],
    );
  }

  Widget _stepContact() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Final touch.', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('Phone and social links (optional).', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        StitchTextField(
          controller: _phoneCtrl,
          label: 'Phone',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        StitchTextField(controller: _igCtrl, label: 'Instagram (optional)', icon: Icons.alternate_email),
        const SizedBox(height: 12),
        StitchTextField(controller: _fbCtrl, label: 'Facebook (optional)', icon: Icons.facebook),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.lock_outline, size: 18, color: Theme.of(context).colorScheme.outline),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'We only use this to reach you about your membership.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepCongrats(GymFlavor flavor) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 40),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Center(child: GymLogo(flavor: flavor, size: 88)),
        ),
        const SizedBox(height: 24),
        Text(
          'Congratulations!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'You\'re set up with ${flavor.gymName}. Start booking classes and tracking your membership.',
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
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ],
    );
  }
}
