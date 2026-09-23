import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/ad_service.dart';
import '../core/app_theme.dart';
import '../core/game_state.dart';
import '../core/routes.dart';
import '../game/board_factory.dart';
import '../game/puzzle_controller.dart';
import '../widgets/coin_pill.dart';
import '../widgets/dialogs.dart';
import '../widgets/flower_background.dart';
import '../widgets/game_button.dart';
import '../widgets/how_to_play_dialog.dart';
import '../widgets/mini_board_preview.dart';
import '../widgets/stroked_text.dart';
import 'level_complete_screen.dart';
import 'shop_screen.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key, required this.level});
  final int level;

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  final GameState gs = GameState.instance;
  late PuzzleController _ctrl;
  Widget? _board;
  int _boardKey = 0;

  Timer? _timer;
  final ValueNotifier<int> _seconds = ValueNotifier<int>(0);

  int _movesLeft = AppInfo.startMoves;
  int _resets = 0;
  bool _unlimited = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _newController();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_finished) _seconds.value++;
    });
    if (widget.level == 1 && !gs.seenHowToPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          gs.markHowToPlaySeen();
          showHowToPlayDialog(context);
        }
      });
    }
  }

  void _newController() {
    _ctrl = PuzzleController(widget.level)
      ..onReset = _onReset
      ..onSolved = _onSolved;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _seconds.dispose();
    super.dispose();
  }

  bool get _isUnlimited => gs.premium || _unlimited;

  // ── events from the board ──
  void _onReset() {
    if (_finished) return;
    _resets++;
    if (_isUnlimited) return;
    setState(() => _movesLeft = math.max(0, _movesLeft - 1));
    if (_movesLeft == 0) _showOutOfMoves();
  }

  void _onSolved() {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    final reward = _computeReward();
    final preview = _ctrl.solvedPreviewBuilder?.call(context) ??
        MiniBoardPreview(n: 4 + GameState.chapterOf(widget.level));
    // small delay so your blink-on-solve animation can play
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        fadeRoute(LevelCompleteScreen(
            level: widget.level, baseReward: reward, preview: preview)),
      );
    });
  }

  /// Time + resets based reward (tweak freely).
  int _computeReward() {
    final s = _seconds.value;
    final base = 10 + widget.level * 2;
    final timeBonus = s < 30 ? 8 : (s < 60 ? 4 : 0);
    return math.max(5, base + timeBonus - _resets * 2);
  }

  // ── dialogs / actions ──
  Future<void> _showOutOfMoves() async {
    final action = await showOutOfMovesDialog(context);
    if (!mounted || action == null) return;
    switch (action) {
      case OutOfMovesAction.coins:
        if (gs.spendCoins(AppInfo.unlimitedMovesCost)) {
          setState(() => _unlimited = true);
        } else {
          await showMessageDialog(context,
              title: 'NOT ENOUGH COINS',
              message: 'Get more coins in the shop.',
              ribbon: AppColors.red,
              ribbonDark: AppColors.redDark);
          if (mounted) Navigator.push(context, fadeRoute(const ShopScreen()));
        }
        break;
      case OutOfMovesAction.ad:
        final ok = await AdService.showRewarded();
        if (ok && mounted) setState(() => _unlimited = true);
        break;
      case OutOfMovesAction.premium:
        gs.buyPremium(); // demo purchase – hook up in_app_purchase later
        setState(() {});
        break;
      case OutOfMovesAction.restart:
        await _confirmRestart();
        break;
    }
  }

  Future<void> _confirmRestart() async {
    final yes = await showRestartConfirm(context);
    if (yes && mounted) _restart();
  }

  void _restart() {
    setState(() {
      _movesLeft = AppInfo.startMoves;
      _resets = 0;
      _finished = false;
      _board = null;
      _boardKey++;
      _newController();
      _seconds.value = 0;
    });
  }

  void _hint() {
    if (_ctrl.showHint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hint is not connected to the board yet')),
      );
      return;
    }
    if (!gs.spendCoins(AppInfo.hintCost)) {
      showMessageDialog(context,
          title: 'NOT ENOUGH COINS',
          message: 'A hint costs ${AppInfo.hintCost} coins.',
          ribbon: AppColors.red,
          ribbonDark: AppColors.redDark);
      return;
    }
    _ctrl.showHint!.call();
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  // ── UI ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlowerBackground(
        child: SafeArea(
          child: Column(
            children: [
              _topBar(),
              const SizedBox(height: 10),
              StrokedText('LEVEL ${widget.level}', size: 32),
              StrokedText(GameState.difficultyOf(widget.level),
                  size: 14, fill: AppColors.cream, stroke: AppColors.brownDark),
              if (widget.level == 1) ...[
                const SizedBox(height: 6),
                GameButton(
                  height: 34,
                  radius: 12,
                  style: GameButtonStyle.purple,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  onTap: () => showHowToPlayDialog(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.help_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      const StrokedText('HOW TO PLAY',
                          size: 13, stroke: AppColors.purpleDark, dropShadow: 1.5),
                    ],
                  ),
                ),
              ],
              Expanded(child: _boardArea()),
              _bottomBar(),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return ListenableBuilder(
      listenable: gs,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        // SingleChildScrollView = safety net: on very narrow phones the
        // MOVES/TIME/coins/settings cluster now scrolls instead of
        // overflowing off the edge of the screen.
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoBox('MOVES', Text(_isUnlimited ? '∞' : '$_movesLeft', style: _valueStyle)),
              const SizedBox(width: 8),
              ValueListenableBuilder<int>(
                valueListenable: _seconds,
                builder: (_, s, __) =>
                    _infoBox('TIME', Text(_fmt(s), style: _valueStyle)),
              ),
              const SizedBox(width: 14),
              CoinPill(
                coins: gs.coins,
                onAdd: () => Navigator.push(context, fadeRoute(const ShopScreen())),
              ),
              const SizedBox(width: 10),
              GameButton(
                width: 42,
                height: 38,
                radius: 12,
                style: GameButtonStyle.orange,
                padding: EdgeInsets.zero,
                onTap: () => showSettingsDialog(context),
                child: const Icon(Icons.settings_rounded, color: Colors.white, size: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle get _valueStyle => AppText.display(20, color: AppColors.brownDark, height: 1);

  Widget _infoBox(String label, Widget value) {
    return Container(
      width: 62,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.orangeLight, AppColors.orange],
        ),
        boxShadow: const [BoxShadow(color: AppColors.orangeDark, offset: Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StrokedText(label, size: 12, stroke: AppColors.orangeDark, dropShadow: 1.5),
          value,
        ],
      ),
    );
  }

  Widget _boardArea() {
    return LayoutBuilder(builder: (context, cons) {
      final side = math.max(120.0, math.min(cons.maxWidth - 28, cons.maxHeight - 12));
      _board ??= buildBoardForLevel(context, widget.level, _ctrl);
      return Center(
        child: Container(
          width: side,
          height: side,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.orangeLight, AppColors.orange],
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF6E7D4),
              borderRadius: BorderRadius.circular(18),
            ),
            child: KeyedSubtree(key: ValueKey(_boardKey), child: _board!),
          ),
        ),
      );
    });
  }

  Widget _bottomBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GameButton(
          width: 72,
          height: 54,
          radius: 16,
          style: GameButtonStyle.orange,
          padding: EdgeInsets.zero,
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.home_rounded, color: Colors.white, size: 30),
        ),
        GameButton(
          width: 72,
          height: 54,
          radius: 16,
          style: GameButtonStyle.red,
          padding: EdgeInsets.zero,
          onTap: _confirmRestart,
          child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 32),
        ),
        GameButton(
          width: 110,
          height: 54,
          radius: 16,
          style: GameButtonStyle.purple,
          padding: EdgeInsets.zero,
          onTap: _hint,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 26),
              const SizedBox(width: 6),
              const CoinIcon(size: 20),
              const SizedBox(width: 3),
              StrokedText('${AppInfo.hintCost}',
                  size: 16, stroke: AppColors.purpleDark, dropShadow: 1.5),
            ],
          ),
        ),
      ],
    );
  }
}
