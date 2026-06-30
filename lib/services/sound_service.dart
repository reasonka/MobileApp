import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const _poolSize = 3;

  final List<AudioPlayer> _popPlayers = List.generate(_poolSize, (_) => AudioPlayer());
  final List<AudioPlayer> _donePlayers = List.generate(_poolSize, (_) => AudioPlayer());
  final List<AudioPlayer> _delPlayers = List.generate(_poolSize, (_) => AudioPlayer());
  final List<AudioPlayer> _swipePlayers = List.generate(_poolSize, (_) => AudioPlayer());

  int _popIndex = 0;
  int _doneIndex = 0;
  int _delIndex = 0;
  int _swipeIndex = 0;

  final _random = Random();

  List<AudioPlayer> get _allPlayers => [
        ..._popPlayers,
        ..._donePlayers,
        ..._delPlayers,
        ..._swipePlayers,
      ];

  Future<void> preload() async {
    for (final p in _allPlayers) {
      await p.setVolume(0);
      await p.setReleaseMode(ReleaseMode.stop);
    }

    await Future.wait([
      for (final p in _popPlayers) p.play(AssetSource('sounds/bubblePop.mp3')),
      for (final p in _donePlayers) p.play(AssetSource('sounds/done.mp3')),
      for (final p in _delPlayers) p.play(AssetSource('sounds/delete.mp3')),
      for (final p in _swipePlayers) p.play(AssetSource('sounds/swipe.mp3')),
    ]);

    await Future.delayed(const Duration(milliseconds: 500));

    for (final p in _allPlayers) {
      await p.stop();
      await p.setVolume(1);
    }
  }

  Future<void> playPop() async {
    final sound = _random.nextBool()
        ? 'sounds/bubblePop.mp3'
        : 'sounds/bubblePop2.mp3';
    final player = _popPlayers[_popIndex];
    _popIndex = (_popIndex + 1) % _poolSize;
    await player.stop();
    await player.play(AssetSource(sound));
  }

  Future<void> playDone() async {
    final player = _donePlayers[_doneIndex];
    _doneIndex = (_doneIndex + 1) % _poolSize;
    await player.stop();
    await player.play(AssetSource('sounds/done.mp3'));
  }

  Future<void> playDelete() async {
    final player = _delPlayers[_delIndex];
    _delIndex = (_delIndex + 1) % _poolSize;
    await player.stop();
    await player.play(AssetSource('sounds/delete.mp3'));
  }

  Future<void> playSwipe() async {
    final player = _swipePlayers[_swipeIndex];
    _swipeIndex = (_swipeIndex + 1) % _poolSize;
    await player.stop();
    await player.play(AssetSource('sounds/swipe.mp3'));
  }
}