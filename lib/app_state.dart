// app_state.dart
// Simple in-memory app state: coins + level completion/unlock tracking.
// No external package needed - uses Flutter's built-in ChangeNotifier +
// ListenableBuilder. Swap this out for Firestore-backed state later
// without changing how screens read it.

import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  AppState._internal();
  static final AppState instance = AppState._internal();

  int coins = 0;
  final Set<int> completedLevels = {};

  /// Level 1 is always unlocked. Any other level unlocks once the
  /// previous level has been completed.
  bool isUnlocked(int levelId) {
    if (levelId == 1) return true;
    return completedLevels.contains(levelId - 1);
  }

  bool isCompleted(int levelId) => completedLevels.contains(levelId);

  void completeLevel(int levelId, int coinsEarned) {
    completedLevels.add(levelId);
    coins += coinsEarned;
    notifyListeners();
  }
}