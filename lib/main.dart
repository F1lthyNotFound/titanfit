import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'flavor/gym_flavor_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_service.dart';

late final GoRouter _appRouter;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeService.instance.init();
  await GymFlavorService.instance.init();
  await GymFlavorService.instance.bootstrapFlavor();
  _appRouter = AppRouter.create();
  runApp(const TitanFitApp());
}

class TitanFitApp extends StatelessWidget {
  const TitanFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        GymFlavorService.instance,
        ThemeService.instance,
      ]),
      builder: (context, _) {
        final flavor = GymFlavorService.instance.flavor;
        return MaterialApp.router(
          title: flavor?.gymName ?? 'TitanFit',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeService.instance.mode,
          theme: AppTheme.buildLight(flavor),
          darkTheme: AppTheme.build(flavor),
          routerConfig: _appRouter,
        );
      },
    );
  }
}
