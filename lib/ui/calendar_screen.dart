import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository.dart';
import '../domain/dates.dart';
import '../domain/day_status.dart';
import '../domain/distribution.dart';
import '../state/providers.dart';
import 'theme.dart';
import 'widgets/day_sheet.dart';
import 'widgets/max_width.dart';
import 'widgets/week_strip.dart' show dayStatusColor;

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late LocalDate _month; // first of the displayed month

  @override
  void initState() {
    super.initState();
    final t = ref.read(todayProvider);
    _month = LocalDate(t.year, t.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final settings = ref.watch(settingsProvider).value;
    final install = settings?.installDate;
    final gridStart = _month.weekStart;
    final gridEnd = gridStart.addDays(41); // 6 rows
    final totals = ref.watch(rangeTotalsProvider((gridStart, gridEnd))).value ?? const {};
    final rest = ref.watch(rangeRestProvider((gridStart, gridEnd))).value ?? const {};
    final plans = ref.watch(rangePlansProvider((gridStart, gridEnd))).value ?? const {};

    int targetFor(LocalDate d) {
      final stored = plans[d.weekStart.iso];
      if (stored != null) return stored.targets[d.weekdayIndex];
      if (settings == null) return 0;
      // Preview only — never stored (spec: plans are written on touch). Same
      // weekSeed as ensureWeekPlan, so the preview matches the eventual plan.
      return distributeWeek(
          weeklyTarget: settings.weeklyTarget,
          easyDay: settings.easyDay,
          peakDay: settings.peakDay,
          weekSeed: d.weekStart.epochDay ~/ 7)[d.weekdayIndex];
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: MaxWidthBody(
        child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => _month = LocalDate(_month.year, _month.month - 1, 1))),
          Text('${_month.year}-${_month.month.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kInk)),
          IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() => _month = LocalDate(_month.year, _month.month + 1, 1))),
        ]),
        Expanded(
          child: GridView.count(
            crossAxisCount: 7,
            children: [
              for (var i = 0; i < 42; i++)
                _cell(gridStart.addDays(i), today, install, totals, rest, targetFor),
            ],
          ),
        ),
      ]),
      ),
    );
  }

  Widget _cell(LocalDate d, LocalDate today, LocalDate? install, Map<String, int> totals,
      Set<String> rest, int Function(LocalDate) targetFor) {
    final inMonth = d.month == _month.month;
    final logged = totals[d.iso] ?? 0;
    final target = targetFor(d);
    final status = install == null
        ? DayStatus.future
        : dayStatus(date: d, today: today, installDate: install,
            logged: logged, target: target, rest: rest.contains(d.iso));
    final openable = install != null &&
        isDayEditable(date: d, today: today, installDate: install);
    // Weeks before the install week aren't part of your plan — show no target.
    final priorWeek = install != null && d.isBefore(install.weekStart);
    return Opacity(
      opacity: inMonth ? 1 : 0.35,
      child: InkWell(
        onTap: openable ? () => openDaySheet(context, ref, d) : null,
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: dayStatusColor(status),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kInk.withValues(alpha: 0.15)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${d.day}', style: const TextStyle(fontWeight: FontWeight.w700, color: kInk)),
            Text(priorWeek ? '' : (status == DayStatus.future ? '$target' : '$logged/$target'),
                style: TextStyle(fontSize: 10, color: kInk.withValues(alpha: 0.6))),
          ]),
        ),
      ),
    );
  }
}

// Range-keyed providers used only by the calendar.
final rangeTotalsProvider = StreamProvider.family<Map<String, int>, (LocalDate, LocalDate)>(
    (ref, r) => ref.watch(repositoryProvider).watchDayTotals(r.$1, r.$2));
final rangeRestProvider = StreamProvider.family<Set<String>, (LocalDate, LocalDate)>(
    (ref, r) => ref.watch(repositoryProvider).watchRestDays(r.$1, r.$2));
final rangePlansProvider =
    StreamProvider.family<Map<String, WeekPlanData>, (LocalDate, LocalDate)>(
        (ref, r) => ref.watch(repositoryProvider).watchWeekPlans(r.$1, r.$2));
