import 'package:flutter/material.dart';

import '../models/social_platform.dart';
import 'stitch_text_field.dart';

class SocialLinksEditor extends StatefulWidget {
  const SocialLinksEditor({
    super.key,
    required this.links,
    required this.editing,
    this.maxLinks = 5,
    this.onChanged,
  });

  final Map<String, String> links;
  final bool editing;
  final int maxLinks;
  final ValueChanged<Map<String, String>>? onChanged;

  @override
  State<SocialLinksEditor> createState() => SocialLinksEditorState();
}

class SocialLinksEditorState extends State<SocialLinksEditor> {
  final List<_SocialEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _syncFromLinks(widget.links);
  }

  @override
  void didUpdateWidget(SocialLinksEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.editing && oldWidget.links != widget.links) {
      _disposeEntries();
      _syncFromLinks(widget.links);
    }
  }

  @override
  void dispose() {
    _disposeEntries();
    super.dispose();
  }

  void _disposeEntries() {
    for (final e in _entries) {
      e.controller.dispose();
    }
    _entries.clear();
  }

  void _syncFromLinks(Map<String, String> links) {
    links.forEach((platform, url) {
      if (url.trim().isEmpty) return;
      _entries.add(_SocialEntry(
        platform: socialPlatformFromKey(platform),
        url: url,
      ));
    });
  }

  Map<String, String> collectLinks() {
    final out = <String, String>{};
    for (final e in _entries) {
      final url = e.controller.text.trim();
      if (url.isEmpty) continue;
      out[e.platform.key] = url;
    }
    return out;
  }

  void _notify() {
    widget.onChanged?.call(collectLinks());
  }

  Future<void> _pickPlatform(_SocialEntry entry) async {
    final picked = await showModalBottomSheet<SocialPlatform>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: SocialPlatform.values
              .map(
                (p) => ListTile(
                  leading: Icon(p.icon),
                  title: Text(p.label),
                  onTap: () => Navigator.pop(ctx, p),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (picked == null) return;
    setState(() => entry.platform = picked);
    _notify();
  }

  void _addLink() {
    if (_entries.length >= widget.maxLinks) return;
    setState(() => _entries.add(_SocialEntry(platform: SocialPlatform.instagram)));
    _notify();
  }

  void _removeLink(int index) {
    setState(() {
      _entries[index].controller.dispose();
      _entries.removeAt(index);
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.editing) {
      if (_entries.isEmpty && widget.links.isEmpty) {
        return Text(
          'No social links yet.',
          style: Theme.of(context).textTheme.bodyMedium,
        );
      }
      final display = widget.links.isNotEmpty ? widget.links : collectLinks();
      if (display.isEmpty) {
        return Text(
          'No social links yet.',
          style: Theme.of(context).textTheme.bodyMedium,
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: display.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    socialPlatformFromKey(e.key).label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: Text(
                    e.value,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    if (_entries.isEmpty) {
      _entries.add(_SocialEntry(platform: SocialPlatform.instagram));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(_entries.length, (i) {
          final entry = _entries[i];
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
                      onTap: () => _pickPlatform(entry),
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
                  onPressed: () => _removeLink(i),
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _entries.length >= widget.maxLinks ? null : _addLink,
            icon: const Icon(Icons.add, size: 18),
            label: Text('Add link (${_entries.length}/${widget.maxLinks})'),
          ),
        ),
      ],
    );
  }
}

class _SocialEntry {
  _SocialEntry({required this.platform, String url = ''})
      : controller = TextEditingController(text: url);

  SocialPlatform platform;
  final TextEditingController controller;
}
