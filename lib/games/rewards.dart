import '../data/progress_store.dart';

/// Shared praise + encouragement lines for Buddy's voice.
const List<String> kPraise = <String>[
  'Great job!',
  'Awesome!',
  'You did it!',
  'Super star!',
  'Amazing!',
  'Fantastic!',
];

const List<String> kTryAgain = <String>[
  'Try again!',
  'Almost there!',
  'One more try!',
  'You can do it!',
];

/// Number words 0..20 for Buddy's voice.
const List<String> kNumberWords = <String>[
  'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight',
  'nine', 'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen',
  'sixteen', 'seventeen', 'eighteen', 'nineteen', 'twenty',
];

class StickerDef {
  final String id;
  final String emoji;
  const StickerDef(this.id, this.emoji);
}

/// 24 collectible stickers — 4 per game world.
const List<StickerDef> kStickers = <StickerDef>[
  // Farm World (counting)
  StickerDef('counting_1', '🐮'),
  StickerDef('counting_2', '🥕'),
  StickerDef('counting_3', '🌻'),
  StickerDef('counting_4', '🚜'),
  // Space Station (tracing)
  StickerDef('tracing_1', '🚀'),
  StickerDef('tracing_2', '🪐'),
  StickerDef('tracing_3', '🌟'),
  StickerDef('tracing_4', '👨‍🚀'),
  // Ocean Bay (add & take away)
  StickerDef('jodtod_1', '🐠'),
  StickerDef('jodtod_2', '🐙'),
  StickerDef('jodtod_3', '🦀'),
  StickerDef('jodtod_4', '🐬'),
  // Shape Kingdom (shapes)
  StickerDef('shapes_1', '🏰'),
  StickerDef('shapes_2', '👑'),
  StickerDef('shapes_3', '🧩'),
  StickerDef('shapes_4', '🎪'),
  // Jungle Jam (patterns)
  StickerDef('patterns_1', '🦁'),
  StickerDef('patterns_2', '🦜'),
  StickerDef('patterns_3', '🍍'),
  StickerDef('patterns_4', '🌺'),
  // Dino Valley (compare)
  StickerDef('compare_1', '🦕'),
  StickerDef('compare_2', '🐘'),
  StickerDef('compare_3', '🦒'),
  StickerDef('compare_4', '🐋'),
];

String stickerEmoji(String id) {
  for (final StickerDef s in kStickers) {
    if (s.id == id) return s.emoji;
  }
  return '⭐';
}

/// Call after every completed round: adds a star and unlocks stickers at
/// 1/3, 2/3 and full completion (+ a perfect-run bonus sticker).
void awardRoundRewards(
  String gameId,
  int completedRounds,
  int totalRounds,
  int mistakes,
) {
  final ProgressStore store = ProgressStore.instance;
  store.addStar(gameId);
  final int t1 = (totalRounds / 3).ceil();
  final int t2 = (2 * totalRounds / 3).ceil();
  if (completedRounds == t1) store.addSticker('${gameId}_1');
  if (completedRounds == t2) store.addSticker('${gameId}_2');
  if (completedRounds >= totalRounds) {
    store.addSticker('${gameId}_3');
    if (mistakes == 0) store.addSticker('${gameId}_4');
  }
}
