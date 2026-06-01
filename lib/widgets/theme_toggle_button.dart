import 'package:flutter/material.dart';

import '../theme/theme_service.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService.instance;
    return IconButton(
      tooltip: themeService.isDark ? 'Light mode' : 'Dark mode',
      onPressed: themeService.toggle,
      icon: Icon(
        themeService.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      ),
    );
  }
}
