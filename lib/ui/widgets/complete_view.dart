import 'package:flutter/material.dart';

import '../../data/media.dart';
import '../buddy.dart';
import '../theme.dart';
import 'effects.dart';
import 'game_widgets.dart';

/// Celebration screen shown when a game is finished — Buddy parties,
/// fanfare plays, and the new sticker is revealed.
class GameCompleteView extends StatefulWidget {
  final String title;
  final String stickerEmoji;
  final int stars;

  const GameCompleteView({
    super.key,
    required this.title,
    required this.stickerEmoji,
    required this.stars,
  });

  @override
  State<GameCompleteView> createState() => _GameCompleteViewState();
}

class _GameCompleteViewState extends State<GameCompleteView> {
  @override
  void initState() {
    super.initState();
    MediaService.play('win');
    MediaService.say('You did it! Amazing!');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        const Positioned.fill(child: ConfettiBurst(count: 48)),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Buddy(mood: BuddyMood.celebrate, size: 110),
              const SizedBox(height: 4),
              Text(widget.stickerEmoji, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 8),
              Text(widget.title, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 10),
              Text(
                'You earned ${widget.stars} stars!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.softGrey,
                ),
              ),
              const SizedBox(height: 28),
              BigButton(
                label: 'Yay! Done',
                emoji: '🎉',
                colors: const <Color>[Color(0xFF43E97B), Color(0xFF38B2F9)],
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
