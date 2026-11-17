import 'package:flutter/foundation.dart';
import 'package:rafeeq/features/settings/models/reminder_preferences.dart';
import 'package:rafeeq/features/settings/services/reminder_backend.dart';

class FakeReminderBackend implements ReminderBackend {
  @override
  bool supported = true;
  bool allowed = true, fail = false;
  int prompts = 0, initialized = 0, tests = 0, settingsOpened = 0;
  final applied = <ReminderPreferences>[];
  ValueChanged<String>? onOpen;
  @override
  Future<void> initialize(ValueChanged<String> callback) async {
    initialized++;
    onOpen = callback;
  }

  @override
  Future<bool> permission({bool request = false}) async {
    if (request) prompts++;
    return allowed;
  }

  @override
  Future<int> replace(ReminderPreferences preferences) async {
    if (fail) throw StateError('schedule failure');
    applied.add(preferences);
    return preferences.enabled
        ? preferences.times.where((t) => t.enabled).length
        : 0;
  }

  @override
  Future<void> test(bool sound) async {
    tests++;
  }

  @override
  Future<void> openSettings() async {
    settingsOpened++;
  }
}
