# Math Buddies 🚀

**Playful math adventures for little learners!** (ages 3–6)
Paid app ($4.99 one-time) for Amazon Fire tablets. No ads, no analytics, no login,
no internet, no in-app purchases — buy once, everything unlocked forever.

## What's inside (v2.0)
| Feature | Detail |
|---|---|
| 🎮 8 game worlds | Counting, Tracing, Add & Take Away, Shapes, Patterns, Big & Small, **Bubble Pop**, **Memory Match** |
| 🔊 Buddy voice + speech bubbles | Speaks instructions AND shows them in a bubble — via on-device TTS |
| 🎵 Audio | 13 synthesized sound effects + gentle music-box loop (all offline) |
| 🚀 Branded splash | Animated logo splash with Buddy |
| 🎨 Buddy colors | Kids pick Buddy's rocket color (3 choices) |
| 🎁 Daily treasure chest | +5 bonus stars once a day — kids come back daily |
| 🏆 Trophies | 8 achievements (Star Champion, World Explorer, Perfectionist...) |
| 🧒 Adaptive difficulty | Ages 3–4 / 5–6; tracing adds ONE–TEN words for big kids |
| 🗺️ Adventure Map | Winding path home, animated gradient, buttery transitions |
| 🏅 32 stickers | Earn per game tier + perfect-run bonuses; decorate **My Space Scene** |
| 👨‍👩‍👧 Grown-ups dashboard | Parental gate, per-game progress, play time, skills report, controls, reset |

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
- Version `2.0.0+6` — bump `version:` in `pubspec.yaml` for every re-upload (rule J12).
- Regenerate audio anytime: `python3 tools/make_sounds.py`; icons: `python3 tools/make_icons.py`.
