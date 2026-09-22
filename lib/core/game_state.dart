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
  SharedPreferences? _prefs;

  /// Highest level the player can open right now.
  int get unlockedLevel =>
      math.min(AppInfo.maxLevel, math.max(1, solvedLevels + 1));

  static int chapterOf(int level) => (level - 1) ~/ AppInfo.levelsPerChapter;

  static String difficultyOf(int level) {
    const names = ['EASY', 'MEDIUM', 'HARD'];
    return names[math.min(chapterOf(level), names.length - 1)];
  }

  /// 0..1 progress inside the chapter that contains [level].
  double chapterProgress(int level) {
    const per = AppInfo.levelsPerChapter;
    final done =
    math.min(per, math.max(0, solvedLevels - chapterOf(level) * per));
    return done / per;
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
}
