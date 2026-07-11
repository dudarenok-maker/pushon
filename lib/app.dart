import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'state/providers.dart';
import 'ui/onboarding_screen.dart';
import 'ui/theme.dart';

/// Router identity MUST be stable across rebuilds: PushOnApp rebuilds on
/// every settings write (drift stream), and a fresh GoRouter would reset
/// navigation to '/' — silently killing pushed routes like the summary
/// takeover. Never call buildRouter() inside build().
final routerProvider = Provider<GoRouter>((ref) => buildRouter());

class PushOnApp extends ConsumerWidget {
  const PushOnApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return settings.when(
      loading: () => MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(body: Center(child: CircularProgressIndicator()))),
      error: (e, _) =>
          MaterialApp(theme: buildTheme(), home: Scaffold(body: Center(child: Text('$e')))),
      data: (s) {
        if (s.installDate == null) {
          return MaterialApp(theme: buildTheme(), home: const OnboardingScreen());
        }
        return MaterialApp.router(
          title: 'PushOn',
          theme: buildTheme(),
          routerConfig: ref.watch(routerProvider),
        );
      },
    );
  }
}
