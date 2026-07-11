import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/day_status.dart';
import '../../state/providers.dart';
import '../theme.dart';
import 'day_sheet.dart';

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
          Builder(builder: (context) {
            final date = today.weekStart.addDays(d);
            final status = dayStatus(
              date: date,
              today: today,
              installDate: install,
              logged: totals[date.iso] ?? 0,
              target: plan.targets[d],
              rest: rest.contains(date.iso),
            );
            // Editable from the install week onward (so you can back-fill the
            // week you joined), never the future — shared with the calendar.
            final openable = isDayEditable(date: date, today: today, installDate: install);
            return _DayChip(
              letter: kDayLetters[d],
              target: plan.targets[d],
              status: status,
              onTap: openable ? () => openDaySheet(context, ref, date) : null,
            );
          }),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.letter, required this.target, required this.status, this.onTap});
  final String letter;
  final int target;
  final DayStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(children: [
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
          ]),
        ),
      );
}
