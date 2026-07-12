import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/dates.dart';
import '../../state/providers.dart';
import '../theme.dart';
import 'wheel_log_sheet.dart';

/// Whether [date] is rest/sick — a single-day stream so the sheet re-renders
/// when the toggle flips.
final _dayRestProvider = StreamProvider.family<bool, LocalDate>((ref, d) =>
    ref.watch(repositoryProvider).watchRestDays(d, d).map((s) => s.contains(d.iso)));

/// Opens the per-day editor for [date]: rest toggle, the day's sets (each
/// deletable), and Add set. Shared by the calendar grid and the Today week
/// strip so both edit history through one code path. Touches the week plan
/// first (spec: plans are written on first touch).
Future<void> openDaySheet(BuildContext context, WidgetRef ref, LocalDate date) async {
  await ref.read(repositoryProvider).ensureWeekPlan(date.weekStart);
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    builder: (_) => DaySheet(date: date),
  );
}

class DaySheet extends ConsumerWidget {
  const DaySheet({super.key, required this.date});
  final LocalDate date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = ref.watch(daySetsProvider(date)).value ?? const [];
    final rest = ref.watch(_dayRestProvider(date)).value ?? false;
    final repo = ref.read(repositoryProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(date.iso, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kInk)),
          SwitchListTile(
            title: const Text('Rest / sick day'),
            value: rest,
            onChanged: (v) => repo.setRest(date, v),
          ),
          for (final s in sets)
            ListTile(
              key: ValueKey(s.id),
              dense: true,
              title: Text('${s.count} reps'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => repo.deleteSet(id: s.id, now: ref.read(clockProvider)()),
              ),
            ),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add set'),
            onPressed: () async {
              final count = await showWheelPicker(context, title: 'How many?',
                  initial: ref.read(defaultRepsProvider));
              if (count == null) return;
              await repo.logSet(date: date, count: count, now: ref.read(clockProvider)());
            },
          ),
        ]),
      ),
    );
  }
}
