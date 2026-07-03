import 'package:go_router/go_router.dart';

import '../features/history/presentation/history_screen.dart';
import '../features/home/presentation/home_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeShell()),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
  ],
);
