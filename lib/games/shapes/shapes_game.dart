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

class ShapesGame extends StatefulWidget {
  const ShapesGame({super.key});

  @override
  State<ShapesGame> createState() => _ShapesGameState();
}

class _ShapesGameState extends State<ShapesGame> {
  static const List<String> _shapes = <String>[
    '🔵', '🟥', '🔺', '⭐', '❤️', '💠', '🌙', '🌸',
  ];
  static const List<String> _names = <String>[
    'circle', 'square', 'triangle', 'star', 'heart', 'diamond', 'moon', 'flower',
  ];
  static const int _rounds = 12;

  final math.Random _rnd = math.Random();
  final Stopwatch _playTime = Stopwatch()..start();
  late List<int> _targets;
  List<int> _candidates = <int>[];

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
    final List<int> idx = List<int>.generate(_shapes.length, (int i) => i)
      ..shuffle(_rnd);
    _targets = <int>[
      ...idx,
      ...List<int>.generate(_rounds - _shapes.length,
          (int i) => _rnd.nextInt(_shapes.length)),
    ];
    _newRound();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sayTarget());
  }

  @override
  void dispose() {
    _playTime.stop();
    ProgressStore.instance.addPlayTime('shapes', _playTime.elapsed.inSeconds);
    super.dispose();
  }

  int get _target => _targets[_round];

  void _sayTarget() {
    MediaService.say('Find the ${_names[_target]}!');
  }

  void _newRound() {
    final int candidateCount = _isLittle ? 4 : 6;
    final Set<int> cand = <int>{_target};
    while (cand.length < candidateCount) {
      cand.add(_rnd.nextInt(_shapes.length));
    }
    _candidates = cand.toList()..shuffle(_rnd);
  }

  Future<void> _attempt(int shapeIndex) async {
    if (_celebrate) return;
    if (shapeIndex == _target) {
      HapticFeedback.mediumImpact();
      MediaService.play('correct');
      MediaService.say(kPraise[_rnd.nextInt(kPraise.length)]);
      setState(() {
        _celebrate = true;
        _mood = BuddyMood.celebrate;
      });
      awardRoundRewards('shapes', _round + 1, _rounds, _mistakes);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      if (_round + 1 >= _rounds) {
        setState(() => _done = true);
      } else {
        setState(() {
          _round++;
          _celebrate = false;
          _mood = BuddyMood.idle;
          _newRound();
        });
        _sayTarget();
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
                  title: 'Shape Star!',
                  stickerEmoji: stickerEmoji('shapes_3'),
                  stars: ProgressStore.instance.starsFor('shapes'),
                )
              : Stack(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        GameHeader(
                          title: 'Shapes',
                          total: _rounds,
                          done: _round,
                          mood: _mood,
                        ),
                        Text(
                          'Find the ${_names[_target]}!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                        _buildTarget(),
                        Expanded(child: _buildCandidates()),
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

  Widget _buildTarget() {
    return DragTarget<int>(
      onWillAcceptWithDetails: (DragTargetDetails<int> d) => d.data == _target,
      onAcceptWithDetails: (DragTargetDetails<int> d) => _attempt(d.data),
      builder: (BuildContext context, List<int?> accepted, List<dynamic> rej) {
        return Container(
          width: 140,
          height: 140,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _celebrate
                  ? const Color(0xFF43E97B)
                  : const Color(0xFFDDD6FE),
              width: 4,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Opacity(
              opacity: _celebrate ? 1 : 0.30,
              child: Text(
                _shapes[_target],
                style: const TextStyle(fontSize: 78),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCandidates() {
    return Center(
      child: SingleChildScrollView(
        child: Wiggle(
          active: _wiggling,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: _candidates.map((int shapeIndex) {
              final Widget tile = EmojiTile(
                emoji: _shapes[shapeIndex],
                size: 58,
                onTap: () => _attempt(shapeIndex),
              );
              return Draggable<int>(
                data: shapeIndex,
                feedback: Material(
                  color: Colors.transparent,
                  child: EmojiTile(emoji: _shapes[shapeIndex], size: 72),
                ),
                childWhenDragging: Opacity(opacity: 0.3, child: tile),
                child: tile,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
