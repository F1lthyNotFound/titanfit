import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/api_config.dart';
import '../../flavor/gym_flavor_service.dart';
import '../../services/auth_service.dart';
import '../../services/member_service.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/gym_logo.dart';
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
  String? _idType;
  Uint8List? _idPreview;

  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();

  static const _idTypes = [
    'Government ID',
    'Student ID',
    'Senior / PWD ID',
    'Company ID',
  ];

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
    _instagramCtrl.dispose();
    _facebookCtrl.dispose();
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
    _instagramCtrl.text = profile.socialInstagram;
    _facebookCtrl.text = profile.socialFacebook;
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
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await MemberService.forFlavor(flavor).saveProfile(
      firstName: _firstCtrl.text.trim(),
      lastName: _lastCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      gender: _genderCtrl.text.trim(),
      socialInstagram: _instagramCtrl.text.trim(),
      socialFacebook: _facebookCtrl.text.trim(),
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

  Future<void> _pickIdPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, maxWidth: 1600);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _idPreview = bytes);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ID photo captured — submission coming soon')),
    );
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

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: const Color(0xFF000000),
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
                        const SizedBox(height: 12),
                        StitchTextField(
                          controller: _instagramCtrl,
                          label: 'Instagram',
                          icon: Icons.alternate_email,
                        ),
                        const SizedBox(height: 12),
                        StitchTextField(
                          controller: _facebookCtrl,
                          label: 'Facebook',
                          icon: Icons.facebook_outlined,
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
                        if (_profile?.socialInstagram.isNotEmpty == true)
                          _InfoRow(label: 'Instagram', value: _profile!.socialInstagram),
                        if (_profile?.socialFacebook.isNotEmpty == true)
                          _InfoRow(label: 'Facebook', value: _profile!.socialFacebook),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('ID VERIFICATION', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _idType,
                    decoration: const InputDecoration(labelText: 'ID type'),
                    items: _idTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _idType = v),
                  ),
                  const SizedBox(height: 12),
                  if (_idPreview != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(_idPreview!, height: 120, fit: BoxFit.cover),
                    ),
                  const SizedBox(height: 12),
                  PillButton(
                    label: 'Take ID photo',
                    icon: Icons.add_a_photo_outlined,
                    onPressed: _idType == null ? null : _pickIdPhoto,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload UI only — staff approval flow coming soon.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
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
