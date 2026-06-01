import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'flavor/gym_flavor_service.dart';
import 'router/app_router.dart';
import 'theme/accessibility_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_service.dart';

late final GoRouter _appRouter;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeService.instance.init();
  await AccessibilityService.instance.init();
  await GymFlavorService.instance.init();
  await GymFlavorService.instance.bootstrapFlavor();
  if (GymFlavorService.instance.isLoggedIn) {
    await GymFlavorService.instance.validateAuthSession();
  }
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
        AccessibilityService.instance,
      ]),
      builder: (context, _) {
        final flavor = GymFlavorService.instance.flavor;
        final a11y = AccessibilityService.instance;
        final app = MaterialApp.router(
          title: flavor?.gymName ?? 'TitanFit',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeService.instance.mode,
          theme: AppTheme.buildLight(flavor),
          darkTheme: AppTheme.build(flavor),
          routerConfig: _appRouter,
          builder: (context, child) {
            var result = child ?? const SizedBox.shrink();
            final media = MediaQuery.of(context);
            result = MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(a11y.textScale),
                boldText: a11y.boldText,
                disableAnimations: a11y.reduceMotion,
              ),
              child: result,
            );
            final filter = a11y.colorFilter;
            if (filter != null) {
              result = ColorFiltered(colorFilter: filter, child: result);
            }
            return result;
          },
        );
        return app;
      },
    );
  }
}
