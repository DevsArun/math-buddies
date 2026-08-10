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

class TracingGame extends StatefulWidget {
  const TracingGame({super.key});

  @override
  State<TracingGame> createState() => _TracingGameState();
}

class _TracingGameState extends State<TracingGame> {
  static const int _rounds = 10; // numbers 0..9
  static const List<Color> _strokeColors = <Color>[
    Color(0xFFFF6A88),
    Color(0xFF4CC9F0),
    Color(0xFF7C5CFF),
    Color(0xFF43E97B),
    Color(0xFFF76B1C),
  ];

  final Stopwatch _playTime = Stopwatch()..start();

  int _index = 0;
  int _mistakes = 0;
  final List<List<Offset>> _strokes = <List<Offset>>[];
  final List<List<Offset>> _redo = <List<Offset>>[];
  bool _celebrate = false;
  bool _done = false;
  bool _showHint = false;
  BuddyMood _mood = BuddyMood.idle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MediaService.say('Trace the number ${kNumberWords[_index]}');
    });
  }

  @override
  void dispose() {
    _playTime.stop();
    ProgressStore.instance.addPlayTime('tracing', _playTime.elapsed.inSeconds);
    super.dispose();
  }

  int get _pointCount =>
      _strokes.fold(0, (int a, List<Offset> s) => a + s.length);

  void _startStroke(Offset p) {
    MediaService.play('click');
    setState(() {
      _redo.clear();
      _strokes.add(<Offset>[p]);
    });
  }

  void _extendStroke(Offset p) {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.last.add(p));
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    HapticFeedback.lightImpact();
    MediaService.play('click');
    setState(() => _redo.add(_strokes.removeLast()));
  }

  void _redoStroke() {
    if (_redo.isEmpty) return;
    HapticFeedback.lightImpact();
    MediaService.play('click');
    setState(() => _strokes.add(_redo.removeLast()));
  }

  Future<void> _finish() async {
    if (_celebrate) return;
    if (_pointCount < 25) {
      _mistakes++;
      MediaService.play('wrong');
      MediaService.say('Trace the grey number first!');
      setState(() {
        _showHint = true;
        _mood = BuddyMood.encourage;
      });
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _showHint = false);
      return;
    }
    HapticFeedback.mediumImpact();
    MediaService.play('correct');
    MediaService.say('Beautiful ${kNumberWords[_index]}!');
    setState(() {
      _celebrate = true;
      _mood = BuddyMood.celebrate;
    });
    awardRoundRewards('tracing', _index + 1, _rounds, _mistakes);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    if (_index >= _rounds - 1) {
      setState(() => _done = true);
    } else {
      setState(() {
        _index++;
        _strokes.clear();
        _redo.clear();
        _celebrate = false;
        _mood = BuddyMood.idle;
      });
      MediaService.say('Trace the number ${kNumberWords[_index]}');
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
                  title: 'Number Writer!',
                  stickerEmoji: stickerEmoji('tracing_3'),
                  stars: ProgressStore.instance.starsFor('tracing'),
                )
              : Stack(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        GameHeader(
                          title: 'Trace Numbers',
                          total: _rounds,
                          done: _index,
                          mood: _mood,
                        ),
                        Text(
                          kNumberWords[_index].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: AppColors.softGrey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(child: _buildBoard()),
                        if (_showHint)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Trace the grey number first 🙂',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF76B1C),
                              ),
                            ),
                          ),
                        _toolbar(),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: GestureDetector(
            onPanStart: (DragStartDetails d) => _startStroke(d.localPosition),
            onPanUpdate: (DragUpdateDetails d) => _extendStroke(d.localPosition),
            child: CustomPaint(
              painter: _TracePainter(
                number: '$_index',
                strokes: _strokes,
                colors: _strokeColors,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }

  Widget _toolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          RoundIconButton(emoji: '↩️', onTap: _undo, size: 64),
          RoundIconButton(emoji: '↪️', onTap: _redoStroke, size: 64),
          RoundIconButton(
            emoji: '🧽',
            size: 64,
            onTap: () {
              HapticFeedback.lightImpact();
              MediaService.play('whoosh');
              setState(() {
                _strokes.clear();
                _redo.clear();
              });
            },
          ),
          RoundIconButton(emoji: '✅', onTap: _finish, size: 72),
        ],
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  final String number;
  final List<List<Offset>> strokes;
  final List<Color> colors;

  _TracePainter({
    required this.number,
    required this.strokes,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: number,
        style: TextStyle(
          fontSize: size.height * 0.72,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF3B3663).withValues(alpha: 0.14),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
    );

    for (int i = 0; i < strokes.length; i++) {
      final List<Offset> s = strokes[i];
      if (s.isEmpty) continue;
      final Paint paint = Paint()
        ..color = colors[i % colors.length]
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      if (s.length == 1) {
        canvas.drawCircle(s.first, 8, paint);
      } else {
        final Path path = Path()..moveTo(s.first.dx, s.first.dy);
        for (final Offset p in s.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_TracePainter oldDelegate) => true;
}
