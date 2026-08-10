import 'package:flutter/material.dart';

import '../data/media.dart';
import '../data/progress_store.dart';
import '../games/rewards.dart';
import 'theme.dart';
import 'widgets/effects.dart';
import 'widgets/game_widgets.dart';

/// Sticker Book (collection) + My Space Scene (decorate) + Trophies.
class StickersScreen extends StatefulWidget {
  const StickersScreen({super.key});

  @override
  State<StickersScreen> createState() => _StickersScreenState();
}

class _StickersScreenState extends State<StickersScreen> {
  int _mode = 0; // 0 = book, 1 = scene, 2 = trophies

  @override
  Widget build(BuildContext context) {
    final ProgressStore store = ProgressStore.instance;
    return Scaffold(
      body: AnimatedGradientBg(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _header(store),
              _modeSwitch(),
              const SizedBox(height: 8),
              Expanded(
                child: _mode == 0
                    ? _buildBook(store)
                    : _mode == 1
                        ? _buildScene(store)
                        : _buildTrophies(store),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(ProgressStore store) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: <Widget>[
          RoundIconButton(emoji: '⬅️', onTap: () => Navigator.of(context).pop()),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'My Stickers',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '🏅 ${store.stickers.length}/${kStickers.length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeSwitch() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      children: <Widget>[
        _modeButton('📖 Book', _mode == 0, () {
          MediaService.play('click');
          setState(() => _mode = 0);
        }),
        _modeButton('🌌 My Scene', _mode == 1, () {
          MediaService.play('click');
          setState(() => _mode = 1);
        }),
        _modeButton('🏆 Trophies', _mode == 2, () {
          MediaService.play('click');
          setState(() => _mode = 2);
        }),
      ],
    );
  }

  Widget _modeButton(String label, bool active, VoidCallback onTap) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF7C5CFF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: active ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }

  // ---------------- sticker book ----------------

  Widget _buildBook(ProgressStore store) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 130,
        childAspectRatio: 0.95,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: kStickers.length,
      itemBuilder: (BuildContext context, int i) {
        final StickerDef def = kStickers[i];
        final bool earned = store.stickers.contains(def.id);
        return PopIn(
          delayMs: i * 40,
          child: Container(
            decoration: BoxDecoration(
              color: earned ? Colors.white : const Color(0xFFEDEAF6),
              borderRadius: BorderRadius.circular(22),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: earned
                  ? Text(def.emoji, style: const TextStyle(fontSize: 52))
                  : const Text('❔', style: TextStyle(fontSize: 44)),
            ),
          ),
        );
      },
    );
  }

  // ---------------- trophies ----------------

  Widget _buildTrophies(ProgressStore store) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 230,
        childAspectRatio: 1.5,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: kTrophies.length,
      itemBuilder: (BuildContext context, int i) {
        final TrophyDef t = kTrophies[i];
        final bool earned = trophyEarned(t.id, store);
        return PopIn(
          delayMs: i * 60,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: earned ? Colors.white : const Color(0xFFEDEAF6),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: earned
                    ? const Color(0xFFFAD961)
                    : Colors.transparent,
                width: 3,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  earned ? t.emoji : '🔒',
                  style: const TextStyle(fontSize: 38),
                ),
                const SizedBox(height: 4),
                Text(
                  t.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: earned ? AppColors.ink : AppColors.softGrey,
                  ),
                ),
                Text(
                  t.how,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.softGrey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- my space scene ----------------

  Widget _buildScene(ProgressStore store) {
    final List<String> earned = store.stickers
        .where((String id) => kStickers.any((StickerDef d) => d.id == id))
        .toList();
    if (earned.isEmpty) {
      return const Center(
        child: Text(
          'Play games to win stickers! 🎮',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.softGrey,
          ),
        ),
      );
    }
    return Column(
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints c) {
                  final double w = c.maxWidth;
                  final double h = c.maxHeight;
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Color(0xFF2B2565), Color(0xFF5B54E8)],
                      ),
                    ),
                    child: Stack(
                      children: <Widget>[
                        const Positioned.fill(child: FloatingStars()),
                        const Positioned(
                          left: 16,
                          top: 12,
                          child: Text('🪐', style: TextStyle(fontSize: 44)),
                        ),
                        const Positioned(
                          right: 20,
                          bottom: 16,
                          child: Text('🌍', style: TextStyle(fontSize: 54)),
                        ),
                        for (final MapEntry<String, List<double>> e
                            in store.scene.entries)
                          Positioned(
                            left: e.value[0] * w - 30,
                            top: e.value[1] * h - 30,
                            child: GestureDetector(
                              onPanUpdate: (DragUpdateDetails d) {
                                setState(() {
                                  store.scene[e.key] = <double>[
                                    ((e.value[0] * w + d.delta.dx) / w),
                                    ((e.value[1] * h + d.delta.dy) / h),
                                  ];
                                });
                              },
                              onPanEnd: (_) {
                                final List<double> pos = store.scene[e.key]!;
                                store.setScenePos(e.key, pos[0], pos[1]);
                                MediaService.play('place');
                              },
                              onLongPress: () {
                                MediaService.play('pop');
                                setState(() => store.removeFromScene(e.key));
                              },
                              child: Text(
                                stickerEmoji(e.key),
                                style: const TextStyle(fontSize: 48),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tap a sticker to add it • drag to move • hold to remove',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.softGrey,
          ),
        ),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: earned.length,
            separatorBuilder: (BuildContext context, int i) =>
                const SizedBox(width: 10),
            itemBuilder: (BuildContext context, int i) {
              final String id = earned[i];
              return Pressable(
                onTap: () {
                  MediaService.play('place');
                  setState(() {
                    store.setScenePos(id, 0.5, 0.4 + (i % 3) * 0.08);
                  });
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(stickerEmoji(id),
                        style: const TextStyle(fontSize: 36)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
