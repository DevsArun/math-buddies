import 'package:flutter/services.dart';

import 'progress_store.dart';

/// Sound effects, background music and Buddy's voice — all through one tiny
/// platform channel. Every call is fire-and-forget and fails silently so the
/// app keeps working even if audio/TTS is unavailable on a device.
class MediaService {
  MediaService._();

  static const MethodChannel _channel = MethodChannel('mathbuddies/media');

  /// Play a sound effect (pop, click, sparkle, correct, wrong, star, win,
  /// jump, place, whoosh). Respects the grown-ups sound toggle.
  static Future<void> play(String name) async {
    if (!ProgressStore.instance.soundOn) return;
    try {
      await _channel
          .invokeMethod<void>('play', <String, String>{'name': name});
    } catch (_) {}
  }

  /// Buddy speaks. Respects the grown-ups sound toggle.
  static Future<void> say(String text) async {
    if (!ProgressStore.instance.soundOn || text.isEmpty) return;
    try {
      await _channel
          .invokeMethod<void>('speak', <String, String>{'text': text});
    } catch (_) {}
  }

  /// Background music on/off (not gated — caller passes the setting).
  static Future<void> setMusic(bool on) async {
    try {
      await _channel.invokeMethod<void>(on ? 'musicOn' : 'musicOff');
    } catch (_) {}
  }

  /// Call once on app start (and whenever the toggle changes).
  static Future<void> applyMusicSetting() =>
      setMusic(ProgressStore.instance.musicOn);
}
