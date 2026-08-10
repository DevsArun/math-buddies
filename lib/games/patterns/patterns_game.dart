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

class _PatternRound {
  final List<String> shown; // first 5 cells
  final String answer;
  final List<String> options;
  const _PatternRound(this.shown, this.answer, this.options);
}

class PatternsGame extends StatefulWidget {
  const PatternsGame({super.key});

  @override
  State<PatternsGame> createState() => _PatternsGameState();
}

class _PatternsGameState extends State<PatternsGame> {
  static const int _rounds = 12;

  static const List<List<String>> _sets2 = <List<String>>[
    <String>['🦁', '🐵'],
    <String>['🦜', '🐸'],
    <String>['🍍', '🍌'],
    <String>['🌺', '🌼'],
    <String>['🐯', '🦓'],
    <String>['🦋', '🐛'],
    <String>['🥥', '🥝'],
    <String>['🐘', '🦛'],
  ];
  static const List<List<String>> _sets3 = <List<String>>[
    <String>['🔴', '🔵', '🟡'],
    <String>['🦁', '🐵', '🦜'],
    <String>['🍍', '🍌', '🍇'],
    <String>['🌺', '🌼', '🌻'],
  ];
  // All codes MUST be exactly 6 chars (5 shown + 1 answer) - shorter codes
  // crash _build with a RangeError (the v1.1.3 "Patterns won't load" bug).
  static const List<String> _codes2 = <String>[
    'ABABAB', 'AABBAA', 'ABBAAB', 'ABBBAB', 'AAABAA',
  ];
  static const List<String> _codes3Easy = <String>[
    'ABCABC', 'AABBCC',
  ];
  static const List<String> _codes3Hard = <String>[
    'ABCABC', 'AABBCC', 'ABCCBA', 'ABCBAC',
  ];

  final math.Random _rnd = math.Random();
  final Stopwatch _playTime = Stopwatch()..start();
  late List<_PatternRound> _roundsData;

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
    _roundsData = List<_PatternRound>.generate(_rounds, (int i) {
      // Little explorers get 3-symbol patterns only in the last tier.
      final bool three =
          _isLittle ? i >= _rounds - 4 : i % 2 == 1;
      if (three) {
        final List<String> set = _sets3[_rnd.nextInt(_sets3.length)];
        final List<String> codes = _isLittle ? _codes3Easy : _codes3Hard;
        return _build(codes[_rnd.nextInt(codes.length)], set);
      }
      final List<String> set = _sets2[_rnd.nextInt(_sets2.length)];
      return _build(_codes2[_rnd.nextInt(_codes2.length)], set);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MediaService.say('What comes next?');
    });
  }

  @override
  void dispose() {
    _playTime.stop();
    ProgressStore.instance.addPlayTime('patterns', _playTime.elapsed.inSeconds);
    super.dispose();
  }

  _PatternRound _build(String code, List<String> set) {
    String sym(String letter) {
      final int idx = letter.codeUnitAt(0) - 'A'.codeUnitAt(0);
      return set[idx % set.length];
    }

    final List<String> full = code.split('').map(sym).toList();
    final List<String> shown = full.take(5).toList();
    final String answer = full[5];

    final Set<String> opts = <String>{answer};
    final List<String> extras = <String>[
      ...set,
      '🐠', '🎈', '🧡', '🐥', '🍪', '🐢',
    ]..shuffle(_rnd);
    for (final String e in extras) {
      if (opts.length >= 3) break;
      if (e != answer) opts.add(e);
    }
    final List<String> options = opts.toList()..shuffle(_rnd);
    return _PatternRound(shown, answer, options);
  }

  Future<void> _pick(String emoji) async {
    if (_celebrate) return;
    if (emoji == _roundsData[_round].answer) {
      HapticFeedback.mediumImpact();
      MediaService.play('correct');
      MediaService.say(kPraise[_rnd.nextInt(kPraise.length)]);
      setState(() {
        _celebrate = true;
        _mood = BuddyMood.celebrate;
      });
      awardRoundRewards('patterns', _round + 1, _rounds, _mistakes);
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
        MediaService.say('What comes next?');
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
    final _PatternRound r = _roundsData[_round];
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
                  title: 'Pattern Pro!',
                  stickerEmoji: stickerEmoji('patterns_3'),
                  stars: ProgressStore.instance.starsFor('patterns'),
                )
              : Stack(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        GameHeader(
                          title: 'Patterns',
                          total: _rounds,
                          done: _round,
                          mood: _mood,
                        ),
                        const Text(
                          'What comes next?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.softGrey,
                          ),
                        ),
                        Expanded(child: _buildSequence(r)),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 28),
                          child: Wiggle(
                            active: _wiggling,
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 18,
                              children: r.options
                                  .map(
                                    (String e) => EmojiTile(
                                      emoji: e,
                                      size: 62,
                                      onTap: () => _pick(e),
                                    ),
                                  )
                                  .toList(),
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

  Widget _buildSequence(_PatternRound r) {
    final List<Widget> cells = <Widget>[];
    for (int i = 0; i < r.shown.length; i++) {
      cells.add(
        PopIn(delayMs: i * 120, child: EmojiTile(emoji: r.shown[i], size: 54)),
      );
    }
    cells.add(
      Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F0FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDDD6FE), width: 3),
        ),
        child: Center(
          child: _celebrate
              ? Text(r.answer, style: const TextStyle(fontSize: 40))
              : const Text('❓', style: TextStyle(fontSize: 34)),
        ),
      ),
    );
    return Center(
      child: SingleChildScrollView(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: cells,
        ),
      ),
    );
  }
}
