import 'dart:convert';

import 'package:flutter/services.dart';

/// On-device progress (stars, bonus stars, daily chest, buddy color,
/// stickers, play time, sticker scene, settings). Saved as a tiny JSON file
/// through a minimal platform channel — zero plugins, zero permissions
/// (rule J11). Falls back to in-memory progress if the channel is missing.
class ProgressStore {
  ProgressStore._();
  static final ProgressStore instance = ProgressStore._();

  static const MethodChannel _channel = MethodChannel('mathbuddies/storage');

  final Map<String, int> stars = <String, int>{};
  final Set<String> stickers = <String>{};
  final Map<String, int> playSeconds = <String, int>{};

  /// Sticker scene: stickerId -> [xFraction, yFraction] on the canvas.
  final Map<String, List<double>> scene = <String, List<double>>{};

  /// Bonus stars from the daily treasure chest.
  int bonusStars = 0;

  /// Last day the chest was opened ('yyyy-MM-dd'), '' = never.
  String lastChest = '';

  /// Buddy accent color index: 0 purple, 1 orange, 2 teal.
  int buddyColor = 0;

  /// 'little' (ages 3-4), 'big' (ages 5-6), or null when not chosen yet.
  String? ageGroup;
  bool musicOn = true;
  bool soundOn = true;

  Future<void>? _loadFuture;

  Future<void> load() => _loadFuture ??= _loadInternal();

  static String todayKey() {
    final DateTime now = DateTime.now();
    final String m = now.month.toString().padLeft(2, '0');
    final String d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  Future<void> _loadInternal() async {
    try {
      final String? raw = await _channel.invokeMethod<String>('load');
      if (raw != null && raw.isNotEmpty) {
        final Object? data = jsonDecode(raw);
        if (data is Map) {
          _readIntMap(data['stars'], stars);
          _readIntMap(data['playSeconds'], playSeconds);
          final Object? st = data['stickers'];
          if (st is List) {
            stickers.addAll(st.map((Object? e) => '$e'));
          }
          final Object? sc = data['scene'];
          if (sc is Map) {
            sc.forEach((Object? k, Object? v) {
              if (v is List && v.length == 2) {
                final double? x = (v[0] as num?)?.toDouble();
                final double? y = (v[1] as num?)?.toDouble();
                if (x != null && y != null) scene['$k'] = <double>[x, y];
              }
            });
          }
          final Object? b = data['bonusStars'];
          if (b is int) bonusStars = b;
          final Object? lc = data['lastChest'];
          if (lc is String) lastChest = lc;
          final Object? bc = data['buddyColor'];
          if (bc is int && bc >= 0 && bc <= 2) buddyColor = bc;
          final Object? settings = data['settings'];
          if (settings is Map) {
            final Object? age = settings['age'];
            if (age == 'little' || age == 'big') ageGroup = age as String;
            final Object? m = settings['music'];
            if (m is bool) musicOn = m;
            final Object? s = settings['sound'];
            if (s is bool) soundOn = s;
          }
        }
      }
    } catch (_) {
      // Storage unavailable -> memory-only progress. App keeps working.
    }
  }

  void _readIntMap(Object? src, Map<String, int> dst) {
    if (src is Map) {
      src.forEach((Object? k, Object? v) {
        if (v is int) dst['$k'] = v;
      });
    }
  }

  Future<void> save() async {
    try {
      await _channel.invokeMethod<void>(
        'save',
        jsonEncode(<String, Object?>{
          'stars': stars,
          'stickers': stickers.toList(),
          'playSeconds': playSeconds,
          'scene': scene,
          'bonusStars': bonusStars,
          'lastChest': lastChest,
          'buddyColor': buddyColor,
          'settings': <String, Object?>{
            'age': ageGroup,
            'music': musicOn,
            'sound': soundOn,
          },
        }),
      );
    } catch (_) {
      // Ignore: progress simply stays in memory this session.
    }
  }

  // ---- stars ----
  int starsFor(String gameId) => stars[gameId] ?? 0;

  int get totalStars =>
      stars.values.fold(0, (int a, int b) => a + b) + bonusStars;

  void addStar(String gameId) {
    stars[gameId] = starsFor(gameId) + 1;
    save();
  }

  // ---- daily chest ----
  bool get chestAvailable => lastChest != todayKey();

  /// Opens today's chest; returns stars won (0 if already opened today).
  int openChest() {
    if (!chestAvailable) return 0;
    bonusStars += 5;
    lastChest = todayKey();
    save();
    return 5;
  }

  // ---- buddy color ----
  void setBuddyColor(int index) {
    buddyColor = index.clamp(0, 2);
    save();
  }

  // ---- stickers ----
  void addSticker(String stickerId) {
    if (stickers.add(stickerId)) save();
  }

  // ---- play time ----
  void addPlayTime(String gameId, int seconds) {
    if (seconds <= 0) return;
    playSeconds[gameId] = playSecondsFor(gameId) + seconds;
    save();
  }

  int playSecondsFor(String gameId) => playSeconds[gameId] ?? 0;

  int get totalPlaySeconds =>
      playSeconds.values.fold(0, (int a, int b) => a + b);

  // ---- settings ----
  void setAgeGroup(String group) {
    ageGroup = group;
    save();
  }

  void setMusicOn(bool value) {
    musicOn = value;
    save();
  }

  void setSoundOn(bool value) {
    soundOn = value;
    save();
  }

  // ---- sticker scene ----
  void setScenePos(String stickerId, double fx, double fy) {
    scene[stickerId] = <double>[fx.clamp(0.02, 0.98), fy.clamp(0.02, 0.98)];
    save();
  }

  void removeFromScene(String stickerId) {
    if (scene.remove(stickerId) != null) save();
  }

  Future<void> reset() async {
    stars.clear();
    stickers.clear();
    playSeconds.clear();
    scene.clear();
    bonusStars = 0;
    lastChest = '';
    await save();
  }
}
