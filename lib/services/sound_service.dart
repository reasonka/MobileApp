import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final _pop1 = AudioPlayer();
  final _pop2 = AudioPlayer();
  final _done = AudioPlayer();
  final _del  = AudioPlayer();
  final _random = Random();
  final _swipe = AudioPlayer();

  
  Future<void> preload() async {
  await _pop1.setVolume(0);
  await _pop2.setVolume(0);
  await _done.setVolume(0);
  await _del.setVolume(0);
  await _swipe.setVolume(0);

  await _pop1.play(AssetSource('sounds/bubblePop.mp3'));
  await _pop2.play(AssetSource('sounds/bubblePop2.mp3'));
  await _done.play(AssetSource('sounds/done.mp3'));
  await _del.play(AssetSource('sounds/delete.mp3'));
  await _swipe.play(AssetSource('sounds/swipe.mp3'));

  await Future.delayed(const Duration(milliseconds: 500));

  await _pop1.setVolume(1);
  await _pop2.setVolume(1);
  await _done.setVolume(1);
  await _del.setVolume(1);
  await _swipe.setVolume(1); 
}

  Future<void> playPop() async {
  final sound = _random.nextBool()
      ? 'sounds/bubblePop.mp3'
      : 'sounds/bubblePop2.mp3';
  await _pop1.play(AssetSource(sound));
}

Future<void> playDone() async {
  await _done.play(AssetSource('sounds/done.mp3'));
}

Future<void> playDelete() async {
  await _del.play(AssetSource('sounds/delete.mp3'));
}

Future<void> playSwipe() async {
  await _swipe.play(AssetSource('sounds/swipe.mp3'));
}
}