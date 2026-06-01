import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

Future<void> showMemberCardModal(
  BuildContext context, {
  required String memberName,
  required String gymName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _MemberCardSheet(
      memberName: memberName,
      gymName: gymName,
    ),
  );
}

class _MemberCardSheet extends StatelessWidget {
  const _MemberCardSheet({
    required this.memberName,
    required this.gymName,
  });

  final String memberName;
  final String gymName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? TitanTheme.surfaceContainerDark : TitanTheme.surfaceLight;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? TitanTheme.borderDark : TitanTheme.borderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Icon(Icons.badge_outlined, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(gymName.toUpperCase(), style: theme.textTheme.labelSmall),
            const SizedBox(height: 8),
            Text(
              memberName,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Member',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Check in at the front desk with your physical NFC membership card.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/wallet');
                    },
                    child: const Text('Wallet'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
