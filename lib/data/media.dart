import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'progress_store.dart';

/// What Buddy is saying right now (shown in his speech bubble).
class BuddyVoice {
  BuddyVoice._();

  static final ValueNotifier<String> text = ValueNotifier<String>('');
  static Timer? _clearTimer;

  static void show(String message) {
    if (message.isEmpty) return;
    text.value = message;
    _clearTimer?.cancel();
    _clearTimer = Timer(const Duration(milliseconds: 2800), () {
      text.value = '';
    });
  }
}

/// Sound effects, background music and Buddy's voice — all through one tiny
/// platform channel. Every call is fire-and-forget and fails silently so the
/// app keeps working even if audio/TTS is unavailable on a device.
class MediaService {
  MediaService._();

  static const MethodChannel _channel = MethodChannel('mathbuddies/media');

  /// Play a sound effect (pop, click, sparkle, correct, wrong, star, win,
  /// jump, place, whoosh, flip, chest). Respects the grown-ups sound toggle.
  static Future<void> play(String name) async {
    if (!ProgressStore.instance.soundOn) return;
    try {
      await _channel
          .invokeMethod<void>('play', <String, String>{'name': name});
    } catch (_) {}
  }

  /// Buddy speaks (device TTS) AND shows the line in his speech bubble.
  static Future<void> say(String text) async {
    if (text.isEmpty) return;
    BuddyVoice.show(text);
    if (!ProgressStore.instance.soundOn) return;
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
