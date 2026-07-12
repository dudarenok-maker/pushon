import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/dates.dart';
import '../state/providers.dart';
import 'settings_screen.dart' show kDayNames;
import 'theme.dart';
import 'widgets/max_width.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static final _targets = [for (var v = 5; v <= 2000; v += 5) v];
  int _targetIndex = _targets.indexOf(500);
  int _easy = 1;
  int _peak = 5;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kSunshine,
        body: SafeArea(
          child: MaxWidthBody(
            child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(children: [
                const SizedBox(height: 16),
                const Text('PushOn',
                    style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: kInk)),
                const Text('The push-up habit that sticks.',
                    style: TextStyle(fontSize: 16, color: kInk)),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text("We'll nudge you when a set is due — allow notifications when asked.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: kInk)),
                ),
                const SizedBox(height: 24),
                const Text('Weekly target', style: TextStyle(fontWeight: FontWeight.w700, color: kInk)),
                SizedBox(
                  height: 120,
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(initialItem: _targetIndex),
                    itemExtent: 36,
                    onSelectedItemChanged: (i) => setState(() => _targetIndex = i),
                    children: [for (final v in _targets) Center(child: Text('$v'))],
                  ),
                ),
                Row(children: [
                  Expanded(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _easy,
                      items: [for (var d = 0; d < 7; d++)
                        DropdownMenuItem(value: d, child: Text('Easy: ${kDayNames[d]}'))],
                      onChanged: (d) {
                        if (d == null || d == _peak) return;
                        setState(() => _easy = d);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _peak,
                      items: [for (var d = 0; d < 7; d++)
                        DropdownMenuItem(value: d, child: Text('Peak: ${kDayNames[d]}'))],
                      onChanged: (d) {
                        if (d == null || d == _easy) return;
                        setState(() => _peak = d);
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final repo = ref.read(repositoryProvider);
                      final today = LocalDate.from(ref.read(clockProvider)());
                      await repo.patchSettings({
                        'weeklyTarget': '${_targets[_targetIndex]}',
                        'easyDay': '$_easy',
                        'peakDay': '$_peak',
                        'installDate': today.iso,
                      });
                      await repo.ensureWeekPlan(today.weekStart);
                      // Contextual permission ask (spec: first run, with explainer).
                      await ref.read(schedulerProvider)?.requestPermission();
                    },
                    child: const Text('Start'),
                  ),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
          ),
        ),
      );
}
