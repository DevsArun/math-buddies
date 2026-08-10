import 'package:flutter/material.dart';

import '../data/media.dart';
import '../data/progress_store.dart';
import 'buddy.dart';
import 'home_screen.dart';
import 'theme.dart';
import 'widgets/effects.dart';
import 'widgets/game_widgets.dart';

/// First-launch screen: meet Buddy + pick age group (drives difficulty).
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _pick(BuildContext context, String ageGroup) async {
    ProgressStore.instance.setAgeGroup(ageGroup);
    await MediaService.applyMusicSetting();
    await MediaService.play('win');
    await MediaService.say("Let's play!");
    if (context.mounted) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const HomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.bgGradient,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              const FloatingStars(),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Buddy(mood: BuddyMood.happy, size: 130),
                      const SizedBox(height: 8),
                      const Text(
                        'Math Buddies',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Hi! I'm Buddy! Pick your age\nto start the adventure 🚀",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.softGrey,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          _AgeCard(
                            emoji: '🧒',
                            title: 'Ages 3-4',
                            subtitle: 'Little Explorer',
                            colors: const <Color>[
                              Color(0xFF56CCF2),
                              Color(0xFF2F80ED),
                            ],
                            onTap: () => _pick(context, 'little'),
                          ),
                          const SizedBox(width: 20),
                          _AgeCard(
                            emoji: '🧑',
                            title: 'Ages 5-6',
                            subtitle: 'Big Explorer',
                            colors: const <Color>[
                              Color(0xFFFF9A8B),
                              Color(0xFFFF6A88),
                            ],
                            onTap: () => _pick(context, 'big'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  const _AgeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.last.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            Text(emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
