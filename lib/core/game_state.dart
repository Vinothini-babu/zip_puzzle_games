import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

/// Coins + progress. Persisted locally with shared_preferences
/// (swap the _save/load with Firebase later if you want cloud sync).
class GameState extends ChangeNotifier {
  GameState._();
  static final GameState instance = GameState._();

  int coins = AppInfo.startCoins;
  int solvedLevels = 0;
  bool premium = false;
  bool sound = true;
  bool vibration = true;
  bool seenHowToPlay = false;
  String avatarEmoji = '🐼';
  SharedPreferences? _prefs;

  /// Highest level the player can open right now. No cap — levels
  /// continue forever; the board size stops growing at the last entry
  /// in [_gridSizes] (16x16) so it never gets past playable size.
  int get unlockedLevel => math.max(1, solvedLevels + 1);

  /// Board size (n x n) for each level — a smooth, level-to-level ramp
  /// from a gentle 4x4 up to a big 16x16, then it holds at 16x16 for
  /// every level after that (levels are endless; the board isn't).
  /// Tune this list directly (one entry per level, in order) for a
  /// different ramp.
  static const List<int> _gridSizes = [4, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 16];

  /// Numbered checkpoints per level — ramps up more slowly than the
  /// board size, and likewise holds at its last value forever.
  static const List<int> _checkpointCounts = [3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 9];

  static int gridSizeForLevel(int level) =>
      _gridSizes[(level - 1).clamp(0, _gridSizes.length - 1)];

  static int checkpointCountForLevel(int level) =>
      _checkpointCounts[(level - 1).clamp(0, _checkpointCounts.length - 1)];

  /// Difficulty label is tied to the actual board size (not a level
  /// number), so it keeps making sense no matter how high the level
  /// count goes — anything past the ramp is simply "HARD" forever.
  static String difficultyOf(int level) {
    final n = gridSizeForLevel(level);
    if (n <= 7) return 'EASY';
    if (n <= 11) return 'MEDIUM';
    return 'HARD';
  }

  /// Levels are grouped into fixed-size chapters of 4 purely for the
  /// progress bar / level-list headers. Unlike the old difficulty-tier
  /// grouping, this has no upper bound, so it works identically whether
  /// there are 12 levels or 12,000 of them.
  static const int levelsPerChapter = 4;

  static int chapterOf(int level) => (level - 1) ~/ levelsPerChapter;

  /// 0..1 progress inside the chapter that contains [level].
  double chapterProgress(int level) {
    final start = chapterOf(level) * levelsPerChapter + 1;
    final done = (solvedLevels - start + 1).clamp(0, levelsPerChapter);
    return done / levelsPerChapter;
  }

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      coins = _prefs!.getInt('coins') ?? AppInfo.startCoins;
      solvedLevels = _prefs!.getInt('solved') ?? 0;
      premium = _prefs!.getBool('premium') ?? false;
      sound = _prefs!.getBool('sound') ?? true;
      vibration = _prefs!.getBool('vibration') ?? true;
      seenHowToPlay = _prefs!.getBool('seenHowToPlay') ?? false;
      avatarEmoji = _prefs!.getString('avatarEmoji') ?? '🐼';
    } catch (_) {}
    notifyListeners();
  }

  void _save() {
    final p = _prefs;
    if (p == null) return;
    p.setInt('coins', coins);
    p.setInt('solved', solvedLevels);
    p.setBool('premium', premium);
    p.setBool('sound', sound);
    p.setBool('vibration', vibration);
    p.setBool('seenHowToPlay', seenHowToPlay);
    p.setString('avatarEmoji', avatarEmoji);
  }

  void addCoins(int n) {
    coins += n;
    _save();
    notifyListeners();
  }

  bool spendCoins(int n) {
    if (coins < n) return false;
    coins -= n;
    _save();
    notifyListeners();
    return true;
  }

  void completeLevel(int level) {
    solvedLevels = math.max(solvedLevels, level);
    _save();
    notifyListeners();
  }

  void buyPremium() {
    premium = true;
    _save();
    notifyListeners();
  }

  void setSound(bool v) {
    sound = v;
    _save();
    notifyListeners();
  }

  void setVibration(bool v) {
    vibration = v;
    _save();
    notifyListeners();
  }

  void markHowToPlaySeen() {
    if (seenHowToPlay) return;
    seenHowToPlay = true;
    _save();
    notifyListeners();
  }

  void setAvatar(String emoji) {
    avatarEmoji = emoji;
    _save();
    notifyListeners();
  }
}