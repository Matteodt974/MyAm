import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

/// Racine de l'application : MaterialApp.router (go_router) + themes clair/sombre.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Scan App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
