import 'package:flutter/material.dart';

import '../../flavor/gym_flavor_service.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final flavor = GymFlavorService.instance.flavor!;
    return Scaffold(
      appBar: AppBar(title: const Text('Classes')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Book at ${flavor.gymName}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Class schedule will load from staff_bookings API when member endpoints are wired.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.fitness_center,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('No classes loaded'),
              subtitle: const Text('Pull to refresh — coming soon'),
            ),
          ),
        ],
      ),
    );
  }
}
