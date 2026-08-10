import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../buddy.dart';
import '../theme.dart';

/// Big friendly emoji tile used across all games.
class EmojiTile extends StatelessWidget {
  final String emoji;
  final double size;
  final VoidCallback? onTap;
  final bool dimmed;

  const EmojiTile({
    super.key,
    required this.emoji,
    this.size = 56,
    this.onTap,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget tile = Container(
      width: size + 14,
      height: size + 14,
      decoration: BoxDecoration(
        color: dimmed ? Colors.grey.shade300 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(child: Text(emoji, style: TextStyle(fontSize: size))),
    );
    if (onTap == null) return Opacity(opacity: dimmed ? 0.5 : 1, child: tile);
    return GestureDetector(onTap: onTap, child: tile);
  }
}

/// Springy press effect for any tappable child.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const Pressable({super.key, required this.child, required this.onTap});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// Big gradient pill button (chunky tap target for kids).
class BigButton extends StatelessWidget {
  final String label;
  final String? emoji;
  final List<Color> colors;
  final VoidCallback onTap;

  const BigButton({
    super.key,
    required this.label,
    this.emoji,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(28),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.last.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (emoji != null)
              Text(emoji!, style: const TextStyle(fontSize: 26)),
            if (emoji != null) const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round icon button with soft shadow.
class RoundIconButton extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;
  final double size;

  const RoundIconButton({
    super.key,
    required this.emoji,
    required this.onTap,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child:
            Center(child: Text(emoji, style: TextStyle(fontSize: size * 0.45))),
      ),
    );
  }
}

/// Shows "3 / 12" progress as filled and empty stars.
class ProgressStars extends StatelessWidget {
  final int total;
  final int done;
  final double size;

  const ProgressStars({
    super.key,
    required this.total,
    required this.done,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    // Cap drawn stars so 12-round games stay on one line.
    final int shown = total > 12 ? 12 : total;
    final int filled = (done * shown / total).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(shown, (int i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Text(
            i < filled ? '⭐' : '⚪',
            style: TextStyle(fontSize: size),
          ),
        );
      }),
    );
  }
}

/// Standard game header: back button, title, Buddy mood, progress stars.
class GameHeader extends StatelessWidget {
  final String title;
  final int total;
  final int done;
  final BuddyMood mood;

  const GameHeader({
    super.key,
    required this.title,
    required this.total,
    required this.done,
    this.mood = BuddyMood.idle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: <Widget>[
          RoundIconButton(emoji: '⬅️', onTap: () => Navigator.of(context).pop()),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
          ),
          Buddy(mood: mood, size: 54),
          const SizedBox(width: 6),
          ProgressStars(total: total, done: done),
        ],
      ),
    );
  }
}

/// Big answer pad used by several games.
class AnswerPad extends StatelessWidget {
  final List<int> options;
  final void Function(int value) onPick;

  const AnswerPad({super.key, required this.options, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 14,
      children: options.map((int v) {
        return Pressable(
          onTap: () => onPick(v),
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE6E0F8), width: 3),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$v',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Gentle bounce shown on a wrong answer (never scary).
class Wiggle extends StatefulWidget {
  final Widget child;
  final bool active;

  const Wiggle({super.key, required this.child, required this.active});

  @override
  State<Wiggle> createState() => _WiggleState();
}

class _WiggleState extends State<Wiggle> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  @override
  void didUpdateWidget(Wiggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _c.forward(from: 0);
  }

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
        final double dx = math.sin(_c.value * math.pi * 4) * 8 * (1 - _c.value);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}

/// Pop-in animation for tiles appearing.
class PopIn extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const PopIn({super.key, required this.child, this.delayMs = 0});

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final Animation<double> _scale =
      CurvedAnimation(parent: _c, curve: Curves.elasticOut);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
