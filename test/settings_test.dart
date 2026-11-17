import 'package:flutter_test/flutter_test.dart';
import 'package:rafeeq/app/controllers/app_controller.dart';
import 'package:rafeeq/features/adhkar/models/dhikr.dart';
import 'package:rafeeq/features/quran/repositories/quran_repository.dart';
import 'package:rafeeq/features/settings/controllers/reminder_controller.dart';
import 'package:rafeeq/features/settings/models/reminder_preferences.dart';
import 'package:rafeeq/features/settings/services/reminder_backend.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'support/fake_reminder_backend.dart';
import 'support/memory_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeReminderBackend backend;
  late ReminderController reminders;
  var saves = 0;
  setUp(() {
    saves = 0;
    backend = FakeReminderBackend();
    reminders = ReminderController(backend: backend, onSaved: () => saves++);
  });
  tearDown(() => reminders.dispose());

  test('startup does not prompt and reminders default to disabled', () async {
    await reminders.refresh();
    expect(backend.prompts, 0);
    expect(backend.applied.single.enabled, false);
    expect(reminders.scheduledCount, 0);
    expect(saves, 0);
  });
  test('denied permission does not enable or persist reminders', () async {
    backend.allowed = false;
    await reminders.update(reminders.preferences.copyWith(enabled: true));
    expect(backend.prompts, 1);
    expect(reminders.preferences.enabled, false);
    expect(backend.applied, isEmpty);
    expect(reminders.error, isNotNull);
    expect(saves, 0);
  });
  test(
    'enable, edit time, disable category and master update schedule',
    () async {
      await reminders.update(reminders.preferences.copyWith(enabled: true));
      expect(reminders.scheduledCount, 4);
      final times = [...reminders.preferences.times];
      times[0] = times[0].copyWith(minutes: 480);
      times[1] = times[1].copyWith(enabled: false);
      await reminders.update(
        reminders.preferences.copyWith(times: times, sound: false),
      );
      expect(reminders.scheduledCount, 3);
      expect(backend.applied.last.times.first.minutes, 480);
      expect(backend.applied.last.sound, false);
      expect(backend.prompts, 1);
      await reminders.update(reminders.preferences.copyWith(enabled: false));
      expect(reminders.scheduledCount, 0);
      expect(backend.applied.last.enabled, false);
      expect(saves, 3);
    },
  );
  test(
    'revoked permission cancels schedules without requesting again',
    () async {
      await reminders.update(reminders.preferences.copyWith(enabled: true));
      backend.allowed = false;
      await reminders.refresh();
      expect(reminders.allowed, false);
      expect(reminders.scheduledCount, 0);
      expect(backend.applied.last.enabled, false);
      expect(backend.prompts, 1);
    },
  );
  test('schedule failure is visible and can be retried', () async {
    backend.fail = true;
    await reminders.update(reminders.preferences.copyWith(enabled: true));
    expect(reminders.error, isNotNull);
    expect(saves, 0);
    backend.fail = false;
    await reminders.update(reminders.preferences.copyWith(enabled: true));
    expect(reminders.error, isNull);
    expect(reminders.scheduledCount, 4);
  });
  test(
    'test notification requires permission and taps retain destination',
    () async {
      backend.allowed = false;
      await reminders.test();
      expect(backend.tests, 0);
      backend.allowed = true;
      await reminders.test();
      expect(backend.tests, 1);
      backend.onOpen!('morning');
      expect(reminders.destination.value, 'morning');
    },
  );
  test('unsupported platforms remain usable without plugin calls', () async {
    backend.supported = false;
    await reminders.update(reminders.preferences.copyWith(enabled: true));
    expect(backend.initialized, 0);
    expect(reminders.preferences.enabled, false);
  });
  test('daily schedule uses calendar day across daylight saving changes', () {
    tz_data.initializeTimeZones();
    final location = tz.getLocation('America/New_York');
    final now = tz.TZDateTime(location, 2026, 3, 7, 23);
    final next = nextReminder(now, 7 * 60);
    expect(next.day, 8);
    expect(next.hour, 7);
    expect(next.difference(now).inHours, 7);
    expect(nextReminder(next, 7 * 60).day, 9);
  });
  test('invalid reminder times are rejected', () {
    expect(
      () => ReminderPreferences.fromJson({
        'times': {
          'morning': {'minutes': 1440},
        },
      }),
      throwsFormatException,
    );
  });
  test(
    'fonts and reminders survive restart without losing reading data',
    () async {
      await QuranRepository.load();
      final entries = await AdhkarRepository.load();
      final store = MemoryStore();
      final app = AppController(store, entries, reminderBackend: backend);
      app.markReading(const ReadingPosition(2, 6));
      app.increment(false);
      app.setTypography(
        scale: 1.2,
        dhikrSize: 38,
        family: 'Amiri',
        dhikrFamily: 'IBMPlexArabic',
      );
      await app.reminders.update(
        app.reminders.preferences.copyWith(enabled: true),
      );
      await app.flush();
      final restored = AppController(
        store,
        entries,
        reminderBackend: FakeReminderBackend(),
      );
      await restored.load();
      expect(restored.fontScale, 1.2);
      expect(restored.fontFamily, 'Amiri');
      expect(restored.adhkarFontSize, 38);
      expect(restored.adhkarFontFamily, 'IBMPlexArabic');
      expect(restored.lastReading!.id, '2:6');
      expect(restored.daily(false), 1);
      expect(restored.reminders.preferences.enabled, true);
      // Old schema-1 snapshots have no typography or notification fields.
      for (final key in [
        'fontScale',
        'fontFamily',
        'adhkarFontSize',
        'adhkarFontFamily',
        'reminders',
      ]) {
        store.data!.remove(key);
      }
      final legacy = AppController(store, entries);
      await legacy.load();
      expect(legacy.fontScale, 1);
      expect(legacy.adhkarFontSize, 28);
      expect(legacy.reminders.preferences.enabled, false);
      expect(legacy.lastReading!.id, '2:6');
      app.dispose();
      restored.dispose();
      legacy.dispose();
    },
  );
}
