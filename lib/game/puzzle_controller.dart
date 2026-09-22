import 'package:flutter/widgets.dart';

/// Bridge between the themed PuzzleScreen and YOUR ZipPuzzleGrid.
///
/// Grid  -> screen : call [reportReset] when the player clears the path,
///                   call [reportSolved] when the puzzle is solved.
/// Screen -> grid  : the grid can assign [showHint] (called when Hint is tapped)
///                   and [solvedPreviewBuilder] (widget for the level-complete hoop).
class PuzzleController {
  PuzzleController(this.level);
  final int level;

  // set by the board widget (optional)
  VoidCallback? showHint;
  WidgetBuilder? solvedPreviewBuilder;

  // set by PuzzleScreen
  VoidCallback? onReset;
  VoidCallback? onSolved;

  void reportReset() => onReset?.call();
  void reportSolved() => onSolved?.call();
}
