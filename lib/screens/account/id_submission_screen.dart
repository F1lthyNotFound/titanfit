import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../flavor/gym_flavor_service.dart';
import '../../services/member_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_compress.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/pill_button.dart';

class IdSubmissionScreen extends StatefulWidget {
  const IdSubmissionScreen({super.key});

  @override
  State<IdSubmissionScreen> createState() => _IdSubmissionScreenState();
}

class _IdSubmissionScreenState extends State<IdSubmissionScreen> {
  List<MemberIdType> _types = [];
  MemberIdSubmissionBundle? _bundle;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  int? _selectedTypeId;
  final _photoBytes = <int, Uint8List>{};
  final _photoSizes = <int, String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) return;
    final member = MemberService.forFlavor(flavor);
    final results = await Future.wait([
      member.fetchIdTypes(),
      member.fetchIdSubmissions(),
    ]);
    if (!mounted) return;
    setState(() {
      _types = results[0] as List<MemberIdType>;
      _bundle = results[1] as MemberIdSubmissionBundle?;
      _loading = false;
      if (_selectedTypeId == null && _types.isNotEmpty) {
        _selectedTypeId = _types.first.id;
      }
    });
  }

  MemberIdType? get _selectedType {
    if (_selectedTypeId == null) return null;
    for (final t in _types) {
      if (t.id == _selectedTypeId) return t;
    }
    return null;
  }

  Future<void> _pickPhoto(int index, ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, maxWidth: 2400, imageQuality: 92);
    if (file == null) return;
    final raw = await file.readAsBytes();
    final compressed = await compressImageForUpload(raw);
    if (!mounted) return;
    setState(() {
      _photoBytes[index] = compressed;
      _photoSizes[index] = formatBytes(compressed.length);
      _error = null;
    });
  }

  Future<void> _submit() async {
    final type = _selectedType;
    if (type == null) {
      setState(() => _error = 'Select an ID type');
      return;
    }
    final reqs = type.requirements.isEmpty
        ? [const IdPhotoRequirement(label: 'Photo')]
        : type.requirements;
    final images = <List<int>>[];
    for (var i = 0; i < reqs.length; i++) {
      final bytes = _photoBytes[i];
      if (bytes == null) {
        setState(() => _error = 'Upload: ${reqs[i].label}');
        return;
      }
      images.add(bytes);
    }

    final flavor = GymFlavorService.instance.flavor!;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final res = await MemberService.forFlavor(flavor).submitId(
      idTypeId: type.id,
      images: images,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.ok) {
      _photoBytes.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message.isNotEmpty ? res.message : 'Submitted')),
      );
      await _load();
    } else {
      setState(() => _error = res.message.isNotEmpty ? res.message : 'Could not submit');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final earned = _bundle?.earned ?? const [];
    final pending = (_bundle?.items ?? const [])
        .where((s) => s.isPending)
        .toList();
    final rejected = (_bundle?.items ?? const [])
        .where((s) => s.isRejected)
        .toList();
    final selected = _selectedType;
    final reqs = selected == null
        ? const <IdPhotoRequirement>[]
        : (selected.requirements.isEmpty
            ? [const IdPhotoRequirement(label: 'Photo')]
            : selected.requirements);

    return Scaffold(
      backgroundColor: isDark ? TitanTheme.canvasDark : TitanTheme.canvasLight,
      appBar: AppBar(
        title: const Text('ID verification'),
        backgroundColor: isDark ? TitanTheme.canvasDark : TitanTheme.canvasLight,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (earned.isNotEmpty) ...[
                    Text('Your IDs', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ...earned.map((s) => _EarnedCard(submission: s)),
                    const SizedBox(height: 24),
                  ],
                  if (pending.isNotEmpty) ...[
                    Text('Pending review', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ...pending.map((s) => _StatusCard(submission: s)),
                    const SizedBox(height: 24),
                  ],
                  if (rejected.isNotEmpty) ...[
                    Text('Needs resubmission', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ...rejected.map((s) => _StatusCard(submission: s)),
                    const SizedBox(height: 24),
                  ],
                  Text('Submit new ID', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (_types.isEmpty)
                    Text(
                      'No ID types configured yet. Ask staff to set up ID types.',
                      style: theme.textTheme.bodyMedium,
                    )
                  else ...[
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'ID type'),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: _selectedTypeId,
                          items: _types
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t.id,
                                  child: Text(t.label),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() {
                            _selectedTypeId = v;
                            _photoBytes.clear();
                            _error = null;
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(reqs.length, (i) {
                      final preview = _photoBytes[i];
                      final sizeLabel = _photoSizes[i];
                      return FadeSlideIn(
                        delay: Duration(milliseconds: 40 * i),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(reqs[i].label, style: theme.textTheme.labelLarge),
                              const SizedBox(height: 8),
                              if (preview != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(preview, height: 140, fit: BoxFit.cover),
                                ),
                              if (sizeLabel != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Compressed to $sizeLabel (max 2 MB)',
                                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _pickPhoto(i, ImageSource.camera),
                                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                                      label: Text(preview == null ? 'Camera' : 'Retake'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _pickPhoto(i, ImageSource.gallery),
                                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                                      label: const Text('Gallery'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                    ],
                    const SizedBox(height: 12),
                    PillButton(
                      label: 'Submit for review',
                      loading: _submitting,
                      onPressed: _submit,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _EarnedCard extends StatelessWidget {
  const _EarnedCard({required this.submission});

  final MemberIdSubmission submission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = submission.daysRemaining != null
        ? submission.daysRemaining! > 0
            ? '${submission.daysRemaining} days left'
            : 'Expired'
        : 'Approved';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(Icons.verified_outlined, color: theme.colorScheme.primary),
        title: Text(submission.typeLabel),
        subtitle: Text(meta),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.submission});

  final MemberIdSubmission submission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = submission.isPending;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          isPending ? Icons.hourglass_top : Icons.cancel_outlined,
          color: isPending ? theme.colorScheme.primary : theme.colorScheme.error,
        ),
        title: Text(submission.typeLabel),
        subtitle: Text(
          isPending
              ? 'Awaiting staff review'
              : (submission.rejectionComment.isNotEmpty
                  ? submission.rejectionComment
                  : 'Rejected — submit again'),
        ),
      ),
    );
  }
}
