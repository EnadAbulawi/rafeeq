import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rafeeq/features/settings/models/reminder_preferences.dart';
import 'package:rafeeq/features/settings/services/reminder_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  const timezone = MethodChannel('flutter_timezone');
  final calls = <MethodCall>[];
  final pending = <int, Map<String, dynamic>>{};
  var failSchedule = false;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls.clear();
    pending.clear();
    failSchedule = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'initialize':
              return true;
            case 'getNotificationAppLaunchDetails':
              return {'notificationLaunchedApp': false};
            case 'areNotificationsEnabled':
            case 'requestNotificationsPermission':
              return true;
            case 'cancel':
              final arg = call.arguments;
              pending.remove(arg is Map ? arg['id'] : arg);
              return null;
            case 'zonedSchedule':
              if (failSchedule) {
                throw PlatformException(code: 'schedule_failed');
              }
              final arg = Map<String, dynamic>.from(call.arguments as Map);
              pending[arg['id'] as int] = arg;
              return null;
            case 'pendingNotificationRequests':
              return [
                for (final e in pending.values)
                  {
                    'id': e['id'],
                    'title': e['title'],
                    'body': e['body'],
                    'payload': e['payload'],
                  },
              ];
          }
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timezone, (_) async => 'Asia/Hebron');
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timezone, null);
  });
  test(
    'plugin schedules local daily reminders with payloads and inexact alarms',
    () async {
      final backend = LocalReminderBackend();
      await backend.initialize((_) {});
      expect(calls.where((c) => c.method.contains('Permission')), isEmpty);
      final count = await backend.replace(
        const ReminderPreferences(enabled: true),
      );
      expect(count, 4);
      expect(pending.values.map((e) => e['payload']), [
        'morning',
        'evening',
        'reading',
        'salawat',
      ]);
      for (final e in pending.values) {
        expect(e['timeZoneName'], 'Asia/Hebron');
        final android = e['platformSpecifics'] as Map;
        expect(android['scheduleMode'], 'inexactAllowWhileIdle');
      }
      await backend.replace(const ReminderPreferences(enabled: false));
      expect(pending, isEmpty);
    },
  );
  test('silent option uses its own channel and no sound', () async {
    final backend = LocalReminderBackend();
    await backend.initialize((_) {});
    await backend.replace(
      const ReminderPreferences(enabled: true, sound: false),
    );
    for (final e in pending.values) {
      final android = e['platformSpecifics'] as Map;
      expect(android['channelId'], 'daily_reminders_silent_v1');
      expect(android['playSound'], false);
    }
  });
  test(
    'plugin scheduling failure cancels partially scheduled reminders',
    () async {
      final backend = LocalReminderBackend();
      await backend.initialize((_) {});
      await backend.replace(const ReminderPreferences(enabled: true));
      failSchedule = true;
      await expectLater(
        backend.replace(const ReminderPreferences(enabled: true)),
        throwsA(isA<PlatformException>()),
      );
      expect(pending, isEmpty);
    },
  );
}
