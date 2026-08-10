import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Buddy the rocket — the app's mascot. Pure CustomPainter, zero assets.
enum BuddyMood { idle, happy, celebrate, encourage }

class Buddy extends StatefulWidget {
  final BuddyMood mood;
  final double size;
  final Color accent;

  const Buddy({
    super.key,
    this.mood = BuddyMood.idle,
    this.size = 96,
    this.accent = const Color(0xFF5B54E8),
  });

  @override
  State<Buddy> createState() => _BuddyState();
}

class _BuddyState extends State<Buddy> with TickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  )..repeat();

  late final AnimationController _party = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didUpdateWidget(Buddy oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mood == BuddyMood.celebrate &&
        oldWidget.mood != BuddyMood.celebrate) {
      _party.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    _blink.dispose();
    _party.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_bob, _blink, _party]),
      builder: (BuildContext context, Widget? child) {
        final double bobY = math.sin(_bob.value * 2 * math.pi) * 5;
        final bool eyesClosed = _blink.value > 0.93;
        final double wobble =
            _party.isAnimating ? math.sin(_party.value * math.pi * 3) * 0.18 : 0;
        final double pop =
            _party.isAnimating ? 1 + math.sin(_party.value * math.pi) * 0.12 : 1;
        return Transform.translate(
          offset: Offset(0, bobY),
          child: Transform.rotate(
            angle: wobble,
            child: Transform.scale(
              scale: pop,
              child: CustomPaint(
                size: Size.square(widget.size),
                painter: _BuddyPainter(
                  mood: widget.mood,
                  eyesClosed: eyesClosed,
                  t: _bob.value,
                  party: _party.value,
                  accent: widget.accent,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BuddyPainter extends CustomPainter {
  final BuddyMood mood;
  final bool eyesClosed;
  final double t; // 0..1 bob cycle (flame flicker)
  final double party; // 0..1 celebration progress
  final Color accent;

  static const Color yellow = Color(0xFFFFC53D);
  static const Color pink = Color(0xFFFF6A88);

  _BuddyPainter({
    required this.mood,
    required this.eyesClosed,
    required this.t,
    required this.party,
    this.accent = const Color(0xFF5B54E8),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 100; // logical 100x100 box
    canvas.save();
    canvas.scale(s);

    final Paint white = Paint()..color = Colors.white;
    final Paint outline = Paint()
      ..color = const Color(0xFFE6E0F8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // --- flame (flickers) ---
    final double flameLen = 16 + math.sin(t * 4 * math.pi) * 4;
    final Path flame = Path()
      ..moveTo(43, 78)
      ..lineTo(57, 78)
      ..lineTo(50, 78 + flameLen)
      ..close();
    canvas.drawPath(flame, Paint()..color = pink);
    final Path flameInner = Path()
      ..moveTo(46.5, 78)
      ..lineTo(53.5, 78)
      ..lineTo(50, 78 + flameLen * 0.55)
      ..close();
    canvas.drawPath(flameInner, Paint()..color = yellow);

    // --- fins ---
    final Paint finPaint = Paint()..color = yellow;
    canvas.drawPath(
      Path()
        ..moveTo(35, 58)
        ..lineTo(20, 78)
        ..lineTo(35, 72)
        ..close(),
      finPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(65, 58)
        ..lineTo(80, 78)
        ..lineTo(65, 72)
        ..close(),
      finPaint,
    );

    // --- body ---
    final RRect body = RRect.fromRectAndCorners(
      const Rect.fromLTRB(32, 10, 68, 80),
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: const Radius.circular(8),
      bottomRight: const Radius.circular(8),
    );
    canvas.drawRRect(body, white);
    canvas.drawRRect(body, outline);

    // --- window with face ---
    final Offset winCenter = const Offset(50, 42);
    canvas.drawCircle(winCenter, 15, Paint()..color = accent);
    canvas.drawCircle(
        winCenter, 11.5, Paint()..color = accent.withValues(alpha: 0.55));

    final Paint facePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final Paint eyeFill = Paint()..color = Colors.white;

    // eyes
    if (eyesClosed) {
      canvas.drawArc(const Rect.fromLTRB(42, 36, 48, 41), 0.2, math.pi - 0.4,
          false, facePaint);
      canvas.drawArc(const Rect.fromLTRB(52, 36, 58, 41), 0.2, math.pi - 0.4,
          false, facePaint);
    } else {
      canvas.drawCircle(const Offset(45, 38.5), 2.4, eyeFill);
      canvas.drawCircle(const Offset(55, 38.5), 2.4, eyeFill);
    }
    // mouth
    if (mood == BuddyMood.encourage) {
      canvas.drawCircle(const Offset(50, 48), 2.6, eyeFill);
    } else {
      final double smileW = mood == BuddyMood.idle ? 5 : 8;
      canvas.drawArc(
        Rect.fromCenter(center: const Offset(50, 46), width: smileW * 2, height: 10),
        0.3,
        math.pi - 0.6,
        false,
        facePaint,
      );
    }
    // rosy cheeks
    final Paint cheek = Paint()..color = pink.withValues(alpha: 0.55);
    canvas.drawCircle(const Offset(40.5, 45), 2.4, cheek);
    canvas.drawCircle(const Offset(59.5, 45), 2.4, cheek);

    // --- celebration stars ---
    if (mood == BuddyMood.celebrate && party > 0) {
      final Paint starPaint = Paint()
        ..color = yellow.withValues(alpha: (1 - party).clamp(0.0, 1.0));
      for (int i = 0; i < 4; i++) {
        final double ang = -math.pi / 2 + i * (math.pi / 2);
        final double dist = 34 + party * 16;
        final Offset c =
            const Offset(50, 42) + Offset(math.cos(ang) * dist, math.sin(ang) * dist);
        _drawStar(canvas, c, 5.5, starPaint);
      }
    }

    canvas.restore();
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint paint) {
    final Path path = Path();
    for (int i = 0; i < 10; i++) {
      final double ang = -math.pi / 2 + i * math.pi / 5;
      final double rr = i.isEven ? r : r * 0.45;
      final Offset p = c + Offset(rr * math.cos(ang), rr * math.sin(ang));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BuddyPainter oldDelegate) => true;
}
