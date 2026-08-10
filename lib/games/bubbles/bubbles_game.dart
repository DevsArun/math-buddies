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

/// Bubble Pop: pop the number bubbles in order 1 -> 2 -> 3 ...
class BubblesGame extends StatefulWidget {
  const BubblesGame({super.key});

  @override
  State<BubblesGame> createState() => _BubblesGameState();
}

class _BubblesGameState extends State<BubblesGame> {
  static const int _rounds = 10;
  static const int _cells = 12; // fixed 4x3 grid, numbers placed randomly

  final math.Random _rnd = math.Random();
  final Stopwatch _playTime = Stopwatch()..start();
  late List<int> _counts;
  late List<List<int>> _boards; // per round: number at each cell (0 = empty)

  int _round = 0;
  int _next = 1;
  int _mistakes = 0;
  final Set<int> _poppedCells = <int>{};
  bool _celebrate = false;
  bool _wiggling = false;
  bool _done = false;
  BuddyMood _mood = BuddyMood.idle;

  bool get _isLittle => ProgressStore.instance.ageGroup != 'big';

  @override
  void initState() {
    super.initState();
    _counts = List<int>.generate(_rounds, (int i) {
      final int tier = i ~/ 4; // 0,1,2
      return _isLittle
          ? 4 + tier + _rnd.nextInt(2) // 4..7
          : 6 + tier * 2 + _rnd.nextInt(2); // 6..11
    });
    _boards = _counts.map((int n) {
      final List<int> cells = List<int>.filled(_cells, 0);
      final List<int> pos = List<int>.generate(_cells, (int i) => i)
        ..shuffle(_rnd);
      for (int v = 1; v <= n; v++) {
        cells[pos[v - 1]] = v;
      }
      return cells;
    }).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MediaService.say('Pop the bubbles! Start at one!');
    });
  }

  @override
  void dispose() {
    _playTime.stop();
    ProgressStore.instance.addPlayTime('bubbles', _playTime.elapsed.inSeconds);
    super.dispose();
  }

  Future<void> _tapCell(int cell) async {
    if (_celebrate) return;
    final int value = _boards[_round][cell];
    if (value == 0 || _poppedCells.contains(cell)) return;
    if (value == _next) {
      HapticFeedback.selectionClick();
      MediaService.play('pop');
      MediaService.say(kNumberWords[value]);
      setState(() {
        _poppedCells.add(cell);
        _next++;
      });
      if (_next > _counts[_round]) {
        setState(() {
          _celebrate = true;
          _mood = BuddyMood.celebrate;
        });
        MediaService.play('correct');
        MediaService.say(kPraise[_rnd.nextInt(kPraise.length)]);
        awardRoundRewards('bubbles', _round + 1, _rounds, _mistakes);
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;
        if (_round + 1 >= _rounds) {
          setState(() => _done = true);
        } else {
          setState(() {
            _round++;
            _next = 1;
            _poppedCells.clear();
            _celebrate = false;
            _mood = BuddyMood.idle;
          });
        }
      }
    } else {
      _mistakes++;
      HapticFeedback.lightImpact();
      MediaService.play('wrong');
      MediaService.say('Find ${kNumberWords[_next]}!');
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
            colors: <Color>[Color(0xFFEAF9FF), Color(0xFFFFF6E9)],
          ),
        ),
        child: SafeArea(
          child: _done
              ? GameCompleteView(
                  title: 'Bubble Master!',
                  stickerEmoji: stickerEmoji('bubbles_3'),
                  stars: ProgressStore.instance.starsFor('bubbles'),
                )
              : Stack(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        GameHeader(
                          title: 'Bubble Pop',
                          total: _rounds,
                          done: _round,
                          mood: _mood,
                        ),
                        Text(
                          'Pop from 1 to ${_counts[_round]}! Next: $_next',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.softGrey,
                          ),
                        ),
                        Expanded(child: _buildBoard()),
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

  Widget _buildBoard() {
    return Center(
      child: Wiggle(
        active: _wiggling,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 14,
          children: List<Widget>.generate(_cells, (int cell) {
            final int value = _boards[_round][cell];
            if (value == 0) {
              return const SizedBox(width: 96, height: 96);
            }
            final bool popped = _poppedCells.contains(cell);
            return PopIn(
              delayMs: cell * 50,
              child: GestureDetector(
                onTap: () => _tapCell(cell),
                child: AnimatedScale(
                  scale: popped ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInBack,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        center: Alignment(-0.4, -0.5),
                        radius: 1.1,
                        colors: <Color>[Color(0xFFBDEFFF), Color(0xFF66A6FF)],
                      ),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: const Color(0xFF66A6FF).withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$value',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
