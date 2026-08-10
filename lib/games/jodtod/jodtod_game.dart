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

class _Round {
  final int a;
  final int b;
  final String op; // '+' or '-'
  final String emoji;
  const _Round(this.a, this.b, this.op, this.emoji);

  int get answer => op == '+' ? a + b : a - b;
}

class JodTodGame extends StatefulWidget {
  const JodTodGame({super.key});

  @override
  State<JodTodGame> createState() => _JodTodGameState();
}

class _JodTodGameState extends State<JodTodGame> {
  static const int _rounds = 12;
  static const List<String> _ocean = <String>[
    '🐠', '🐟', '🐙', '🦀', '🐚', '⭐', '🐬', '🦐', '🪼', '🐳',
  ];

  final math.Random _rnd = math.Random();
  final Stopwatch _playTime = Stopwatch()..start();
  late List<_Round> _roundsData;

  int _round = 0;
  int _mistakes = 0;
  List<int> _options = <int>[];
  bool _celebrate = false;
  bool _wiggling = false;
  bool _done = false;
  BuddyMood _mood = BuddyMood.idle;

  bool get _isLittle => ProgressStore.instance.ageGroup != 'big';

  @override
  void initState() {
    super.initState();
    _roundsData = List<_Round>.generate(_rounds, (int i) {
      final String op = i % 3 == 2 ? '-' : '+';
      final String emoji = _ocean[_rnd.nextInt(_ocean.length)];
      if (op == '+') {
        if (_isLittle) {
          final int a = 1 + _rnd.nextInt(4);
          final int b = 1 + _rnd.nextInt(3);
          return _Round(a, b, op, emoji);
        }
        final int a = 2 + _rnd.nextInt(8);
        final int b = (2 + _rnd.nextInt(8)).clamp(2, 18 - a);
        return _Round(a, b, op, emoji);
      }
      if (_isLittle) {
        final int a = 3 + _rnd.nextInt(6);
        final int b = 1 + _rnd.nextInt(a - 1);
        return _Round(a, b, op, emoji);
      }
      final int a = 5 + _rnd.nextInt(11);
      final int b = 1 + _rnd.nextInt(a - 1);
      return _Round(a, b, op, emoji);
    });
    _newOptions();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sayRound());
  }

  @override
  void dispose() {
    _playTime.stop();
    ProgressStore.instance.addPlayTime('jodtod', _playTime.elapsed.inSeconds);
    super.dispose();
  }

  _Round get _current => _roundsData[_round];

  void _sayRound() {
    final _Round r = _current;
    MediaService.say(
      '${kNumberWords[r.a]} ${r.op == '+' ? 'plus' : 'minus'} '
      '${kNumberWords[r.b]}?',
    );
  }

  void _newOptions() {
    final int ans = _current.answer;
    final Set<int> opts = <int>{ans};
    int delta = 1;
    while (opts.length < 3) {
      final int low = ans - delta;
      final int high = ans + delta;
      if (low >= 0) opts.add(low);
      if (opts.length < 3 && high <= 20) opts.add(high);
      delta++;
    }
    _options = opts.toList()..shuffle(_rnd);
  }

  Future<void> _pick(int value) async {
    if (_celebrate) return;
    if (value == _current.answer) {
      HapticFeedback.mediumImpact();
      MediaService.play('correct');
      MediaService.say(kPraise[_rnd.nextInt(kPraise.length)]);
      setState(() {
        _celebrate = true;
        _mood = BuddyMood.celebrate;
      });
      awardRoundRewards('jodtod', _round + 1, _rounds, _mistakes);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      if (_round + 1 >= _rounds) {
        setState(() => _done = true);
      } else {
        setState(() {
          _round++;
          _celebrate = false;
          _mood = BuddyMood.idle;
          _newOptions();
        });
        _sayRound();
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
                  title: 'Math Whiz!',
                  stickerEmoji: stickerEmoji('jodtod_3'),
                  stars: ProgressStore.instance.starsFor('jodtod'),
                )
              : Stack(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        GameHeader(
                          title: 'Add & Take Away',
                          total: _rounds,
                          done: _round,
                          mood: _mood,
                        ),
                        Text(
                          _current.op == '+'
                              ? 'Put them together!'
                              : 'Take some away!',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.softGrey,
                          ),
                        ),
                        Expanded(child: _buildEquation()),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Wiggle(
                            active: _wiggling,
                            child: AnswerPad(options: _options, onPick: _pick),
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

  Widget _group(int count, {bool dimmed = false}) {
    return Container(
      constraints: const BoxConstraints(minWidth: 110, maxWidth: 170),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
        spacing: 4,
        runSpacing: 4,
        children: List<Widget>.generate(
          count,
          (int i) => PopIn(
            delayMs: i * 60,
            child: Opacity(
              opacity: dimmed ? 0.35 : 1,
              child: Text(_current.emoji, style: const TextStyle(fontSize: 30)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEquation() {
    final _Round r = _current;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: <Widget>[
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _group(r.a),
                Text(
                  r.op == '+' ? '➕' : '➖',
                  style: const TextStyle(fontSize: 40),
                ),
                _group(r.b, dimmed: r.op == '-'),
                const Text('＝', style: TextStyle(fontSize: 40)),
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0FF),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFDDD6FE),
                      width: 3,
                    ),
                  ),
                  child: const Center(
                    child: Text('❓', style: TextStyle(fontSize: 42)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${r.a} ${r.op} ${r.b} = ?',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
