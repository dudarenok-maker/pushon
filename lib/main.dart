import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/db.dart';
import 'data/notification_scheduler.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase(driftDatabase(name: 'pushon'));
  final scheduler = NotificationScheduler();
  await scheduler.init(onTap: () {}); // a tap simply opens the app — Today is home
  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      schedulerProvider.overrideWithValue(scheduler),
    ],
    child: const PushOnApp(),
  ));
}
