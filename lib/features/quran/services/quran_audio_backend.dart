import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

class RecitationState {
  const RecitationState({
    required this.playing,
    this.buffering = false,
    this.completed = false,
  });
  final bool playing, buffering, completed;
}

abstract interface class QuranAudioBackend {
  Stream<RecitationState> get states;
  Stream<Object> get errors;
  Future<void> load(Uri url);
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> setRepeat(bool repeat);
  Future<void> dispose();
}

class JustAudioQuranBackend implements QuranAudioBackend {
  JustAudioQuranBackend._(this._player);
  final AudioPlayer _player;
  static Future<QuranAudioBackend> create() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    return JustAudioQuranBackend._(AudioPlayer());
  }

  @override
  Stream<RecitationState> get states => _player.playerStateStream.map(
    (s) => RecitationState(
      playing: s.playing,
      buffering:
          s.processingState == ProcessingState.loading ||
          s.processingState == ProcessingState.buffering,
      completed: s.processingState == ProcessingState.completed,
    ),
  );
  @override
  Stream<Object> get errors => _player.errorStream;
  @override
  Future<void> load(Uri url) async {
    await _player.setUrl(url.toString());
  }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> setRepeat(bool repeat) =>
      _player.setLoopMode(repeat ? LoopMode.one : LoopMode.off);
  @override
  Future<void> dispose() => _player.dispose();
}
