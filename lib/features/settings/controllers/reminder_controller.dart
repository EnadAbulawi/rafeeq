import 'package:flutter/foundation.dart';

import '../models/reminder_preferences.dart';
import '../services/reminder_backend.dart';

class ReminderController extends ChangeNotifier {
  ReminderController({required this.onSaved, ReminderBackend? backend})
    : backend = backend ?? LocalReminderBackend();
  final VoidCallback onSaved;
  final ReminderBackend backend;
  ReminderPreferences preferences = const ReminderPreferences();
  final destination = ValueNotifier<String?>(null);
  bool busy = false, allowed = false, _initialized = false, _closed = false;
  int scheduledCount = 0;
  String? error;
  bool get supported => backend.supported;
  void _notify() {
    if (!_closed) notifyListeners();
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    await backend.initialize((target) {
      if (!_closed) destination.value = target;
    });
    _initialized = true;
  }

  Future<void> refresh() => _apply(preferences, request: false, save: false);
  Future<void> update(ReminderPreferences next) =>
      _apply(next, request: next.enabled && !preferences.enabled, save: true);
  Future<void> _apply(
    ReminderPreferences next, {
    required bool request,
    required bool save,
  }) async {
    if (busy || !supported || _closed) return;
    busy = true;
    error = null;
    _notify();
    try {
      await _initialize();
      allowed = await backend.permission(request: request);
      if (request && !allowed) {
        error = 'لم يُمنح إذن الإشعارات. يمكنك السماح به من إعدادات الجهاز.';
        return;
      }
      scheduledCount = await backend.replace(
        allowed ? next : next.copyWith(enabled: false),
      );
      if (save && !_closed) {
        preferences = next;
        onSaved();
      }
      if (next.enabled && !allowed) {
        error = 'الإشعارات محظورة من إعدادات الجهاز.';
      }
    } catch (e, stack) {
      scheduledCount = 0;
      error = 'تعذر تحديث التذكيرات. أعد المحاولة.';
      debugPrint('Reminder update failed: $e\n$stack');
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> test() async {
    if (busy || !supported) return;
    busy = true;
    error = null;
    _notify();
    try {
      await _initialize();
      allowed = await backend.permission(request: true);
      if (!allowed) {
        error = 'اسمح بالإشعارات من إعدادات الجهاز لإرسال التجربة.';
        return;
      }
      await backend.test(preferences.sound);
    } catch (_) {
      error = 'تعذر إرسال إشعار التجربة.';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> openSettings() async {
    try {
      await backend.openSettings();
    } catch (_) {
      error = 'افتح إعدادات الجهاز ثم إشعارات رفيق.';
      _notify();
    }
  }

  @override
  void dispose() {
    _closed = true;
    destination.dispose();
    super.dispose();
  }
}
