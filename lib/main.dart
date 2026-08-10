import 'package:flutter/material.dart';

import 'data/media.dart';
import 'data/progress_store.dart';
import 'ui/home_screen.dart';
import 'ui/onboarding.dart';
import 'ui/theme.dart';

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

/// Loads saved progress once, starts music, then routes to onboarding
/// (first launch) or the adventure map.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    ProgressStore.instance.load().then((_) async {
      await MediaService.applyMusicSetting();
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return ProgressStore.instance.ageGroup == null
          ? const OnboardingScreen()
          : const HomeScreen();
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.bgGradient,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('🚀', style: TextStyle(fontSize: 72)),
              SizedBox(height: 16),
              Text(
                'Math Buddies',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
