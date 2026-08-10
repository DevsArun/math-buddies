import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/media.dart';
import '../../data/progress_store.dart';
import '../../ui/buddy.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/complete_view.dart';
import '../../ui/widgets/effects.dart';
import '../../ui/widgets/game_widgets.dart';
import '../rewards.dart';

/// Memory Match: flip cards and find the matching emoji pairs.
class MemoryGame extends StatefulWidget {
  const MemoryGame({super.key});

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> {
  static const int _rounds = 6;
  static const List<String> _pool = <String>[
    '🦊', '🐼', '🐸', '🦁', '🐵', '🦄', '🐢', '🦉', '🐝', '🦋', '🐳', '🍄',
  ];

  final math.Random _rnd = math.Random();
  final Stopwatch _playTime = Stopwatch()..start();
  late List<List<String>> _boards; // per round: shuffled card emojis

  int _round = 0;
  int _mistakes = 0;
  final List<int> _up = <int>[];
  final Set<int> _matched = <int>{};
  bool _lock = false;
  bool _celebrate = false;
  bool _done = false;
  BuddyMood _mood = BuddyMood.idle;

  bool get _isLittle => ProgressStore.instance.ageGroup != 'big';
  int get _pairs => _isLittle ? 3 : 6;

  @override
  void initState() {
    super.initState();
    _boards = List<List<String>>.generate(_rounds, (int i) {
      final List<String> picked = List<String>.of(_pool)..shuffle(_rnd);
      final List<String> cards = <String>[
        ...picked.take(_pairs),
        ...picked.take(_pairs),
      ]..shuffle(_rnd);
      return cards;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MediaService.say('Find the matching pairs!');
    });
  }

  @override
  void dispose() {
    _playTime.stop();
    ProgressStore.instance.addPlayTime('memory', _playTime.elapsed.inSeconds);
    super.dispose();
  }

  Future<void> _tapCard(int index) async {
    if (_lock || _celebrate || _matched.contains(index) || _up.contains(index)) {
      return;
    }
    HapticFeedback.selectionClick();
    MediaService.play('flip');
    setState(() => _up.add(index));
    if (_up.length < 2) return;

    final int first = _up[0];
    final int second = _up[1];
    final bool match = _boards[_round][first] == _boards[_round][second];
    if (match) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      MediaService.play('sparkle');
      setState(() {
        _matched.add(first);
        _matched.add(second);
        _up.clear();
      });
      if (_matched.length == _boards[_round].length) {
        setState(() {
          _celebrate = true;
          _mood = BuddyMood.celebrate;
        });
        MediaService.play('correct');
        MediaService.say(kPraise[_rnd.nextInt(kPraise.length)]);
        awardRoundRewards('memory', _round + 1, _rounds, _mistakes);
        await Future<void>.delayed(const Duration(milliseconds: 1300));
        if (!mounted) return;
        if (_round + 1 >= _rounds) {
          setState(() => _done = true);
        } else {
          setState(() {
            _round++;
            _matched.clear();
            _up.clear();
            _celebrate = false;
            _mood = BuddyMood.idle;
          });
        }
      }
    } else {
      _lock = true;
      _mistakes++;
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      MediaService.play('wrong');
      setState(() {
        _up.clear();
        _lock = false;
        _mood = BuddyMood.encourage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> cards = _boards[_round];
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFFFF0F6), Color(0xFFEAF3FF)],
          ),
        ),
        child: SafeArea(
          child: _done
              ? GameCompleteView(
                  title: 'Memory Master!',
                  stickerEmoji: stickerEmoji('memory_3'),
                  stars: ProgressStore.instance.starsFor('memory'),
                )
              : Stack(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        GameHeader(
                          title: 'Memory Match',
                          total: _rounds,
                          done: _round,
                          mood: _mood,
                        ),
                        const Text(
                          'Find the matching pairs!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.softGrey,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _isLittle ? 3 : 4,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                              itemCount: cards.length,
                              itemBuilder: (BuildContext context, int i) {
                                final bool faceUp =
                                    _up.contains(i) || _matched.contains(i);
                                return _MemoryCard(
                                  emoji: cards[i],
                                  faceUp: faceUp,
                                  matched: _matched.contains(i),
                                  delayMs: i * 60,
                                  onTap: () => _tapCard(i),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_celebrate)
                      const Positioned.fill(child: ConfettiBurst()),
                  ],
                ),
        ),
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final String emoji;
  final bool faceUp;
  final bool matched;
  final int delayMs;
  final VoidCallback onTap;

  const _MemoryCard({
    required this.emoji,
    required this.faceUp,
    required this.matched,
    required this.delayMs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PopIn(
      delayMs: delayMs,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: matched ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 250),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              gradient: faceUp
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFFF093FB), Color(0xFFF5576C)],
                    ),
              color: faceUp ? Colors.white : null,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: matched
                    ? const Color(0xFF43E97B)
                    : (faceUp
                        ? const Color(0xFFDDD6FE)
                        : Colors.transparent),
                width: 3,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                faceUp ? emoji : '✨',
                style: TextStyle(fontSize: faceUp ? 46 : 34),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
