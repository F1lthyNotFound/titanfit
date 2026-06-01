import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/api_config.dart';
import '../../flavor/gym_flavor.dart';
import '../../flavor/gym_flavor_service.dart';
import '../../services/auth_service.dart';
import '../../services/member_service.dart';
import '../../theme/accessibility_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_service.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gym_logo.dart';
import '../../widgets/social_links_editor.dart';
import '../../widgets/stitch_text_field.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  MemberProfile? _profile;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;
  String? _error;

  final _socialEditorKey = GlobalKey<SocialLinksEditorState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _phoneCtrl.dispose();
    _genderCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) return;
    final profile = await MemberService.forFlavor(flavor).fetchProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
    });
    _syncFields(profile);
  }

  void _syncFields(MemberProfile? profile) {
    if (profile == null) return;
    _firstCtrl.text = profile.firstName;
    _lastCtrl.text = profile.lastName;
    _phoneCtrl.text = profile.phone;
    _genderCtrl.text = profile.gender;
  }

  Map<String, String> get _displaySocialLinks {
    final p = _profile;
    if (p == null) return {};
    if (p.socialLinks.isNotEmpty) return p.socialLinks;
    final links = <String, String>{};
    if (p.socialInstagram.isNotEmpty) links['instagram'] = p.socialInstagram;
    if (p.socialFacebook.isNotEmpty) links['facebook'] = p.socialFacebook;
    return links;
  }

  String? get _avatarUrl {
    final path = _profile?.avatarUrl ?? '';
    if (path.isEmpty) return null;
    final flavor = GymFlavorService.instance.flavor;
    final base = flavor?.apiBase.isNotEmpty == true
        ? flavor!.apiBase
        : ApiConfig.defaultApiBase;
    return path.startsWith('http') ? path : '$base$path';
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _editing = true);
    await _save(avatarBytes: bytes);
  }

  Future<void> _save({List<int>? avatarBytes}) async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) return;
    final socialLinks = _socialEditorKey.currentState?.collectLinks() ?? _displaySocialLinks;
    if (socialLinks.length > 5) {
      setState(() => _error = 'Maximum 5 social links');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await MemberService.forFlavor(flavor).saveProfile(
      firstName: _firstCtrl.text.trim(),
      lastName: _lastCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      gender: _genderCtrl.text.trim(),
      socialLinks: socialLinks,
      avatarBytes: avatarBytes,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.ok) {
      setState(() => _editing = false);
      await _load();
    } else {
      setState(() => _error = result.message.isNotEmpty ? result.message : 'Could not save profile');
    }
  }

  Future<void> _logout(BuildContext context) async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor != null) {
      await AuthService.forFlavor(flavor).logout();
    }
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final flavor = GymFlavorService.instance.flavor!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: Listenable.merge([
        ThemeService.instance,
        AccessibilityService.instance,
      ]),
      builder: (context, _) => _buildBody(context, flavor, isDark),
    );
  }

  Widget _buildBody(BuildContext context, GymFlavor flavor, bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? TitanTheme.canvasDark : TitanTheme.canvasLight,
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: isDark ? TitanTheme.canvasDark : TitanTheme.canvasLight,
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _saving
                  ? null
                  : () {
                      if (_editing) {
                        _save();
                      } else {
                        setState(() => _editing = true);
                      }
                    },
              child: Text(_editing ? 'Save' : 'Edit'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    _loading
                        ? const SizedBox(
                            width: 88,
                            height: 88,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : (_avatarUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(44),
                                child: CachedNetworkImage(
                                  imageUrl: _avatarUrl!,
                                  width: 88,
                                  height: 88,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      GymLogo(flavor: flavor, size: 88),
                                ),
                              )
                            : GymLogo(flavor: flavor, size: 88)),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _profile != null &&
                        '${_profile!.firstName} ${_profile!.lastName}'.trim().isNotEmpty
                    ? '${_profile!.firstName} ${_profile!.lastName}'.trim()
                    : flavor.gymName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            if (_profile?.username.isNotEmpty == true)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '@${_profile!.username}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.orangeAccent)),
              ),
            GlassPanel(
              child: _editing
                  ? Column(
                      children: [
                        StitchTextField(
                          controller: _firstCtrl,
                          label: 'First name',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 12),
                        StitchTextField(
                          controller: _lastCtrl,
                          label: 'Last name',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 12),
                        StitchTextField(
                          controller: _phoneCtrl,
                          label: 'Phone',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        StitchTextField(
                          controller: _genderCtrl,
                          label: 'Gender',
                          icon: Icons.wc_outlined,
                        ),
                        if (_profile?.email.isNotEmpty == true) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Email: ${_profile!.email}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    )
                  : Column(
                      children: [
                        if (_profile?.email.isNotEmpty == true)
                          _InfoRow(label: 'Email', value: _profile!.email),
                        if (_profile?.phone.isNotEmpty == true)
                          _InfoRow(label: 'Phone', value: _profile!.phone),
                        if (_profile?.gender.isNotEmpty == true)
                          _InfoRow(label: 'Gender', value: _profile!.gender),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text('SOCIALS', style: Theme.of(context).textTheme.labelSmall),
                      const Spacer(),
                      Text(
                        'Max 5',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SocialLinksEditor(
                    key: _socialEditorKey,
                    links: _displaySocialLinks,
                    editing: _editing,
                    maxLinks: 5,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('APPEARANCE', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dark mode'),
                    subtitle: const Text('Switch between light and dark theme'),
                    value: ThemeService.instance.isDark,
                    onChanged: (on) => ThemeService.instance.setMode(
                      on ? ThemeMode.dark : ThemeMode.light,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('ACCESSIBILITY', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 8),
                  Text('Text size', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<double>(
                    segments: const [
                      ButtonSegment(value: 1.0, label: Text('Default')),
                      ButtonSegment(value: 1.12, label: Text('Large')),
                      ButtonSegment(value: 1.24, label: Text('XL')),
                    ],
                    selected: {AccessibilityService.instance.textScale},
                    onSelectionChanged: (values) {
                      AccessibilityService.instance.setTextScale(values.first);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Bold text'),
                    value: AccessibilityService.instance.boldText,
                    onChanged: AccessibilityService.instance.setBoldText,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Reduce motion'),
                    value: AccessibilityService.instance.reduceMotion,
                    onChanged: AccessibilityService.instance.setReduceMotion,
                  ),
                  const SizedBox(height: 4),
                  Text('Color vision', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ColorBlindMode>(
                    key: ValueKey(AccessibilityService.instance.colorBlindMode),
                    initialValue: AccessibilityService.instance.colorBlindMode,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: ColorBlindMode.off, child: Text('Off')),
                      DropdownMenuItem(value: ColorBlindMode.protanopia, child: Text('Protanopia')),
                      DropdownMenuItem(value: ColorBlindMode.deuteranopia, child: Text('Deuteranopia')),
                      DropdownMenuItem(value: ColorBlindMode.tritanopia, child: Text('Tritanopia')),
                    ],
                    onChanged: (mode) {
                      if (mode != null) {
                        AccessibilityService.instance.setColorBlindMode(mode);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('SECURITY', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_reset_outlined),
                    title: const Text('Reset password'),
                    subtitle: const Text('Email link to gym-branded reset page'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/forgot-password'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassPanel(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.badge_outlined),
                title: const Text('ID verification'),
                subtitle: const Text('Submit IDs and view approved badges'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/id-verification'),
              ),
            ),
            const SizedBox(height: 16),
            GlassPanel(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
