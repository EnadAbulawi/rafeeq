import 'dart:async';

import 'package:flutter/foundation.dart';

import '../repositories/quran_repository.dart';
import '../services/quran_audio_backend.dart';

class QuranReciter {
  const QuranReciter(this.name, this.directory);
  final String name, directory;
  Uri verseUrl(ReadingPosition position) {
    if (!position.valid) throw const FormatException('Invalid audio verse');
    final id =
        '${position.surah.toString().padLeft(3, '0')}${position.verse.toString().padLeft(3, '0')}';
    return Uri.https('everyayah.com', '/data/$directory/$id.mp3');
  }
}

const quranReciters = [
  QuranReciter('مشاري العفاسي', 'Alafasy_128kbps'),
  QuranReciter('محمود خليل الحصري', 'Husary_128kbps'),
  QuranReciter('عبد الباسط عبد الصمد', 'Abdul_Basit_Murattal_192kbps'),
];

class QuranAudioController extends ChangeNotifier {
  QuranAudioController({Future<QuranAudioBackend> Function()? createBackend})
    : _create = createBackend ?? JustAudioQuranBackend.create;
  final Future<QuranAudioBackend> Function() _create;
  Future<QuranAudioBackend>? _initializing;
  QuranAudioBackend? _backend;
  StreamSubscription<RecitationState>? _stateSubscription;
  StreamSubscription<Object>? _errorSubscription;
  ReadingPosition? current;
  int reciterIndex = 0;
  bool playing = false, busy = false, completed = false;
  bool repeat = false, continueRecitation = true;
  String? error;
  int _request = 0;
  bool _disposed = false;

  Future<QuranAudioBackend> _ready() => _initializing ??= () async {
    final backend = await _create();
    if (_disposed) {
      await backend.dispose();
      return backend;
    }
    _backend = backend;
    _stateSubscription = backend.states.listen((state) {
      if (_disposed) return;
      playing = state.playing && !state.completed;
      if (!busy) {
        completed = state.completed;
        final p = current;
        if (state.completed && !repeat && continueRecitation && p != null) {
          if (p.verse < QuranRepository().count(p.surah)) {
            unawaited(playVerse(ReadingPosition(p.surah, p.verse + 1)));
          }
        }
      }
      _notify();
    });
    _errorSubscription = backend.errors.listen((e) => _fail(e));
    return backend;
  }();

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _fail(Object e) {
    if (_disposed) return;
    debugPrint('Quran audio failed: $e');
    busy = false;
    playing = false;
    error = 'تعذر تشغيل التلاوة. تحقق من الإنترنت ثم أعد المحاولة.';
    _notify();
  }

  Future<void> playVerse(ReadingPosition position) async {
    if (!position.valid || _disposed) return;
    final token = ++_request;
    current = position;
    busy = true;
    completed = false;
    error = null;
    _notify();
    try {
      final backend = await _ready();
      if (_disposed || token != _request) return;
      await backend.setRepeat(repeat);
      await backend.load(quranReciters[reciterIndex].verseUrl(position));
      if (_disposed || token != _request) return;
      busy = false;
      _notify();
      unawaited(_start(backend, token));
    } catch (e) {
      if (token == _request && !_disposed) {
        if (_backend == null) _initializing = null;
        _fail(e);
      }
    }
  }

  Future<void> _start(QuranAudioBackend backend, int token) async {
    try {
      await backend.play();
    } catch (e) {
      if (token == _request) _fail(e);
    }
  }

  Future<void> toggle(ReadingPosition fallback) async {
    if (busy) return;
    if (playing) {
      await pause();
      return;
    }
    if (current == null || completed || error != null) {
      await playVerse(current ?? fallback);
      return;
    }
    final backend = _backend;
    if (backend != null) unawaited(_start(backend, _request));
  }

  Future<void> pause() async {
    try {
      await _backend?.pause();
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> stop() async {
    ++_request;
    busy = false;
    current = null;
    completed = false;
    playing = false;
    error = null;
    _notify();
    try {
      await _backend?.stop();
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> selectReciter(int index) async {
    if (index < 0 || index >= quranReciters.length) return;
    reciterIndex = index;
    await stop();
  }

  Future<void> setRepeat(bool value) async {
    repeat = value;
    _notify();
    try {
      await _backend?.setRepeat(value);
    } catch (e) {
      _fail(e);
    }
  }

  void setContinue(bool value) {
    continueRecitation = value;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_request;
    unawaited(_stateSubscription?.cancel());
    unawaited(_errorSubscription?.cancel());
    final backend = _backend;
    if (backend != null) unawaited(backend.dispose());
    super.dispose();
  }
}
