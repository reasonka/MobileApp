import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const _poolSize = 3;

  final List<AudioPlayer> _popPlayers = List.generate(_poolSize, (_) => AudioPlayer());
  final List<AudioPlayer> _donePlayers = List.generate(_poolSize, (_) => AudioPlayer());
  final List<AudioPlayer> _delPlayers = List.generate(_poolSize, (_) => AudioPlayer());
  final List<AudioPlayer> _swipePlayers = List.generate(_poolSize, (_) => AudioPlayer());
  final List<AudioPlayer> _undoPlayers = List.generate(_poolSize, (_) => AudioPlayer());

  final AudioPlayer _bgmPlayer = AudioPlayer();
  bool _bgmPlaying = false;

  int _popIndex = 0, _doneIndex = 0, _delIndex = 0, _swipeIndex = 0, _undoIndex = 0;
  final _random = Random();

  double _masterVolume = 1.0;
  double _sfxVolume = 1.0;
  double _bgmVolume = 1.0;
  bool _userPaused = false;

  double get masterVolume => _masterVolume;
  double get sfxVolume => _sfxVolume;
  double get bgmVolume => _bgmVolume;

  static const _kMasterKey = 'sound_master_volume';
  static const _kSfxKey = 'sound_sfx_volume';
  static const _kBgmKey = 'sound_bgm_volume';

  List<AudioPlayer> get _allSfxPlayers => [
        ..._popPlayers, ..._donePlayers, ..._delPlayers, ..._swipePlayers, ..._undoPlayers,
      ];

  double get _effSfx => (_masterVolume * _sfxVolume).clamp(0.0, 1.0);
  double get _effBgm => (_masterVolume * _bgmVolume).clamp(0.0, 1.0);

  Future<void> init() async {
  final prefs = await SharedPreferences.getInstance();
  _masterVolume = prefs.getDouble(_kMasterKey) ?? 1.0;
  _sfxVolume = prefs.getDouble(_kSfxKey) ?? 1.0;
  _bgmVolume = prefs.getDouble(_kBgmKey) ?? 1.0;


  final bgmContext = AudioContext(
    android: AudioContextAndroid(
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.gain,
    ),
    iOS: AudioContextIOS(
  category: AVAudioSessionCategory.ambient,
),
  );

  // SFX use a weaker focus mode so they duck instead of killing BGM.
  // SFX should never touch audio focus — they just mix on top of BGM.
final sfxContext = AudioContext(
  android: AudioContextAndroid(
    contentType: AndroidContentType.sonification,
    usageType: AndroidUsageType.media,
    audioFocus: AndroidAudioFocus.none,
  ),
  iOS: AudioContextIOS(
  category: AVAudioSessionCategory.ambient,
),
);
  await _bgmPlayer.setAudioContext(bgmContext);
  for (final p in _allSfxPlayers) {
    await p.setAudioContext(sfxContext);
  }

  await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
  await _bgmPlayer.setVolume(_effBgm);

_bgmPlayer.onPlayerStateChanged.listen((state) {
  final wasPlaying = _bgmPlaying;
  _bgmPlaying = state == PlayerState.playing;
  // If BGM unexpectedly drops to paused/stopped while we still want it
  // running (i.e. we didn't call stopBgm()/pauseBgm() ourselves), resume it.
  if (wasPlaying && state != PlayerState.playing && !_userPaused) {
    _bgmPlayer.resume();
  }
});
}

  Future<void> setMasterVolume(double v) async {
    _masterVolume = v.clamp(0.0, 1.0);
    (await SharedPreferences.getInstance()).setDouble(_kMasterKey, _masterVolume);
    await _bgmPlayer.setVolume(_effBgm);
  }

  Future<void> setSfxVolume(double v) async {
    _sfxVolume = v.clamp(0.0, 1.0);
    (await SharedPreferences.getInstance()).setDouble(_kSfxKey, _sfxVolume);
  }

  Future<void> setBgmVolume(double v) async {
    _bgmVolume = v.clamp(0.0, 1.0);
    (await SharedPreferences.getInstance()).setDouble(_kBgmKey, _bgmVolume);
    await _bgmPlayer.setVolume(_effBgm);
  }

  Future<void> preload() async {
    for (final p in _allSfxPlayers) {
      await p.setVolume(0);
      await p.setReleaseMode(ReleaseMode.stop);
    }
    await Future.wait([
      for (final p in _popPlayers) p.play(AssetSource('sounds/bubblePop.mp3')),
      for (final p in _donePlayers) p.play(AssetSource('sounds/done.mp3')),
      for (final p in _delPlayers) p.play(AssetSource('sounds/delete.mp3')),
      for (final p in _swipePlayers) p.play(AssetSource('sounds/swipe.mp3')),
      for (final p in _undoPlayers) p.play(AssetSource('sounds/Undo.mp3')),
    ]);
    await Future.delayed(const Duration(milliseconds: 500));
    for (final p in _allSfxPlayers) {
      await p.stop();
    }
  }

  Future<void> _playPooled(List<AudioPlayer> pool, int Function() nextIndex, String asset) async {
    final player = pool[nextIndex()];
    await player.stop();
    await player.setVolume(_effSfx);
    await player.play(AssetSource(asset));
  }

  Future<void> playPop() => _playPooled(
        _popPlayers,
        () { final i = _popIndex; _popIndex = (_popIndex + 1) % _poolSize; return i; },
        _random.nextBool() ? 'sounds/bubblePop.mp3' : 'sounds/bubblePop2.mp3',
      );

  Future<void> playDone() => _playPooled(
        _donePlayers,
        () { final i = _doneIndex; _doneIndex = (_doneIndex + 1) % _poolSize; return i; },
        'sounds/done.mp3',
      );

  Future<void> playDelete() => _playPooled(
        _delPlayers,
        () { final i = _delIndex; _delIndex = (_delIndex + 1) % _poolSize; return i; },
        'sounds/delete.mp3',
      );

  Future<void> playSwipe() => _playPooled(
        _swipePlayers,
        () { final i = _swipeIndex; _swipeIndex = (_swipeIndex + 1) % _poolSize; return i; },
        'sounds/swipe.mp3',
      );

  /// Uncheck / cancel / close-without-deleting.
  Future<void> playUndo() => _playPooled(
        _undoPlayers,
        () { final i = _undoIndex; _undoIndex = (_undoIndex + 1) % _poolSize; return i; },
        'sounds/Undo.mp3',
      );

  Future<void> playBgm() async {
  if (_bgmPlaying) return;
  _userPaused = false;
  await _bgmPlayer.setVolume(_effBgm);
  await _bgmPlayer.play(AssetSource('sounds/BGM.mp3'));
  _bgmPlaying = true;
}

 Future<void> stopBgm() async {
  if (!_bgmPlaying) return;
  _userPaused = true;
  _bgmPlaying = false;
  await _bgmPlayer.stop();
}

Future<void> pauseBgm() async {
  if (_bgmPlaying) {
    _userPaused = true;
    await _bgmPlayer.pause();
  }
}

Future<void> resumeBgm() async {
  if (_bgmPlaying) {
    _userPaused = false;
    await _bgmPlayer.resume();
  }
}

 
}