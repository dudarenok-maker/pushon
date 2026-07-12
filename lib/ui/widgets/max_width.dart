import 'package:flutter/widgets.dart';

import '../theme.dart';

/// Centres a screen body and caps its width at [kContentMaxWidth] on large
/// screens (tablets, foldables, desktop) so content — and full-width buttons —
/// don't stretch edge-to-edge. Phones are narrower than the cap, so they render
/// unchanged. Wraps only the body; app bars and the bottom nav stay full-width.
class MaxWidthBody extends StatelessWidget {
  const MaxWidthBody({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final overflow = constraints.maxWidth - kContentMaxWidth;
          // Phones (≤ the cap) render the child untouched — no wrapper at all.
          if (overflow <= 0) return child;
          // Wider screens: inset equally to centre the content at the cap.
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: overflow / 2),
            child: child,
          );
        },
      );
}
