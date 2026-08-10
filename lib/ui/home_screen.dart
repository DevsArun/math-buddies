import 'package:flutter/material.dart';

import '../data/media.dart';
import '../data/progress_store.dart';
import '../games/bubbles/bubbles_game.dart';
import '../games/compare/compare_game.dart';
import '../games/counting/counting_game.dart';
import '../games/jodtod/jodtod_game.dart';
import '../games/memory/memory_game.dart';
import '../games/patterns/patterns_game.dart';
import '../games/rewards.dart';
import '../games/shapes/shapes_game.dart';
import '../games/tracing/tracing_game.dart';
import 'buddy.dart';
import 'settings_screen.dart';
import 'stickers_screen.dart';
import 'theme.dart';
import 'widgets/effects.dart';
import 'widgets/game_widgets.dart';
import 'widgets/parental_gate.dart';

class GameInfo {
  final String id;
  final String title;
  final String world;
  final String emoji;
  final List<Color> gradient;
  const GameInfo(this.id, this.title, this.world, this.emoji, this.gradient);
}

final List<GameInfo> kGames = <GameInfo>[
  GameInfo('counting', 'Counting', 'Farm World', '🍎', AppColors.gameGradients[0]),
  GameInfo('tracing', 'Trace Numbers', 'Space Station', '✏️', AppColors.gameGradients[1]),
  GameInfo('jodtod', 'Add & Take Away', 'Ocean Bay', '➕', AppColors.gameGradients[2]),
  GameInfo('shapes', 'Shapes', 'Shape Kingdom', '🔷', AppColors.gameGradients[3]),
  GameInfo('patterns', 'Patterns', 'Jungle Jam', '🎨', AppColors.gameGradients[4]),
  GameInfo('compare', 'Big & Small', 'Dino Valley', '⚖️', AppColors.gameGradients[5]),
  GameInfo('bubbles', 'Bubble Pop', 'Bubble Sky', '🫧', AppColors.gameGradients[6]),
  GameInfo('memory', 'Memory Match', 'Memory Meadow', '🃏', AppColors.gameGradients[7]),
];

/// Adventure Map home: a winding path of planet-worlds, one per game.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _openGame(String id) async {
    await MediaService.play('whoosh');
    final Widget screen = switch (id) {
      'counting' => const CountingGame(),
      'tracing' => const TracingGame(),
      'jodtod' => const JodTodGame(),
      'shapes' => const ShapesGame(),
      'patterns' => const PatternsGame(),
      'compare' => const CompareGame(),
      'bubbles' => const BubblesGame(),
      'memory' => const MemoryGame(),
      _ => const CountingGame(),
    };
    if (!mounted) return;
    await Navigator.of(context).push(fancyRoute<void>(screen));
    setState(() {}); // refresh stars after returning
  }

  Future<void> _openChest() async {
    final ProgressStore store = ProgressStore.instance;
    if (!store.chestAvailable) {
      await MediaService.say('Come back tomorrow for more treasure!');
      return;
    }
    final int won = store.openChest();
    await MediaService.play('chest');
    await MediaService.say('Daily treasure! $won bonus stars!');
    if (!mounted) return;
    setState(() {});
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('🎁', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 8),
              Text(
                '+$won ⭐',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const Text(
                'Daily treasure! Come back tomorrow!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.softGrey,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            Center(
              child: BigButton(
                label: 'Yay!',
                emoji: '🎉',
                colors: const <Color>[Color(0xFFFAD961), Color(0xFFF76B1C)],
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        );
      },
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ProgressStore store = ProgressStore.instance;
    return Scaffold(
      body: AnimatedGradientBg(
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              const FloatingStars(),
              ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: <Widget>[
                  _header(store),
                  const SizedBox(height: 6),
                  for (int i = 0; i < kGames.length; i++) ...<Widget>[
                    _mapRow(kGames[i], i, store),
                    if (i < kGames.length - 1) _PathConnector(flip: i.isEven),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(ProgressStore store) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 6),
      child: Row(
        children: <Widget>[
          Buddy(
            mood: BuddyMood.happy,
            size: 84,
            accent: AppColors.buddyAccents[store.buddyColor],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Math Buddies',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '⭐ ${store.totalStars}   🏅 ${store.stickers.length}/${kStickers.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: <Widget>[
              Pressable(
                onTap: _openChest,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: store.chestAvailable
                        ? const Color(0xFFFFF3D6)
                        : Colors.white.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: store.chestAvailable
                            ? const Color(0xFFFAD961).withValues(alpha: 0.8)
                            : Colors.black.withValues(alpha: 0.08),
                        blurRadius: store.chestAvailable ? 14 : 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '🎁',
                      style: TextStyle(
                        fontSize: 26,
                        color: store.chestAvailable ? null : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              RoundIconButton(
                emoji: '🎒',
                onTap: () async {
                  await MediaService.play('jump');
                  if (!context.mounted) return;
                  await Navigator.of(context)
                      .push(fancyRoute<void>(const StickersScreen()));
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              RoundIconButton(
                emoji: '⚙️',
                onTap: () async {
                  final bool ok = await showParentalGate(context);
                  if (ok && context.mounted) {
                    await Navigator.of(context)
                        .push(fancyRoute<void>(const SettingsScreen()));
                    setState(() {});
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mapRow(GameInfo game, int index, ProgressStore store) {
    final bool left = index.isEven;
    final int stars = store.starsFor(game.id);
    final Widget planet = Pressable(
      onTap: () => _openGame(game.id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: game.gradient,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: game.gradient.last.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Center(
              child: Text(game.emoji, style: const TextStyle(fontSize: 42)),
            ),
          ),
          if (stars > 0)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '⭐ $stars',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
        ],
      ),
    );

    final Widget label = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            left ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            game.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          Text(
            game.world,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.softGrey,
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisAlignment:
            left ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: left
            ? <Widget>[planet, const SizedBox(width: 16), Flexible(child: label)]
            : <Widget>[Flexible(child: label), const SizedBox(width: 16), planet],
      ),
    );
  }
}

/// Dotted winding path between the planets.
class _PathConnector extends StatelessWidget {
  final bool flip;
  const _PathConnector({required this.flip});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      width: double.infinity,
      child: CustomPaint(painter: _PathPainter(flip: flip)),
    );
  }
}

class _PathPainter extends CustomPainter {
  final bool flip;
  _PathPainter({required this.flip});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFB9AFFF)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final double x1 = flip ? size.width * 0.28 : size.width * 0.72;
    final double x2 = flip ? size.width * 0.72 : size.width * 0.28;
    const int dots = 7;
    for (int i = 0; i <= dots; i++) {
      final double t = i / dots;
      final double x = x1 + (x2 - x1) * t;
      final double y = size.height * t;
      canvas.drawCircle(Offset(x, y), 3.4, paint);
    }
  }

  @override
  bool shouldRepaint(_PathPainter oldDelegate) => oldDelegate.flip != flip;
}
