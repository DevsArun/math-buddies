import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Slowly shifting pastel background — the "next level" studio feel.
class AnimatedGradientBg extends StatefulWidget {
  final Widget child;

  const AnimatedGradientBg({super.key, required this.child});

  @override
  State<AnimatedGradientBg> createState() => _AnimatedGradientBgState();
}

class _AnimatedGradientBgState extends State<AnimatedGradientBg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat(reverse: true);

  static const List<Color> _a = <Color>[Color(0xFFFFF6E9), Color(0xFFEAF3FF)];
  static const List<Color> _b = <Color>[Color(0xFFFFE9F3), Color(0xFFE6FAF3)];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        final double t = Curves.easeInOut.transform(_c.value);
        final Color top = Color.lerp(_a[0], _b[0], t) ?? _a[0];
        final Color bottom = Color.lerp(_a[1], _b[1], t) ?? _a[1];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[top, bottom],
            ),
          ),
          child: child,
        );
      },
    );
  }
}

/// Gentle confetti burst overlay (no assets, no plugins).
class ConfettiBurst extends StatefulWidget {
  final int count;

  const ConfettiBurst({super.key, this.count = 26});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  late final List<_Particle> _parts = <_Particle>[];

  @override
  void initState() {
    super.initState();
    final math.Random rnd = math.Random(7);
    const List<Color> colors = <Color>[
      Color(0xFFFF6A88),
      Color(0xFFFFC53D),
      Color(0xFF4CC9F0),
      Color(0xFF7C5CFF),
      Color(0xFF43E97B),
    ];
    for (int i = 0; i < widget.count; i++) {
      _parts.add(_Particle(
        angle: rnd.nextDouble() * 2 * math.pi,
        speed: 120 + rnd.nextDouble() * 180,
        size: 8 + rnd.nextDouble() * 10,
        color: colors[rnd.nextInt(colors.length)],
        spin: rnd.nextDouble() * 4,
      ));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, Widget? child) {
          return CustomPaint(
            painter: _ConfettiPainter(_parts, _c.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;
  final double spin;
  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.spin,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> parts;
  final double t;
  _ConfettiPainter(this.parts, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset origin = Offset(size.width / 2, size.height * 0.35);
    for (final _Particle p in parts) {
      final double dist = p.speed * t;
      final Offset pos = origin +
          Offset(math.cos(p.angle) * dist, math.sin(p.angle) * dist + 220 * t * t);
      final Paint paint = Paint()
        ..color = p.color.withValues(alpha: (1 - t).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * t);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.t != t;
}

/// Small floating stars that drift up behind content.
class FloatingStars extends StatefulWidget {
  const FloatingStars({super.key});

  @override
  State<FloatingStars> createState() => _FloatingStarsState();
}

class _FloatingStarsState extends State<FloatingStars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, Widget? child) {
          return CustomPaint(painter: _StarsPainter(_c.value), size: Size.infinite);
        },
      ),
    );
  }
}

class _StarsPainter extends CustomPainter {
  final double t;
  _StarsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final math.Random rnd = math.Random(42);
    final Paint paint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    for (int i = 0; i < 18; i++) {
      final double x = rnd.nextDouble() * size.width;
      final double speed = 20 + rnd.nextDouble() * 30;
      final double y =
          (size.height + 40) - ((t * speed * 6 + rnd.nextDouble() * size.height) % (size.height + 80));
      final double r = 2 + rnd.nextDouble() * 3;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_StarsPainter oldDelegate) => oldDelegate.t != t;
}
