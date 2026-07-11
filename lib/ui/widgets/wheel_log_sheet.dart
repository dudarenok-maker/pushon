import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// Shared scrolling-wheel picker. Returns the chosen value or null.
Future<int?> showWheelPicker(
  BuildContext context, {
  required String title,
  int initial = 20,
  int min = 1,
  int max = 200,
  int step = 1,
}) {
  final values = [for (var v = min; v <= max; v += step) v];
  var selected = values.indexOf(initial.clamp(min, max));
  if (selected < 0) selected = 0;
  return showModalBottomSheet<int>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kInk)),
          ),
          SizedBox(
            height: 140,
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(initialItem: selected),
              itemExtent: 40,
              onSelectedItemChanged: (i) => selected = i,
              children: [for (final v in values) Center(child: Text('$v'))],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(sheetContext, values[selected]),
                child: const Text('Add'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
