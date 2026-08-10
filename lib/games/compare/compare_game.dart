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

class _CompareRound {
  final String mode; // 'big', 'small', 'more', 'less'
  final String emoji;
  final List<double> sizes; // for big/small
  final int correctIndex; // for big/small
  final List<int> groups; // for more/less (2 groups)
  final int correctGroup; // for more/less

  const _CompareRound.size(this.mode, this.emoji, this.sizes, this.correctIndex)
      : groups = const <int>[],
        correctGroup = -1;

  const _CompareRound.group(this.mode, this.emoji, this.groups, this.correctGroup)
      : sizes = const <double>[],
        correctIndex = -1;
}

class CompareGame extends StatefulWidget {
  const CompareGame({super.key});

  @override
  State<CompareGame> createState() => _CompareGameState();
}

class _CompareGameState extends State<CompareGame> {
  static const int _rounds = 12;
  static const List<String> _modes = <String>[
    'big', 'more', 'small', 'less', 'more', 'big', 'less', 'small',
    'big', 'less', 'more', 'small',
  ];
  static const List<String> _dino = <String>[
    '🦕', '🐘', '🦒', '🐋', '🦖', '🐢', '🦁', '🐊', '🦛', '🐪',
  ];

  final math.Random _rnd = math.Random();
  final Stopwatch _playTime = Stopwatch()..start();
  late List<_CompareRound> _roundsData;

  int _round = 0;
  int _mistakes = 0;
  bool _celebrate = false;
  bool _wiggling = false;
  bool _done = false;
  BuddyMood _mood = BuddyMood.idle;

  bool get _isLittle => ProgressStore.instance.ageGroup != 'big';

  @override
  void initState() {
    super.initState();
    _roundsData = List<_CompareRound>.generate(_rounds, (int i) {
      final String mode = _modes[i];
      final String emoji = _dino[_rnd.nextInt(_dino.length)];
      if (mode == 'big' || mode == 'small') {
        // Big explorers get closer sizes (harder to tell apart).
        final List<double> base = _isLittle
            ? <double>[34, 58, 84]
            : <double>[40, 56, 72];
        final List<double> sizes = List<double>.of(base)..shuffle(_rnd);
        final double target = mode == 'big' ? base[2] : base[0];
        final int correct = sizes.indexOf(target);
        return _CompareRound.size(mode, emoji, sizes, correct);
      }
      final int maxC = _isLittle ? 7 : 9;
      final int minDiff = _isLittle ? 2 : 1;
      final int a = 2 + _rnd.nextInt(maxC - 1);
      int b = 2 + _rnd.nextInt(maxC - 1);
      while ((a - b).abs() < minDiff) {
        b = 2 + _rnd.nextInt(maxC - 1);
      }
      final List<int> groups = <int>[a, b]..shuffle(_rnd);
      final int correctGroup = mode == 'more'
          ? (groups[0] > groups[1] ? 0 : 1)
          : (groups[0] < groups[1] ? 0 : 1);
      return _CompareRound.group(mode, emoji, groups, correctGroup);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _sayPrompt());
  }

  @override
  void dispose() {
    _playTime.stop();
    ProgressStore.instance.addPlayTime('compare', _playTime.elapsed.inSeconds);
    super.dispose();
  }

  String get _prompt {
    switch (_roundsData[_round].mode) {
      case 'big':
        return 'Tap the BIGGEST!';
      case 'small':
        return 'Tap the SMALLEST!';
      case 'more':
        return 'Which has MORE?';
      default:
        return 'Which has FEWER?';
    }
  }

  void _sayPrompt() {
    MediaService.say(switch (_roundsData[_round].mode) {
      'big' => 'Tap the biggest!',
      'small' => 'Tap the smallest!',
      'more' => 'Which has more?',
      _ => 'Which has fewer?',
    });
  }

  Future<void> _attempt(bool correct) async {
    if (_celebrate) return;
    if (correct) {
      HapticFeedback.mediumImpact();
      MediaService.play('correct');
      MediaService.say(kPraise[_rnd.nextInt(kPraise.length)]);
      setState(() {
        _celebrate = true;
        _mood = BuddyMood.celebrate;
      });
      awardRoundRewards('compare', _round + 1, _rounds, _mistakes);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      if (_round + 1 >= _rounds) {
        setState(() => _done = true);
      } else {
        setState(() {
          _round++;
          _celebrate = false;
          _mood = BuddyMood.idle;
        });
        _sayPrompt();
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
    final _CompareRound r = _roundsData[_round];
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
                  title: 'Super Comparer!',
                  stickerEmoji: stickerEmoji('compare_3'),
                  stars: ProgressStore.instance.starsFor('compare'),
                )
              : Stack(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        GameHeader(
                          title: 'Big & Small',
                          total: _rounds,
                          done: _round,
                          mood: _mood,
                        ),
                        Text(
                          _prompt,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                        Expanded(
                          child: Wiggle(
                            active: _wiggling,
                            child: r.sizes.isNotEmpty
                                ? _buildSizes(r)
                                : _buildGroups(r),
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

  Widget _buildSizes(_CompareRound r) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 26,
        runSpacing: 20,
        children: List<Widget>.generate(r.sizes.length, (int i) {
          return Pressable(
            onTap: () => _attempt(i == r.correctIndex),
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: PopIn(
                  delayMs: i * 120,
                  child: Text(r.emoji, style: TextStyle(fontSize: r.sizes[i])),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGroups(_CompareRound r) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 22,
        runSpacing: 20,
        children: List<Widget>.generate(2, (int g) {
          return Pressable(
            onTap: () => _attempt(g == r.correctGroup),
            child: Container(
              width: 170,
              constraints: const BoxConstraints(minHeight: 170),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFFE6E0F8), width: 3),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: List<Widget>.generate(
                  r.groups[g],
                  (int i) => PopIn(
                    delayMs: i * 70,
                    child: Text(r.emoji, style: const TextStyle(fontSize: 34)),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
