import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/notification_planner.dart';

/// Thin wrapper over flutter_local_notifications so the rest of the app
/// (and tests, via a fake) only ever sees `applyPlan`.
class NotificationScheduler {
  NotificationScheduler([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'pushon_reminders', 'Reminders',
      channelDescription: 'Daily push-up nudges and the evening reminder',
      importance: Importance.defaultImportance,
    ),
  );

  Future<void> init({required void Function() onTap}) async {
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (_) => onTap(),
    );
  }

  /// Android 13+ runtime permission. Called from onboarding (after the
  /// explainer copy), NOT at init — the spec wants the ask on first run
  /// with context, not a cold system dialog at boot.
  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> applyPlan(List<PlannedNotification> plan) async {
    await _plugin.cancelAll();
    for (final n in plan) {
      await _plugin.zonedSchedule(
        id: n.kind.index,
        title: n.title,
        body: n.body,
        scheduledDate: tz.TZDateTime.from(n.fireAt, tz.local),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
