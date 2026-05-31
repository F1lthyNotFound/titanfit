import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../flavor/gym_flavor.dart';

class GymLogo extends StatelessWidget {
  const GymLogo({super.key, required this.flavor, this.size = 64});

  final GymFlavor flavor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = flavor.logoUrl;
    if (url.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.fitness_center, size: size * 0.5),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Icon(Icons.fitness_center, size: size * 0.4),
      ),
    );
  }
}
