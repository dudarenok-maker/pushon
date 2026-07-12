import 'dart:math' show pi;

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
    if (plan == null || install == null) return const SizedBox(height: 66);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var d = 0; d < 7; d++)
          Builder(builder: (context) {
            final date = today.weekStart.addDays(d);
            final logged = totals[date.iso] ?? 0;
            final status = dayStatus(
              date: date,
              today: today,
              installDate: install,
              logged: logged,
              target: plan.targets[d],
              rest: rest.contains(date.iso),
            );
            // Editable from the install week onward (so you can back-fill the
            // week you joined), never the future — shared with the calendar.
            final openable = isDayEditable(date: date, today: today, installDate: install);
            return _DayChip(
              letter: kDayLetters[d],
              logged: logged,
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
  const _DayChip({
    required this.letter,
    required this.logged,
    required this.target,
    required this.status,
    this.onTap,
  });
  final String letter;
  final int logged;
  final int target;
  final DayStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isFuture = status == DayStatus.future || status == DayStatus.preInstall;
    final isRest = status == DayStatus.rest;
    final progress = (!isFuture && !isRest && target > 0) ? (logged / target).clamp(0.0, 1.0) : 0.0;

    // Track: sunshine highlights today (pending); otherwise a faint ink ring.
    final track = status == DayStatus.pending
        ? kSunshine
        : kInk.withValues(alpha: isRest ? 0.10 : 0.16);
    final letterColor = isFuture ? kInk.withValues(alpha: 0.4) : kInk;

    // Sub-label: future shows just the goal; rest shows a dash; active days
    // show how far you got — logged / target.
    final String sub = isFuture
        ? '$target'
        : isRest
            ? '·'
            : '$logged/$target';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 38,
            height: 38,
            child: CustomPaint(
              painter: _RingPainter(progress: progress, track: track, fill: kCoral),
              child: Center(
                child: Text(letter,
                    style: TextStyle(fontWeight: FontWeight.w700, color: letterColor)),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(sub,
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: kInk.withValues(alpha: isFuture ? 0.4 : 0.65))),
        ]),
      ),
    );
  }
}

/// A thin ring: a full [track] circle with a [fill] arc sweeping from the top
/// to show [progress] (0–1). Hand-painted (not a ProgressIndicator) so there's
/// no animation controller ticking behind the strip.
class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.track, required this.fill});
  final double progress;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 3.5;
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    canvas.drawArc(
      rect, 0, 2 * pi, false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (progress > 0) {
      canvas.drawArc(
        rect, -pi / 2, 2 * pi * progress, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = fill,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.fill != fill;
}
