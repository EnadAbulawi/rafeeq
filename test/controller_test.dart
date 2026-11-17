import 'package:flutter_test/flutter_test.dart';
import 'package:rafeeq/app/controllers/app_controller.dart';
import 'package:rafeeq/features/adhkar/models/dhikr.dart';
import 'package:rafeeq/features/quran/repositories/quran_repository.dart';

import 'support/memory_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemoryStore store;
  late AppController app;
  late DateTime date;
  late List<Dhikr> entries;
  setUpAll(() async {
    await QuranRepository.load();
    entries = await AdhkarRepository.load();
  });
  setUp(() {
    store = MemoryStore();
    date = DateTime(2026, 10, 31, 23, 59);
    app = AppController(store, entries, clock: () => date);
  });
  tearDown(() async {
    await app.flush();
    app.dispose();
  });
  test('counter increments and keeps salawat separate', () async {
    app.increment(false);
    app.increment(false);
    app.increment(true);
    expect(app.counter(false).session, 2);
    expect(app.daily(false), 2);
    expect(app.lifetime(false), 2);
    expect(app.daily(true), 1);
  });
  test('reset preserves daily and lifetime totals', () {
    app.increment(false);
    app.resetSession(false);
    expect(app.counter(false).session, 0);
    expect(app.daily(false), 1);
    expect(app.lifetime(false), 1);
  });
  test('local midnight and backward clock preserve historical days', () {
    app.increment(true);
    date = DateTime(2026, 11, 1);
    expect(app.daily(true), 0);
    app.increment(true);
    expect(app.lifetime(true), 2);
    date = DateTime(2026, 10, 31);
    expect(app.daily(true), 1);
    expect(app.counter(true).session, 2);
  });
  test('selected phrases retain separate sessions and aggregate totals', () {
    app.increment(false);
    app.selectPhrase(1);
    expect(app.counter(false).session, 0);
    app.increment(false);
    expect(app.daily(false), 2);
    app.selectPhrase(0);
    expect(app.counter(false).session, 1);
  });
  test('goals clamp and may be disabled', () {
    app.setGoal(2);
    app.increment(true);
    expect(app.goalProgress, .5);
    app.increment(true);
    app.increment(true);
    expect(app.goalProgress, 1);
    app.setGoal(0);
    expect(app.goalProgress, 0);
  });
  test('dhikr cannot exceed repetitions and resets by date', () {
    final dhikr = entries.first;
    for (var i = 0; i < dhikr.count + 3; i++) {
      app.repeatDhikr(dhikr);
    }
    expect(app.completed(dhikr), dhikr.count);
    date = DateTime(2026, 11, 1);
    expect(app.completed(dhikr), 0);
  });
  test('category reset preserves other categories', () {
    final a = entries.first,
        b = entries.firstWhere((e) => e.category != a.category);
    app.repeatDhikr(a);
    app.repeatDhikr(b);
    app.resetCategory(a.category);
    expect(app.completed(a), 0);
    expect(app.completed(b), 1);
  });
  test(
    'restart restores counters preferences bookmarks and progress',
    () async {
      app.increment(false);
      app.increment(true);
      app.selectPhrase(3);
      app.increment(false);
      app.toggleTheme();
      app.setHaptic(false);
      app.setGoal(500);
      app.markReading(const ReadingPosition(2, 255));
      app.toggleBookmark(const ReadingPosition(114, 6));
      app.repeatDhikr(entries.first);
      await app.flush();
      final restored = AppController(store, entries, clock: () => date);
      await restored.load();
      expect(restored.lifetime(false), 2);
      expect(restored.daily(true), 1);
      expect(restored.dark, true);
      expect(restored.haptic, false);
      expect(restored.selectedPhrase, 3);
      expect(restored.salawatGoal, 500);
      expect(restored.lastReading!.id, '2:255');
      expect(restored.bookmarks.single.id, '114:6');
      expect(restored.completed(entries.first), 1);
      restored.dispose();
    },
  );
  test('rapid writes keep latest snapshot in order', () async {
    for (var i = 0; i < 100; i++) {
      app.increment(false);
    }
    await app.flush();
    final restored = AppController(store, entries);
    await restored.load();
    expect(restored.lifetime(false), 100);
    restored.dispose();
  });
  test(
    'write failures surface and can be retried without losing memory state',
    () async {
      store.fail = true;
      app.increment(true);
      await app.flush();
      expect(app.saveError, isNotNull);
      expect(app.daily(true), 1);
      store.fail = false;
      await app.flush();
      expect(app.saveError, isNull);
      final restored = AppController(store, entries, clock: () => date);
      await restored.load();
      expect(restored.daily(true), 1);
      restored.dispose();
    },
  );
  test('corrupted schema does not overwrite saved state', () async {
    store.data = {'version': 9};
    expect(app.load, throwsFormatException);
    expect(store.data, {'version': 9});
    store.data = null;
  });
  test('bookmark toggle removes only requested verse', () {
    app.toggleBookmark(const ReadingPosition(1, 1));
    app.toggleBookmark(const ReadingPosition(2, 1));
    app.toggleBookmark(const ReadingPosition(1, 1));
    expect(app.bookmarks.single.id, '2:1');
  });
  test('reader mode defaults to pages and survives restart without changing progress', () async {
    expect(app.quranVertical, false);
    app.markReading(const ReadingPosition(2, 255));
    app.increment(false);
    app.setQuranVertical(true);
    await app.flush();
    final restored = AppController(store, entries);
    await restored.load();
    expect(restored.quranVertical, true);
    expect(restored.lastReading!.id, '2:255');
    expect(restored.lifetime(false), 1);
    restored.dispose();
  });
  test(
    'existing version-one data without reader setting defaults to pages',
    () async {
      app.increment(true);
      await app.flush();
      store.data!.remove('quranVertical');
      final restored = AppController(store, entries);
      await restored.load();
      expect(restored.quranVertical, false);
      expect(restored.lifetime(true), 1);
      restored.dispose();
    },
  );
}
