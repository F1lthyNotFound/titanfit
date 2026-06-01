import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../config/app_version.dart';
import '../../flavor/gym_flavor.dart';
import '../../flavor/gym_flavor_service.dart';
import '../../services/member_service.dart';
import '../../theme/theme_service.dart';
import '../../widgets/gym_logo.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/stitch_text_field.dart';

enum SocialPlatform { facebook, instagram, whatsapp, other }

extension SocialPlatformX on SocialPlatform {
  String get key => name;

  String get label => switch (this) {
        SocialPlatform.facebook => 'Facebook',
        SocialPlatform.instagram => 'Instagram',
        SocialPlatform.whatsapp => 'WhatsApp',
        SocialPlatform.other => 'Other',
      };

  IconData get icon => switch (this) {
        SocialPlatform.facebook => Icons.facebook,
        SocialPlatform.instagram => Icons.alternate_email,
        SocialPlatform.whatsapp => Icons.chat_outlined,
        SocialPlatform.other => Icons.link,
      };
}

class _SocialEntry {
  _SocialEntry({required this.platform, String url = ''})
      : controller = TextEditingController(text: url);

  SocialPlatform platform;
  final TextEditingController controller;
}

class MemberOnboardingScreen extends StatefulWidget {
  const MemberOnboardingScreen({super.key});

  @override
  State<MemberOnboardingScreen> createState() => _MemberOnboardingScreenState();
}

class _MemberOnboardingScreenState extends State<MemberOnboardingScreen> {
  int _step = 0;
  bool _loading = false;
  String? _error;

  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final List<_SocialEntry> _socialEntries = [];

  String _gender = '';
  String _day = '';
  String _month = '';
  String _year = '';
  Uint8List? _avatarBytes;

  static const _stepCount = 5;

  static const _steps = <(String title, String subtitle)>[
    ('Your profile', 'Photo and name for your gym ID'),
    ('About you', 'Pick what fits — or skip'),
    ('Birthday', 'Optional — for age-based programs'),
    ('Stay in touch', 'Phone and social links'),
    ('You\'re in', ''),
  ];

  static SocialPlatform _platformFromKey(String platform) {
    for (final p in SocialPlatform.values) {
      if (p.key == platform) return p;
    }
    return SocialPlatform.other;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) return;
    final profile = await MemberService.forFlavor(flavor).fetchProfile();
    if (profile == null || !mounted) return;
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
    for (final e in _socialEntries) {
      e.controller.dispose();
    }
    _socialEntries.clear();
    profile.socialLinks.forEach((platform, url) {
      _socialEntries.add(_SocialEntry(platform: _platformFromKey(platform), url: url));
    });
    setState(() {});
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _phoneCtrl.dispose();
    for (final e in _socialEntries) {
      e.controller.dispose();
    }
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

  void _goToStep(int next) {
    setState(() {
      _step = next;
      _error = null;
    });
  }

  void _next() {
    if (_step < _stepCount - 1) _goToStep(_step + 1);
  }

  void _back() {
    if (_step > 0) {
      _goToStep(_step - 1);
    } else {
      context.go('/login');
    }
  }

  String? _dobIso() {
    if (_year.isEmpty || _month.isEmpty || _day.isEmpty) return null;
    return '${_year.padLeft(4, '0')}-${_month.padLeft(2, '0')}-${_day.padLeft(2, '0')}';
  }

  Map<String, String> _socialLinksPayload() {
    final out = <String, String>{};
    for (final e in _socialEntries) {
      final url = e.controller.text.trim();
      if (url.isEmpty) continue;
      out[e.platform.key] = url;
    }
    return out;
  }

  void _addSocialLink() {
    setState(() {
      _socialEntries.add(_SocialEntry(platform: SocialPlatform.instagram));
    });
  }

  void _removeSocialLink(int index) {
    setState(() {
      _socialEntries[index].controller.dispose();
      _socialEntries.removeAt(index);
    });
  }

  Future<void> _saveStep({bool complete = false}) async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) return;

    if (_step == 0 && _firstCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter your first name');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final member = MemberService.forFlavor(flavor);
    final result = await member.saveProfile(
      firstName: _step == 0 ? _firstCtrl.text.trim() : null,
      lastName: _step == 0 ? _lastCtrl.text.trim() : null,
      gender: _step == 1 && _gender.isNotEmpty ? _gender : null,
      dateOfBirth: _step == 2 ? _dobIso() : null,
      phone: _step == 3 ? _phoneCtrl.text.trim() : null,
      socialLinks: _step == 3 ? _socialLinksPayload() : null,
      avatarBytes: _step == 0 ? _avatarBytes : null,
      complete: complete,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.ok) {
      setState(() => _error = result.message.isNotEmpty ? result.message : 'Could not save — try again');
      return;
    }

    if (complete) {
      await GymFlavorService.instance.setSession(
        loggedIn: true,
        onboardingComplete: true,
      );
      if (mounted) context.go('/home');
    } else {
      _next();
    }
  }

  Widget _header() {
    final primary = Theme.of(context).colorScheme.primary;
    final (title, subtitle) = _steps[_step];
    final themeService = ThemeService.instance;
    final progress = (_step + 1) / _stepCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: themeService.isDark ? 'Light mode' : 'Dark mode',
                onPressed: themeService.toggle,
                icon: Icon(themeService.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              ),
              IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back)),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: Colors.transparent,
                    color: primary,
                  ),
                ),
              ),
              if (_step < _stepCount - 1)
                TextButton(
                  onPressed: _next,
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: const Text('Skip for now'),
                )
              else
                const SizedBox(width: 72),
            ],
          ),
          if (_step < _stepCount - 1) ...[
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
          ],
        ],
      ),
    );
  }

  double get _keyboardPad => MediaQuery.viewInsetsOf(context).bottom;

  Widget _scrollStep({required List<Widget> children, bool keyboard = false}) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(24, 24, 24, 120 + (keyboard ? _keyboardPad : 0)),
      children: children,
    );
  }

  Widget _stepIcon(IconData icon) {
    return Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary);
  }

  Widget _genderTile(String value, IconData icon, {String? label}) {
    final selected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(vertical: label == null ? 24 : 16),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: label == null ? 36 : 28,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              if (label != null) ...[
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromSheet({
    required String title,
    required List<String> items,
    required String current,
    required ValueChanged<String> onPick,
  }) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(title, style: Theme.of(ctx).textTheme.titleSmall),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final selected = item == current;
                    return ListTile(
                      dense: true,
                      title: Text(item, style: Theme.of(ctx).textTheme.bodyLarge),
                      trailing: selected ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary) : null,
                      onTap: () => Navigator.pop(ctx, item),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (picked != null) onPick(picked);
  }

  Widget _compactPicker({
    required String hint,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    final theme = Theme.of(context);
    final display = value.isEmpty ? hint : value;

    return Expanded(
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _pickFromSheet(
            title: hint,
            items: items,
            current: value,
            onPick: onChanged,
          ),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: Text(
              display,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: value.isEmpty ? theme.colorScheme.outline : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialRow(int index, _SocialEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _pickFromSheet(
                  title: 'Platform',
                  items: SocialPlatform.values.map((p) => p.label).toList(),
                  current: entry.platform.label,
                  onPick: (label) {
                    final p = SocialPlatform.values.firstWhere((v) => v.label == label);
                    setState(() => entry.platform = p);
                  },
                ),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Icon(entry.platform.icon, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          entry.platform.label,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 13),
                        ),
                      ),
                      Icon(Icons.expand_more, size: 18, color: Theme.of(context).colorScheme.outline),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StitchTextField(
              controller: entry.controller,
              hint: 'Paste link or handle',
              icon: entry.platform.icon,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => _removeSocialLink(index),
          ),
        ],
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
    final years = List.generate(80, (i) => '${DateTime.now().year - 18 - i}'.toString());

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 12, top: 2),
                child: Text(
                  'v$kAppVersion',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ),
            ),
            _header(),
            Expanded(
              child: _currentStep(flavor, days, months, years),
            ),
            if (_step < _stepCount - 1)
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + _keyboardPad),
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
    return _scrollStep(
      keyboard: true,
      children: [
        Center(child: _stepIcon(Icons.person_outline)),
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
        StitchTextField(
          controller: _firstCtrl,
          hint: 'First name',
          icon: Icons.badge_outlined,
          textInputAction: TextInputAction.next,
          autofocus: true,
        ),
        const SizedBox(height: 16),
        StitchTextField(
          controller: _lastCtrl,
          hint: 'Last name',
          icon: Icons.badge_outlined,
          textInputAction: TextInputAction.done,
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ],
    );
  }

  Widget _stepGender() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      children: [
        Center(child: _stepIcon(Icons.wc_outlined)),
        const SizedBox(height: 24),
        Row(
          children: [
            _genderTile('female', Icons.female, label: 'Female'),
            const SizedBox(width: 12),
            _genderTile('male', Icons.male, label: 'Male'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _genderTile('nonbinary', Icons.transgender, label: 'Non-binary'),
            const SizedBox(width: 12),
            _genderTile('prefer_not_to_say', Icons.visibility_off_outlined, label: 'Prefer not to say'),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ],
    );
  }

  Widget _stepDob(List<String> days, List<String> months, List<String> years) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      children: [
        Center(child: _stepIcon(Icons.cake_outlined)),
        const SizedBox(height: 24),
        Row(
          children: [
            _compactPicker(hint: 'Day', value: _day, items: days, onChanged: (v) => setState(() => _day = v)),
            const SizedBox(width: 8),
            _compactPicker(hint: 'Month', value: _month, items: months, onChanged: (v) => setState(() => _month = v)),
            const SizedBox(width: 8),
            _compactPicker(hint: 'Year', value: _year, items: years, onChanged: (v) => setState(() => _year = v)),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ],
    );
  }

  Widget _stepContact() {
    return _scrollStep(
      keyboard: true,
      children: [
        Center(child: _stepIcon(Icons.contact_phone_outlined)),
        const SizedBox(height: 24),
        StitchTextField(
          controller: _phoneCtrl,
          hint: 'Phone number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text('Social links', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            TextButton.icon(
              onPressed: _addSocialLink,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        if (_socialEntries.isEmpty)
          Text(
            'Optional — tap Add to link Facebook, Instagram, WhatsApp, or other.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ...List.generate(_socialEntries.length, (i) => _socialRow(i, _socialEntries[i])),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
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
          builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
          child: Center(child: GymLogo(flavor: flavor, size: 96)),
        ),
        const SizedBox(height: 24),
        Text('You\'re in!', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 16),
        Text(
          'Welcome to ${flavor.gymName}.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        PillButton(label: "Let's go", loading: _loading, onPressed: () => _saveStep(complete: true)),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ],
    );
  }
}
