import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../state/providers.dart';
import 'theme.dart';
import 'widgets/max_width.dart';
import 'widgets/wheel_log_sheet.dart';

const kDayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _fmtMinutes(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider).value;
    final repo = ref.read(repositoryProvider);
    if (s == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    Future<void> pickDay({required bool easy}) async {
      final chosen = await showDialog<int>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: Text(easy ? 'Easy day' : 'Peak day'),
          children: [
            for (var d = 0; d < 7; d++)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, d),
                child: Text(kDayNames[d]),
              ),
          ],
        ),
      );
      if (chosen == null) return;
      final conflict = easy ? chosen == s.peakDay : chosen == s.easyDay;
      if (conflict) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Easy and peak day must differ')));
        }
        return;
      }
      await repo.patchSettings({easy ? 'easyDay' : 'peakDay': '$chosen'});
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: MaxWidthBody(
        child: ListView(children: [
        ListTile(
          title: const Text('Weekly target'),
          subtitle: const Text('Changes apply from next Monday'),
          trailing: Text('${s.weeklyTarget}', style: const TextStyle(fontSize: 16, color: kInk)),
          onTap: () async {
            final v = await showWheelPicker(context,
                title: 'Weekly target', initial: s.weeklyTarget, min: 5, max: 2000, step: 5);
            if (v != null) await repo.patchSettings({'weeklyTarget': '$v'});
          },
        ),
        ListTile(
            title: const Text('Easy day'),
            trailing: Text(kDayNames[s.easyDay]),
            onTap: () => pickDay(easy: true)),
        ListTile(
            title: const Text('Peak day'),
            trailing: Text(kDayNames[s.peakDay]),
            onTap: () => pickDay(easy: false)),
        const Divider(),
        SwitchListTile(
          title: const Text('Inactivity nudge'),
          subtitle: const Text('A prod 4 hours after your last set'),
          value: s.nudgeEnabled,
          onChanged: (v) => repo.patchSettings({'nudgeEnabled': '$v'}),
        ),
        SwitchListTile(
          title: const Text('Evening reminder'),
          subtitle: const Text('Remaining reps at 8pm'),
          value: s.reminderEnabled,
          onChanged: (v) => repo.patchSettings({'reminderEnabled': '$v'}),
        ),
        ListTile(
          title: const Text('Waking window starts'),
          trailing: Text(_fmtMinutes(s.wakingStartMinutes)),
          onTap: () async {
            final t = await showTimePicker(context: context,
                initialTime: TimeOfDay(hour: s.wakingStartMinutes ~/ 60, minute: s.wakingStartMinutes % 60));
            if (t != null) await repo.patchSettings({'wakingStartMinutes': '${t.hour * 60 + t.minute}'});
          },
        ),
        ListTile(
          title: const Text('Waking window ends'),
          trailing: Text(_fmtMinutes(s.wakingEndMinutes)),
          onTap: () async {
            final t = await showTimePicker(context: context,
                initialTime: TimeOfDay(hour: s.wakingEndMinutes ~/ 60, minute: s.wakingEndMinutes % 60));
            if (t != null) await repo.patchSettings({'wakingEndMinutes': '${t.hour * 60 + t.minute}'});
          },
        ),
        ListTile(
          title: const Text('Reminders not showing up?'),
          subtitle: const Text("Ask Android not to put PushOn to sleep"),
          onTap: () => requestBatteryExemption(context),
        ),
        const Divider(),
        ListTile(
          title: const Text('About PushOn'),
          subtitle: const Text('The push-up habit that sticks. All data stays on your device.'),
          onTap: () => showLicensePage(context: context, applicationName: 'PushOn'),
        ),
      ]),
      ),
    );
  }
}

Future<void> requestBatteryExemption(BuildContext context) async {
  final proceed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: const Text(
          'Reminders work best if Android does not put PushOn to sleep. Allow it?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Not now')),
        TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Allow')),
      ],
    ),
  );
  if (proceed == true) {
    await Permission.ignoreBatteryOptimizations.request();
  }
}
