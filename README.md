# Math Buddies 🚀

**Playful math adventures for little learners!** (ages 3–6)
Paid app ($4.99 one-time) for Amazon Fire tablets. No ads, no analytics, no login,
no internet, no in-app purchases — buy once, everything unlocked forever.

## What's inside (v1.1)
| Feature | Detail |
|---|---|
| 🎮 6 game worlds | Counting (Farm), Tracing (Space), Add & Take Away (Ocean), Shapes (Kingdom), Patterns (Jungle), Big & Small (Dino) |
| 🔊 Buddy voice | Speaks instructions, counts along, praises — via on-device TTS |
| 🎵 Audio | 11 synthesized sound effects + gentle music-box loop (all offline) |
| 🧒 Adaptive difficulty | Ages 3–4 / 5–6 picked at first launch; games auto-tune |
| 🗺️ Adventure Map | Winding path home screen, one planet per world |
| 🏅 24 stickers | Earn per game tier + perfect-run bonuses; decorate **My Space Scene** |
| 👨‍👩‍👧 Grown-ups dashboard | Parental gate, per-game progress bars, play time, skills report, sound/music/age controls, reset |

## How the build works (you never install anything)
1. Push this repo to GitHub (PRIVATE).
2. Add the 4 signing secrets (see **signing kit** zip README).
3. GitHub Actions runs `.github/workflows/build.yml`:
   - creates the Android shell in CI (rule B),
   - pins compileSdk 36 / targetSdk 34 / minSdk 22 / NDK 28.2.13676358 / Java 17 (rules A, J5, J6),
   - runs `flutter analyze` + `flutter test` (blocking, rule J3),
   - builds **signed release APK** and verifies the signature (rules C, J8).
4. Download artifacts from the Actions run:
   - **`AMAZON-UPLOAD-signed-release`** → upload THIS one to the Amazon Console.
   - **`APPETIZE-ONLY-debug`** → only for Appetize.io testing. **NEVER upload this to Amazon.**

## Tech rules baked in
- Zero manifest permissions, zero third-party Flutter plugins (rule J11).
- Progress + sticker scene saved on-device via a tiny platform channel.
- Audio: SoundPool (effects), MediaPlayer (music), TextToSpeech (voice) — all in MainActivity.
- R8/shrinking disabled in release (lesson K3).
- Version `1.1.0+2` — bump `version:` in `pubspec.yaml` for every re-upload (rule J12).
- Regenerate audio anytime: `python3 tools/make_sounds.py`; icons: `python3 tools/make_icons.py`.
