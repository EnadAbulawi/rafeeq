import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rafeeq/features/quran/controllers/quran_audio_controller.dart';
import 'package:rafeeq/features/quran/repositories/quran_repository.dart';
import 'package:rafeeq/features/quran/services/quran_audio_backend.dart';

class FakeAudio implements QuranAudioBackend {
  final events = StreamController<RecitationState>.broadcast(sync: true);
  final failures = StreamController<Object>.broadcast(sync: true);
  final urls = <Uri>[];
  int plays = 0, pauses = 0, stops = 0, disposals = 0;
  bool repeating = false, failLoad = false;
  Completer<void>? gate;
  @override
  Stream<RecitationState> get states => events.stream;
  @override
  Stream<Object> get errors => failures.stream;
  @override
  Future<void> load(Uri url) async {
    urls.add(url);
    if (gate != null) await gate!.future;
    if (failLoad) throw StateError('network unavailable');
  }

  @override
  Future<void> play() async {
    plays++;
    events.add(const RecitationState(playing: true));
  }

  @override
  Future<void> pause() async {
    pauses++;
    events.add(const RecitationState(playing: false));
  }

  @override
  Future<void> stop() async {
    stops++;
    events.add(const RecitationState(playing: false));
  }

  @override
  Future<void> setRepeat(bool repeat) async {
    repeating = repeat;
  }

  @override
  Future<void> dispose() async {
    disposals++;
    await events.close();
    await failures.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(QuranRepository.load);
  late FakeAudio backend;
  late QuranAudioController audio;
  setUp(() {
    backend = FakeAudio();
    audio = QuranAudioController(createBackend: () async => backend);
  });
  tearDown(() {
    audio.dispose();
  });
  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
  }

  test('recitation URLs preserve three-digit surah and verse identifiers', () {
    expect(
      quranReciters.first.verseUrl(const ReadingPosition(2, 255)).toString(),
      'https://everyayah.com/data/Alafasy_128kbps/002255.mp3',
    );
    expect(
      quranReciters[1].verseUrl(const ReadingPosition(114, 6)).path,
      endsWith('/114006.mp3'),
    );
    expect(
      () => quranReciters.first.verseUrl(const ReadingPosition(0, 1)),
      throwsFormatException,
    );
  });
  test('audio is lazy and play pause resume do not reload the verse', () async {
    expect(backend.urls, isEmpty);
    await audio.toggle(const ReadingPosition(1, 1));
    expect(audio.playing, true);
    await audio.toggle(const ReadingPosition(1, 2));
    expect(audio.playing, false);
    await audio.toggle(const ReadingPosition(1, 2));
    expect(audio.playing, true);
    expect(backend.urls.length, 1);
    expect(backend.plays, 2);
    expect(backend.pauses, 1);
  });
  test('stop cancels pending load before playback starts', () async {
    backend.gate = Completer<void>();
    final pending = audio.playVerse(const ReadingPosition(1, 1));
    await settle();
    expect(audio.busy, true);
    await audio.stop();
    backend.gate!.complete();
    await pending;
    expect(audio.current, isNull);
    expect(backend.plays, 0);
    expect(audio.busy, false);
  });
  test(
    'changing reciter stops old audio before a new verse is played',
    () async {
      await audio.playVerse(const ReadingPosition(1, 1));
      await audio.selectReciter(2);
      expect(audio.current, isNull);
      expect(audio.playing, false);
      await audio.playVerse(const ReadingPosition(1, 2));
      expect(
        backend.urls.last.path,
        '/data/Abdul_Basit_Murattal_192kbps/001002.mp3',
      );
    },
  );
  test(
    'completion advances within a surah and stops at its last verse',
    () async {
      await audio.playVerse(const ReadingPosition(1, 6));
      backend.events.add(const RecitationState(playing: true, completed: true));
      await settle();
      expect(audio.current!.id, '1:7');
      backend.events.add(const RecitationState(playing: true, completed: true));
      await settle();
      expect(audio.current!.id, '1:7');
      expect(audio.playing, false);
      expect(audio.completed, true);
    },
  );
  test('single-verse mode and repeat do not auto-advance', () async {
    audio.setContinue(false);
    await audio.playVerse(const ReadingPosition(2, 1));
    backend.events.add(const RecitationState(playing: true, completed: true));
    await settle();
    expect(audio.current!.id, '2:1');
    audio.setContinue(true);
    await audio.setRepeat(true);
    await audio.playVerse(const ReadingPosition(2, 1));
    expect(backend.repeating, true);
    backend.events.add(const RecitationState(playing: true, completed: true));
    await settle();
    expect(audio.current!.id, '2:1');
  });
  test(
    'failed network load offers retry without losing the selected verse',
    () async {
      backend.failLoad = true;
      await audio.playVerse(const ReadingPosition(2, 255));
      expect(audio.error, isNotNull);
      expect(audio.busy, false);
      expect(audio.current!.id, '2:255');
      backend.failLoad = false;
      await audio.toggle(const ReadingPosition(1, 1));
      expect(audio.error, isNull);
      expect(audio.playing, true);
      expect(audio.current!.id, '2:255');
    },
  );
  test('backend error events surface without unhandled exceptions', () async {
    await audio.playVerse(const ReadingPosition(1, 1));
    backend.failures.add(StateError('decoder error'));
    expect(audio.error, isNotNull);
    expect(audio.playing, false);
  });
  test('initialization failure can be retried', () async {
    var attempts = 0;
    final other = QuranAudioController(
      createBackend: () async {
        if (++attempts == 1) throw StateError('initialization failed');
        return FakeAudio();
      },
    );
    await other.playVerse(const ReadingPosition(1, 1));
    expect(other.error, isNotNull);
    await other.playVerse(const ReadingPosition(1, 1));
    expect(other.playing, true);
    other.dispose();
  });
}
