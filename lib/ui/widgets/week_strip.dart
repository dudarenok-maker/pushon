import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/day_status.dart';
import '../../state/providers.dart';
import '../theme.dart';

const kDayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

Color dayStatusColor(DayStatus s) => switch (s) {
      DayStatus.hit => kCoral,
      DayStatus.partial => kCoral.withValues(alpha: 0.45),
      DayStatus.missed => kInk.withValues(alpha: 0.25),
      DayStatus.rest => kInk.withValues(alpha: 0.12),
      DayStatus.pending => kSunshine,
      DayStatus.future || DayStatus.preInstall => Colors.transparent,
    };

class WeekStrip extends ConsumerWidget {
  const WeekStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final plan = ref.watch(weekPlanProvider).value;
    final totals = ref.watch(weekTotalsProvider).value ?? const {};
    final rest = ref.watch(weekRestDaysProvider).value ?? const {};
    final install = ref.watch(settingsProvider).value?.installDate;
    if (plan == null || install == null) return const SizedBox(height: 56);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var d = 0; d < 7; d++)
          _DayChip(
            letter: kDayLetters[d],
            target: plan.targets[d],
            status: dayStatus(
              date: today.weekStart.addDays(d),
              today: today,
              installDate: install,
              logged: totals[today.weekStart.addDays(d).iso] ?? 0,
              target: plan.targets[d],
              rest: rest.contains(today.weekStart.addDays(d).iso),
            ),
          ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.letter, required this.target, required this.status});
  final String letter;
  final int target;
  final DayStatus status;

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: dayStatusColor(status),
            shape: BoxShape.circle,
            border: Border.all(color: kInk.withValues(alpha: 0.25)),
          ),
          child: Text(letter, style: const TextStyle(fontWeight: FontWeight.w700, color: kInk)),
        ),
        const SizedBox(height: 2),
        Text('$target', style: TextStyle(fontSize: 11, color: kInk.withValues(alpha: 0.6))),
      ]);
}
