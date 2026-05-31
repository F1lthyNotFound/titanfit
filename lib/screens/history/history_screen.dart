import 'package:flutter/material.dart';

import '../../widgets/glass_panel.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: const Color(0xFF000000),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.history,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No visits yet',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Check-ins, bookings, and class history appear here when '
                  'attendance syncs with your gym.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassPanel(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.event_note_outlined,
                    color: Theme.of(context).colorScheme.outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Past sessions will show date, activity, and branch.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
