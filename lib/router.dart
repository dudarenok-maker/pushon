import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'ui/calendar_screen.dart';
import 'ui/settings_screen.dart';
import 'ui/summary_screen.dart';
import 'ui/today_screen.dart';

GoRouter buildRouter() => GoRouter(
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => _AppShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/', builder: (_, _) => const TodayScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/calendar', builder: (_, _) => const CalendarScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/summary', builder: (_, _) => const SummaryScreen()),
            ]),
          ],
        ),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        // Full-screen Monday takeover — a TOP-LEVEL route on purpose. Never
        // push() a shell branch: branch routes are switched via goBranch,
        // and pushing one duplicates the shell.
        GoRoute(path: '/weekly-summary', builder: (_, _) => const SummaryScreen()),
      ],
    );

class _AppShell extends StatelessWidget {
  const _AppShell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: shell.goBranch,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Today'),
            NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Calendar'),
            NavigationDestination(icon: Icon(Icons.insights), label: 'Summary'),
          ],
        ),
      );
}
