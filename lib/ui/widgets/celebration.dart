import 'package:flutter/material.dart';

import '../../domain/achievements.dart';
import '../theme.dart';

({String emoji, String title}) _content(Celebration c) => switch (c) {
      Celebration.weekComplete => (emoji: '🎉', title: 'Weekly target smashed!'),
      Celebration.dayComplete => (emoji: '✅', title: 'Day complete!'),
      Celebration.personalBest => (emoji: '🏆', title: 'New personal best!'),
      Celebration.none => (emoji: '', title: ''),
    };

/// Shows a brief, self-dismissing celebratory card over the current screen.
/// A no-op for [Celebration.none]. Uses an Overlay entry so it never blocks
/// input or navigation.
void showCelebration(BuildContext context, Celebration c) {
  if (c == Celebration.none) return;
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  final content = _content(c);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _CelebrationCard(
      emoji: content.emoji,
      title: content.title,
      onDone: entry.remove,
    ),
  );
  overlay.insert(entry);
}

class _CelebrationCard extends StatefulWidget {
  const _CelebrationCard({required this.emoji, required this.title, required this.onDone});
  final String emoji;
  final String title;
  final VoidCallback onDone;

  @override
  State<_CelebrationCard> createState() => _CelebrationCardState();
}

class _CelebrationCardState extends State<_CelebrationCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
  var _done = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await _c.forward();
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    await _c.reverse();
    if (!_done) {
      _done = true;
      widget.onDone();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: IgnorePointer(
          child: Center(
            child: FadeTransition(
              opacity: _c,
              child: ScaleTransition(
                scale: CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                  decoration: BoxDecoration(
                    color: kCream,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: kInk.withValues(alpha: 0.2), blurRadius: 24)],
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(widget.emoji, style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(widget.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kInk)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}
