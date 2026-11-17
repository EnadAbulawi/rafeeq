import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/storage/local_store.dart';
import '../../features/counters/models/counter_record.dart';
import '../../features/adhkar/models/dhikr.dart';
import '../../features/quran/repositories/quran_repository.dart';
import '../../features/settings/controllers/reminder_controller.dart';
import '../../features/settings/models/reminder_preferences.dart';
import '../../features/settings/services/reminder_backend.dart';

const tasbihPhrases = [
  'سبحان الله',
  'الحمد لله',
  'الله أكبر',
  'لا إله إلا الله',
  'أستغفر الله',
];

class AppController extends ChangeNotifier {
  AppController(
    this.store,
    this.adhkar, {
    DateTime Function()? clock,
    ReminderBackend? reminderBackend,
  }) : clock = clock ?? DateTime.now {
    reminders = ReminderController(onSaved: _changed, backend: reminderBackend);
  }
  late final ReminderController reminders;
  final LocalStore store;
  final List<Dhikr> adhkar;
  final DateTime Function() clock;
  final quran = QuranRepository();
  Map<String, CounterRecord> _counters = {};
  Map<String, int> _progress = {};
  Set<String> _bookmarks = {};
  ReadingPosition? lastReading;
  bool dark = false;
  bool haptic = true;
  bool quranVertical = false;
  double fontScale = 1, adhkarFontSize = 28;
  String fontFamily = 'IBMPlexArabic', adhkarFontFamily = 'Amiri';
  int selectedPhrase = 0;
  int salawatGoal = 100;
  String? saveError;
  Future<void> _pending = Future.value();
  bool _closed = false;

  Future<void> load() async {
    final data = await store.read();
    if (data == null) return;
    if (data['version'] != 1) {
      throw const FormatException('Unsupported storage schema');
    }
    final counters = (data['counters'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, CounterRecord.fromJson(v as Map<String, dynamic>)),
    );
    final progress = (data['progress'] as Map<String, dynamic>)
        .cast<String, int>();
    final bookmarks = (data['bookmarks'] as List).cast<String>().toSet();
    for (final value in bookmarks) {
      ReadingPosition.parse(value);
    }
    final selected = data['selectedPhrase'] as int;
    final goal = data['salawatGoal'] as int;
    if (selected < 0 ||
        selected >= tasbihPhrases.length ||
        goal < 0 ||
        goal > 100000 ||
        progress.values.any((v) => v < 0)) {
      throw const FormatException('Invalid saved preferences');
    }
    final reading = data['lastReading'] == null
        ? null
        : ReadingPosition.parse(data['lastReading'] as String);
    final savedDark = data['dark'] as bool;
    final savedHaptic = data['haptic'] as bool;
    final savedQuranVertical = data['quranVertical'] as bool? ?? false;
    final scale = (data['fontScale'] as num? ?? 1).toDouble();
    final size = (data['adhkarFontSize'] as num? ?? 28).toDouble();
    final family = data['fontFamily'] as String? ?? 'IBMPlexArabic';
    final adhkarFamily = data['adhkarFontFamily'] as String? ?? 'Amiri';
    if (!scale.isFinite ||
        scale < .85 ||
        scale > 1.35 ||
        !size.isFinite ||
        size < 22 ||
        size > 44 ||
        !['IBMPlexArabic', 'Amiri'].contains(family) ||
        !['IBMPlexArabic', 'Amiri'].contains(adhkarFamily)) {
      throw const FormatException('Invalid typography preferences');
    }
    final reminderPreferences = ReminderPreferences.fromJson(
      data['reminders'] as Map<String, dynamic>?,
    );
    _counters = counters;
    _progress = progress;
    _bookmarks = bookmarks;
    selectedPhrase = selected;
    salawatGoal = goal;
    lastReading = reading;
    dark = savedDark;
    haptic = savedHaptic;
    quranVertical = savedQuranVertical;
    fontScale = scale;
    adhkarFontSize = size;
    fontFamily = family;
    adhkarFontFamily = adhkarFamily;
    reminders.preferences = reminderPreferences;
  }

  CounterRecord counter(bool salawat) =>
      _counters[salawat ? 'salawat' : 'tasbih:$selectedPhrase'] ??
      CounterRecord();
  int daily(bool salawat) => salawat
      ? counter(true).daily(clock())
      : _counters.entries
            .where((e) => e.key.startsWith('tasbih:'))
            .fold(0, (n, e) => n + e.value.daily(clock()));
  int lifetime(bool salawat) => salawat
      ? counter(true).lifetime
      : _counters.entries
            .where((e) => e.key.startsWith('tasbih:'))
            .fold(0, (n, e) => n + e.value.lifetime);
  double get goalProgress =>
      salawatGoal == 0 ? 0 : (daily(true) / salawatGoal).clamp(0, 1).toDouble();

  void increment(bool salawat) {
    final key = salawat ? 'salawat' : 'tasbih:$selectedPhrase';
    _counters[key] = counter(salawat).increment(clock());
    _changed();
  }

  void resetSession(bool salawat) {
    _counters[salawat ? 'salawat' : 'tasbih:$selectedPhrase'] = counter(salawat)
        .resetSession();
    _changed();
  }

  void selectPhrase(int index) {
    if (index < 0 || index >= tasbihPhrases.length) return;
    selectedPhrase = index;
    _changed();
  }

  void toggleTheme() {
    dark = !dark;
    _changed();
  }

  void setHaptic(bool value) {
    haptic = value;
    _changed();
  }

  void setQuranVertical(bool value) {
    if (quranVertical == value) return;
    quranVertical = value;
    _changed();
  }

  void setTypography({
    double? scale,
    double? dhikrSize,
    String? family,
    String? dhikrFamily,
  }) {
    if (scale != null && scale.isFinite) fontScale = scale.clamp(.85, 1.35);
    if (dhikrSize != null && dhikrSize.isFinite) {
      adhkarFontSize = dhikrSize.clamp(22, 44);
    }
    if (['IBMPlexArabic', 'Amiri'].contains(family)) fontFamily = family!;
    if (['IBMPlexArabic', 'Amiri'].contains(dhikrFamily)) {
      adhkarFontFamily = dhikrFamily!;
    }
    _changed();
  }

  void setGoal(int goal) {
    if (goal < 0 || goal > 100000) return;
    salawatGoal = goal;
    _changed();
  }

  String _progressKey(Dhikr entry) => '${localDay(clock())}:${entry.id}';
  int completed(Dhikr entry) =>
      (_progress[_progressKey(entry)] ?? 0).clamp(0, entry.count);
  void repeatDhikr(Dhikr entry) {
    if (completed(entry) >= entry.count) return;
    _progress[_progressKey(entry)] = completed(entry) + 1;
    _changed();
  }

  void resetCategory(String category) {
    for (final entry in entries(category)) {
      _progress.remove(_progressKey(entry));
    }
    _changed();
  }

  List<Dhikr> entries(String category) =>
      adhkar.where((e) => e.category == category).toList();
  double categoryProgress(String category) {
    final values = entries(category);
    if (values.isEmpty) return 0;
    final total = values.fold(0, (n, e) => n + e.count);
    return values.fold(0, (n, e) => n + completed(e)) / total;
  }

  List<ReadingPosition> get bookmarks =>
      _bookmarks.map(ReadingPosition.parse).toList()..sort(
        (a, b) => a.surah == b.surah
            ? a.verse.compareTo(b.verse)
            : a.surah.compareTo(b.surah),
      );
  bool bookmarked(ReadingPosition p) => _bookmarks.contains(p.id);
  void toggleBookmark(ReadingPosition p) {
    if (!p.valid) return;
    if (!_bookmarks.remove(p.id)) _bookmarks.add(p.id);
    _changed();
  }

  void markReading(ReadingPosition position) {
    if (!position.valid) return;
    lastReading = position;
    _changed();
  }

  void refreshDate() {
    notifyListeners();
  }

  Map<String, dynamic> _snapshot() => {
    'version': 1,
    'dark': dark,
    'haptic': haptic,
    'quranVertical': quranVertical,
    'fontScale': fontScale,
    'adhkarFontSize': adhkarFontSize,
    'fontFamily': fontFamily,
    'adhkarFontFamily': adhkarFontFamily,
    'reminders': reminders.preferences.toJson(),
    'selectedPhrase': selectedPhrase,
    'salawatGoal': salawatGoal,
    'lastReading': lastReading?.id,
    'bookmarks': _bookmarks.toList(),
    'progress': Map<String, int>.of(_progress),
    'counters': _counters.map((k, v) => MapEntry(k, v.toJson())),
  };
  void _changed() {
    notifyListeners();
    unawaited(flush());
  }

  Future<void> flush() {
    // Capture each state before queueing; SQLite commits snapshots in tap order.
    final snapshot =
        jsonDecode(jsonEncode(_snapshot())) as Map<String, dynamic>;
    _pending = _pending.then((_) async {
      try {
        await store.write(snapshot);
        if (saveError != null) {
          saveError = null;
          if (!_closed) notifyListeners();
        }
      } catch (error, stack) {
        debugPrint('Local save failed: $error\n$stack');
        saveError = 'تعذر حفظ التغييرات. أعد المحاولة قبل إغلاق التطبيق.';
        if (!_closed) notifyListeners();
      }
    });
    return _pending;
  }

  @override
  void dispose() {
    _closed = true;
    reminders.dispose();
    super.dispose();
  }
}
