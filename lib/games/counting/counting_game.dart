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

class CountingGame extends StatefulWidget {
  const CountingGame({super.key});

  @override
  State<CountingGame> createState() => _CountingGameState();
}

class _CountingGameState extends State<CountingGame> {
  static const int _rounds = 12;
  static const List<String> _farm = <String>[
    '🍎', '🐥', '🐮', '🥕', '🌻', '🐷', '🥚', '🌽', '🐑', '🍓', '🐰', '🍐',
  ];

  final math.Random _rnd = math.Random();
  final Stopwatch _playTime = Stopwatch()..start();
  late List<int> _counts;
  late List<String> _roundEmoji;

  int _round = 0;
  int _mistakes = 0;
  final Set<int> _tapped = <int>{};
  bool _answerPhase = false;
  bool _celebrate = false;
  bool _wiggling = false;
  bool _done = false;
  BuddyMood _mood = BuddyMood.idle;
  List<int> _options = <int>[];

  bool get _isLittle => ProgressStore.instance.ageGroup != 'big';

  @override
  void initState() {
    super.initState();
    // 3 difficulty tiers x 4 rounds, tuned by age group.
    final List<List<int>> tiers = _isLittle
        ? const <List<int>>[<int>[3, 5], <int>[5, 8], <int>[8, 11]]
        : const <List<int>>[<int>[5, 9], <int>[9, 13], <int>[13, 21]];
    _counts = <int>[
      for (final List<int> tier in tiers)
        ...List<int>.generate(
            4, (int i) => tier[0] + _rnd.nextInt(tier[1] - tier[0])),
    ];
    _roundEmoji = List<String>.generate(
      _rounds,
      (int i) => _farm[_rnd.nextInt(_farm.length)],
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MediaService.say("Let's count! Tap each one.");
    });
  }

  @override
  void dispose() {
    _playTime.stop();
    ProgressStore.instance.addPlayTime('counting', _playTime.elapsed.inSeconds);
    super.dispose();
  }

  int get _target => _counts[_round];

  void _tapItem(int i) {
    if (_answerPhase || _tapped.contains(i) || _celebrate) return;
    setState(() => _tapped.add(i));
    HapticFeedback.selectionClick();
    MediaService.play('pop');
    MediaService.say(kNumberWords[_tapped.length]);
    if (_tapped.length == _target) {
      _options = <int>{_target, _target + 1, _target - 1, _target + 2}
          .where((int v) => v >= 1)
          .take(3)
          .toList()
        ..shuffle(_rnd);
      setState(() => _answerPhase = true);
      MediaService.play('sparkle');
      MediaService.say('How many did you count?');
    }
  }

  Future<void> _pick(int value) async {
    if (_celebrate) return;
    if (value == _target) {
      setState(() {
        _celebrate = true;
        _mood = BuddyMood.celebrate;
      });
      HapticFeedback.mediumImpact();
      MediaService.play('correct');
      MediaService.say(kPraise[_rnd.nextInt(kPraise.length)]);
      awardRoundRewards('counting', _round + 1, _rounds, _mistakes);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      if (_round + 1 >= _rounds) {
        setState(() => _done = true);
      } else {
        setState(() {
          _round++;
          _tapped.clear();
          _answerPhase = false;
          _celebrate = false;
          _mood = BuddyMood.idle;
        });
      }
    } else {
      _mistakes++;
      HapticFeedback.lightImpact();
      MediaService.play('wrong');
      MediaService.say(kTryAgain[_rnd.nextInt(kTryAgain.length)]);
      setState(() {
        _wiggling = true;
        _mood = BuddyMood.encourage;
      });
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() => _wiggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.bgGradient,
          ),
        ),
        child: SafeArea(
          child: _done
              ? GameCompleteView(
                  title: 'Counting Star!',
                  stickerEmoji: stickerEmoji('counting_3'),
                  stars: ProgressStore.instance.starsFor('counting'),
                )
              : Stack(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        GameHeader(
                          title: 'Counting',
                          total: _rounds,
                          done: _round,
                          mood: _mood,
                        ),
                        Text(
                          _answerPhase
                              ? 'How many did you count?'
                              : 'Tap each one and count!',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.softGrey,
                          ),
                        ),
                        Expanded(child: _buildItems()),
                        if (_answerPhase)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Wiggle(
                              active: _wiggling,
                              child:
                                  AnswerPad(options: _options, onPick: _pick),
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

  Widget _buildItems() {
    final int n = _target;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int cols = n > 10 ? 5 : 4;
        final double tileSize =
            (constraints.maxWidth / (cols + 0.8)).clamp(52.0, 104.0);
        return Center(
          child: SingleChildScrollView(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: List<Widget>.generate(n, (int i) {
                final bool counted = _tapped.contains(i);
                return PopIn(
                  delayMs: i * 70,
                  child: GestureDetector(
                    onTap: () => _tapItem(i),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: <Widget>[
                        AnimatedScale(
                          scale: counted ? 0.9 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: EmojiTile(
                            emoji: _roundEmoji[_round],
                            size: tileSize * 0.62,
                            dimmed: counted,
                          ),
                        ),
                        if (counted)
                          Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Color(0xFF43E97B),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
