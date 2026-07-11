import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';

/// Keeps [todayProvider] fresh for the lifetime of the running app.
///
/// [todayProvider] caches `today` from the clock for the process lifetime, so
/// without this the value — and the notification plan derived from it — goes
/// stale when the app is left foregrounded past midnight or warm-resumed from
/// the background; only a cold start would recompute it. This scope invalidates
/// [todayProvider] on resume and at the next local midnight, which cascades to
/// the week plan, totals, streak and notification sync.
///
/// Lives above the app (wired in `main.dart`) rather than inside a screen so a
/// single instance covers every route, and so the long-lived midnight timer is
/// created only by the real app — never by the widget-test harness, whose
/// fake-async binding would flag it as a pending timer at teardown.
class DayRolloverScope extends ConsumerStatefulWidget {
  const DayRolloverScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DayRolloverScope> createState() => _DayRolloverScopeState();
}

class _DayRolloverScopeState extends ConsumerState<DayRolloverScope> {
  late final AppLifecycleListener _lifecycle;
  Timer? _midnight;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
    _scheduleMidnight();
  }

  void _refresh() {
    if (!mounted) return;
    ref.invalidate(todayProvider);
    _scheduleMidnight();
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = ref.read(clockProvider)();
    final next = DateTime(now.year, now.month, now.day + 1);
    // +1s cushion so the timer fires just after the boundary, never a hair
    // before it (which would recompute the same day and reschedule tightly).
    _midnight = Timer(next.difference(now) + const Duration(seconds: 1), _refresh);
  }

  @override
  void dispose() {
    _midnight?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
