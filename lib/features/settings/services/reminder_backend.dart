import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_preferences.dart';

abstract interface class ReminderBackend {
  bool get supported;
  Future<void> initialize(ValueChanged<String> onOpen);
  Future<bool> permission({bool request = false});
  Future<int> replace(ReminderPreferences preferences);
  Future<void> test(bool sound);
  Future<void> openSettings();
}

tz.TZDateTime nextReminder(tz.TZDateTime now, int minutes) {
  var next = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    minutes ~/ 60,
    minutes % 60,
  );
  if (!next.isAfter(now)) {
    next = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + 1,
      minutes ~/ 60,
      minutes % 60,
    );
  }
  return next;
}

class LocalReminderBackend implements ReminderBackend {
  final plugin = FlutterLocalNotificationsPlugin();
  static const ids = [4100, 4101, 4102, 4103];
  @override
  bool get supported =>
      !kIsWeb &&
      [
        TargetPlatform.android,
        TargetPlatform.iOS,
      ].contains(defaultTargetPlatform);

  @override
  Future<void> initialize(ValueChanged<String> onOpen) async {
    tz_data.initializeTimeZones();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_rafeeq'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) {
        if (r.payload != null) onOpen(r.payload!);
      },
    );
    final launch = await plugin.getNotificationAppLaunchDetails();
    final payload = launch?.notificationResponse?.payload;
    if (launch?.didNotificationLaunchApp == true && payload != null) {
      onOpen(payload);
    }
  }

  @override
  Future<bool> permission({bool request = false}) async {
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      if (request) {
        return await android.requestNotificationsPermission() ?? false;
      }
      return await android.areNotificationsEnabled() ?? false;
    }
    final ios = plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (request) {
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return (await ios?.checkPermissions())?.isEnabled ?? false;
  }

  NotificationDetails details(bool sound) => NotificationDetails(
    android: AndroidNotificationDetails(
      sound ? 'daily_reminders_sound_v1' : 'daily_reminders_silent_v1',
      sound ? 'تذكيرات بصوت' : 'تذكيرات صامتة',
      channelDescription: 'تذكيرات رفيق اليومية حسب الأوقات التي تختارها',
      importance: Importance.defaultImportance,
      playSound: sound,
      enableVibration: sound,
      icon: 'ic_stat_rafeeq',
    ),
    iOS: DarwinNotificationDetails(presentSound: sound, presentAlert: true),
  );

  @override
  Future<int> replace(ReminderPreferences preferences) async {
    for (final id in ids) {
      await plugin.cancel(id: id);
    }
    if (!preferences.enabled) return 0;
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    try {
      for (var i = 0; i < preferences.times.length; i++) {
        final t = preferences.times[i];
        if (!t.enabled) continue;
        await plugin.zonedSchedule(
          id: ids[i],
          title: t.title,
          body: t.body,
          payload: t.key,
          scheduledDate: nextReminder(tz.TZDateTime.now(tz.local), t.minutes),
          notificationDetails: details(preferences.sound),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
      final pending = await plugin.pendingNotificationRequests();
      return pending.where((p) => ids.contains(p.id)).length;
    } catch (_) {
      for (final id in ids) {
        await plugin.cancel(id: id);
      }
      rethrow;
    }
  }

  @override
  Future<void> test(bool sound) => plugin.show(
    id: 4199,
    title: 'رفيق',
    body: 'وصل إشعار التجربة. يمكنك تخصيص تذكيراتك من الإعدادات.',
    notificationDetails: details(sound),
    payload: 'settings',
  );
  @override
  Future<void> openSettings() async {
    await plugin.openAppNotificationSettings();
  }
}
