import 'package:go_router/go_router.dart';

import '../features/home/presentation/home_shell.dart';

/// Routeur de l'application. Route initiale = l'ecran principal facon Yuka.
/// (Auth/historique seront ajoutes plus tard sous forme de routes dediees.)
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeShell(),
    ),
  ],
);
