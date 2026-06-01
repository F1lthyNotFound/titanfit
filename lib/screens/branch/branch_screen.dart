import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../flavor/gym_flavor_service.dart';
import '../../services/member_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/media_image.dart';

class BranchScreen extends StatefulWidget {
  const BranchScreen({super.key});

  @override
  State<BranchScreen> createState() => _BranchScreenState();
}

class _BranchScreenState extends State<BranchScreen> {
  BranchInfo? _info;
  List<BranchListItem> _branches = [];
  bool _loading = true;
  bool _switching = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _loadBranches(_searchController.text.trim());
  }

  Future<void> _load() async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) return;
    setState(() => _loading = true);
    final member = MemberService.forFlavor(flavor);
    final results = await Future.wait([
      member.fetchBranchInfo(),
      member.fetchBranches(),
    ]);
    if (!mounted) return;
    setState(() {
      _info = results[0] as BranchInfo?;
      _branches = results[1] as List<BranchListItem>;
      _loading = false;
    });
  }

  Future<void> _loadBranches(String search) async {
    final flavor = GymFlavorService.instance.flavor;
    if (flavor == null) return;
    final list = await MemberService.forFlavor(flavor).fetchBranches(search: search);
    if (!mounted) return;
    setState(() => _branches = list);
  }

  Future<void> _switchBranch(BranchListItem branch) async {
    if (branch.isCurrent || _switching) return;
    final flavor = GymFlavorService.instance.flavor!;
    setState(() => _switching = true);
    final res = await MemberService.forFlavor(flavor).switchBranch(branch.id);
    if (!mounted) return;
    setState(() => _switching = false);
    if (res.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Switched to ${res.branchName.isNotEmpty ? res.branchName : branch.name}')),
      );
      context.pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message.isNotEmpty ? res.message : 'Could not switch branch')),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    var target = url.trim();
    if (!target.contains('://')) {
      target = 'https://$target';
    }
    final uri = Uri.tryParse(target);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final flavor = GymFlavorService.instance.flavor;
    final info = _info;

    return Scaffold(
      backgroundColor: isDark ? TitanTheme.canvasDark : TitanTheme.canvasLight,
      appBar: AppBar(
        title: const Text('Branch'),
        backgroundColor: isDark ? TitanTheme.canvasDark : TitanTheme.canvasLight,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _BranchHero(info: info, apiBase: flavor?.apiBase),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          info?.branchName.isNotEmpty == true ? info!.branchName : 'Branch',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 16),
                        if (info != null && info.displayAddress.isNotEmpty)
                          _DetailTile(
                            icon: Icons.location_on_outlined,
                            label: info.displayAddress,
                            onTap: info.mapsUrl.isNotEmpty ? () => _openUrl(info.mapsUrl) : null,
                          ),
                        if (info != null && info.phone.isNotEmpty)
                          _DetailTile(
                            icon: Icons.phone_outlined,
                            label: info.phone,
                            onTap: () => _openUrl('tel:${info.phone}'),
                          ),
                        if (info != null && info.gymWebsite.isNotEmpty)
                          _DetailTile(
                            icon: Icons.language_outlined,
                            label: 'Visit website',
                            onTap: () => _openUrl(info.gymWebsite),
                          ),
                        if (info != null && info.mapsUrl.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => _openUrl(info.mapsUrl),
                            icon: const Icon(Icons.map_outlined, size: 18),
                            label: const Text('View on Google Maps'),
                          ),
                        ],
                        const SizedBox(height: 28),
                        Text('Switch branch', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search branches…',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            filled: true,
                            fillColor: isDark ? TitanTheme.surfaceDark : TitanTheme.surfaceLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_branches.isEmpty)
                          Text('No branches found.', style: theme.textTheme.bodyMedium)
                        else
                          ..._branches.map((b) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: b.isCurrent
                                    ? theme.colorScheme.primary.withValues(alpha: 0.08)
                                    : (isDark ? TitanTheme.surfaceDark : TitanTheme.surfaceLight),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: b.isCurrent
                                      ? theme.colorScheme.primary
                                      : (isDark ? TitanTheme.borderDark : TitanTheme.borderLight),
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  b.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: b.isCurrent ? FontWeight.w700 : FontWeight.w600,
                                  ),
                                ),
                                subtitle: b.subtitle.isNotEmpty ? Text(b.subtitle) : null,
                                trailing: b.isCurrent
                                    ? Text('Current', style: theme.textTheme.labelSmall)
                                    : _switching
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.chevron_right),
                                onTap: b.isCurrent ? null : () => _switchBranch(b),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _BranchHero extends StatelessWidget {
  const _BranchHero({required this.info, this.apiBase});

  final BranchInfo? info;
  final String? apiBase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cover = info?.coverUrl ?? '';
    final logo = info?.logoUrl ?? '';

    if (cover.isEmpty && logo.isEmpty) {
      return Container(
        height: 160,
        color: theme.colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(Icons.storefront_outlined, size: 48, color: theme.colorScheme.outline),
      );
    }

    return SizedBox(
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (cover.isNotEmpty)
            MediaImage(source: cover, apiBase: apiBase, fit: BoxFit.cover)
          else
            Container(color: theme.colorScheme.surfaceContainerHighest),
          if (logo.isNotEmpty)
            Positioned(
              left: 20,
              bottom: 16,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: MediaImage(
                  source: logo,
                  apiBase: apiBase,
                  width: 64,
                  height: 64,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.outline),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
              if (onTap != null)
                Icon(Icons.open_in_new, size: 16, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
