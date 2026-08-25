// share_helper.dart
// Small wrapper around share_plus so every "Share" button in the app
// sends a consistent message. Requires the share_plus package - add
// this to pubspec.yaml under dependencies:
//
//   share_plus: ^10.1.2
//
// then run `flutter pub get`.

import 'package:share_plus/share_plus.dart';

class ShareHelper {
  /// Shares a generic invite while playing a level.
  static Future<void> sharePlaying({required int levelId}) {
    return SharePlus.instance.share(
      ShareParams(
        text: "I'm playing Level $levelId on Zip Puzzle! 🧩 Connect the "
            "numbers and fill the grid - can you beat it?",
      ),
    );
  }

  /// Shares a level-complete result with the coins earned.
  static Future<void> shareLevelComplete({
    required int levelId,
    required int coinsEarned,
  }) {
    return SharePlus.instance.share(
      ShareParams(
        text: "I just solved Level $levelId on Zip Puzzle and earned "
            "$coinsEarned coins! 🎉🧩 Think you can beat my time?",
      ),
    );
  }
}