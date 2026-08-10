import 'package:flutter/material.dart';

import 'data/media.dart';
import 'data/progress_store.dart';
import 'ui/buddy.dart';
import 'ui/home_screen.dart';
import 'ui/onboarding.dart';
import 'ui/theme.dart';
import 'ui/widgets/effects.dart';

void main() {
  runApp(const MathBuddiesApp());
}

class MathBuddiesApp extends StatelessWidget {
  const MathBuddiesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Buddies',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const SplashGate(),
    );
  }
}

/// Branded animated splash: Buddy rises, logo fades in, then routes to
/// onboarding (first launch) or the adventure map.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  bool _ready = false;
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  @override
  void initState() {
    super.initState();
    // Continue only when BOTH the save file is loaded AND the brand intro
    // has had its moment.
    Future.wait(<Future<void>>[
      ProgressStore.instance.load(),
      Future<void>.delayed(const Duration(milliseconds: 1900)),
    ]).then((_) async {
      await MediaService.applyMusicSetting();
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return ProgressStore.instance.ageGroup == null
          ? const OnboardingScreen()
          : const HomeScreen();
    }
    return Scaffold(
      body: AnimatedGradientBg(
        child: Stack(
          children: <Widget>[
            const FloatingStars(),
            Center(
              child: AnimatedBuilder(
                animation: _intro,
                builder: (BuildContext context, Widget? child) {
                  final double t = Curves.easeOut.transform(_intro.value);
                  final double fade = Curves.easeIn.transform(_intro.value);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Transform.translate(
                        offset: Offset(0, (1 - t) * 70),
                        child: const Buddy(mood: BuddyMood.happy, size: 120),
                      ),
                      const SizedBox(height: 10),
                      Opacity(
                        opacity: fade,
                        child: const Text(
                          'Math Buddies',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: fade,
                        child: const Text(
                          'Playful math adventures!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.softGrey,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
