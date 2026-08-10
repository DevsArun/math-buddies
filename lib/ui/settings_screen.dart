import 'package:flutter/material.dart';

import '../data/media.dart';
import '../data/progress_store.dart';
import 'home_screen.dart';
import 'theme.dart';
import 'widgets/game_widgets.dart';

/// Grown-ups dashboard (behind the parental gate): sound/music controls,
/// age selection, per-game progress + skills report, reset.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _skillLabel(int stars) {
    if (stars >= 24) return 'Mastered ⭐';
    if (stars >= 12) return 'Practicing 💪';
    if (stars > 0) return 'Learning 🌱';
    return 'Not started';
  }

  String _minutes(String gameId) {
    final int m =
        (ProgressStore.instance.playSecondsFor(gameId) / 60).round();
    return '${m}m';
  }

  Future<void> _confirmReset(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Reset all progress?'),
          content: const Text(
            'This removes all stars, stickers and the sticker scene on this device. This cannot be undone.',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(fontSize: 18)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Reset',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
    if (ok ?? false) {
      await ProgressStore.instance.reset();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProgressStore store = ProgressStore.instance;
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
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: <Widget>[
                    RoundIconButton(
                      emoji: '⬅️',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Grown-ups',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: <Widget>[
                    _card(
                      title: '🔊 Sound',
                      child: Column(
                        children: <Widget>[
                          _switchRow(
                            'Sounds & Buddy voice',
                            store.soundOn,
                            (bool v) {
                              setState(() => store.setSoundOn(v));
                              MediaService.play('click');
                            },
                          ),
                          _switchRow(
                            'Background music',
                            store.musicOn,
                            (bool v) {
                              setState(() => store.setMusicOn(v));
                              MediaService.setMusic(v);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _card(
                      title: '🧒 Age group',
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: <Widget>[
                            _ageChip(store, 'little', 'Ages 3-4'),
                            const SizedBox(width: 12),
                            _ageChip(store, 'big', 'Ages 5-6'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _card(
                      title: '📊 Progress & skills',
                      child: Column(
                        children: <Widget>[
                          const SizedBox(height: 8),
                          for (final GameInfo g in kGames)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 7),
                              child: Row(
                                children: <Widget>[
                                  Text(g.emoji,
                                      style: const TextStyle(fontSize: 26)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          g.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: LinearProgressIndicator(
                                            value: (store.starsFor(g.id) / 24)
                                                .clamp(0.0, 1.0),
                                            minHeight: 8,
                                            backgroundColor:
                                                const Color(0xFFEDEAF6),
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    g.gradient.last),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: 96,
                                    child: Text(
                                      '⭐${store.starsFor(g.id)} · ${_minutes(g.id)}\n${_skillLabel(store.starsFor(g.id))}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.softGrey,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Divider(height: 24),
                          Text(
                            'Total play time: ${(store.totalPlaySeconds / 60).round()} minutes',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.softGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _card(
                      title: '🔒 Privacy',
                      body:
                          'Math Buddies collects no personal data. No ads, no analytics, no accounts, no internet. Progress is saved only on this device.',
                    ),
                    const SizedBox(height: 16),
                    _card(
                      title: '🧹 Progress',
                      body:
                          'Remove all stars, stickers and the sticker scene from this device.',
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: BigButton(
                          label: 'Reset progress',
                          emoji: '🗑️',
                          colors: const <Color>[
                            Color(0xFFFF9A8B),
                            Color(0xFFFF6A88),
                          ],
                          onTap: () => _confirmReset(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Math Buddies v1.1.1',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.softGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switchRow(String label, bool value, void Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _ageChip(ProgressStore store, String id, String label) {
    final bool active = store.ageGroup == id;
    return Pressable(
      onTap: () {
        setState(() => store.setAgeGroup(id));
        MediaService.play('click');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF7C5CFF) : const Color(0xFFF3F0FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? const Color(0xFF7C5CFF) : const Color(0xFFDDD6FE),
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: active ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }

  Widget _card({required String title, String? body, Widget? child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          if (body != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
                color: AppColors.softGrey,
              ),
            ),
          ],
          if (child != null) child,
        ],
      ),
    );
  }
}
