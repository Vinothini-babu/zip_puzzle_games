import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'app_state.dart';

/// Generic fullscreen simulated rewarded-ad screen. Plays a real local
/// video (like a real rewarded ad) with a progress bar tied to video
/// position, mute toggle, and a claim button that unlocks once the
/// video finishes. Reusable for any placement (free coins, level-complete
/// bonus, etc) - just pass a different [videoAsset] / [rewardCoins].
///
/// TODO (later): replace the asset video with a real AdMob rewarded ad
/// call (RewardedAd.load -> ad.show(onUserEarnedReward: ...)). Keep the
/// same entry points so calling screens don't need to change when real
/// ads are wired in.

// --- Free Coins button (level select screen) ---
const int kFreeCoinsReward = 25;
const String kFreeCoinsVideoAsset = 'assets/videos/funny_ad.mp4';

Future<void> showFreeCoinsAd(BuildContext context) => showRewardedAd(
  context,
  videoAsset: kFreeCoinsVideoAsset,
  rewardCoins: kFreeCoinsReward,
);

/// Fallback duration used for the progress/claim-unlock logic if the
/// video fails to load (e.g. asset missing during testing).
const int kFallbackAdDurationSeconds = 6;

/// Shows the fullscreen ad screen and credits [rewardCoins] once the
/// user finishes watching and taps Claim. Awaiting this completes when
/// the user closes the reward screen (taps Done).
Future<void> showRewardedAd(
    BuildContext context, {
      required String videoAsset,
      required int rewardCoins,
    }) async {
  await Navigator.of(context).push(
    PageRouteBuilder(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => _FakeAdScreen(
        videoAsset: videoAsset,
        rewardCoins: rewardCoins,
      ),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _FakeAdScreen extends StatefulWidget {
  final String videoAsset;
  final int rewardCoins;

  const _FakeAdScreen({
    required this.videoAsset,
    required this.rewardCoins,
  });

  @override
  State<_FakeAdScreen> createState() => _FakeAdScreenState();
}

class _FakeAdScreenState extends State<_FakeAdScreen> {
  static const Color goldAccent = Color(0xFFFFC107);

  VideoPlayerController? _controller;
  Timer? _fallbackTicker;

  bool _videoReady = false;
  bool _videoFailed = false;
  bool _finished = false;
  bool _claimed = false;
  bool _muted = false;
  int _fallbackSecondsLeft = kFallbackAdDurationSeconds;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(widget.videoAsset);
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      controller.addListener(_onVideoTick);
      await controller.play();
      setState(() => _videoReady = true);
    } catch (e) {
      // Asset missing / failed to load - fall back to a plain timed
      // countdown so the reward flow still works during testing.
      if (!mounted) return;
      setState(() => _videoFailed = true);
      _startFallbackTicker();
    }
  }

  void _onVideoTick() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final pos = controller.value.position;
    final dur = controller.value.duration;
    if (!_finished && dur.inMilliseconds > 0 && pos >= dur) {
      setState(() => _finished = true);
    } else {
      // Trigger progress-bar rebuilds as the video plays.
      if (mounted) setState(() {});
    }
  }

  void _startFallbackTicker() {
    _fallbackTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _fallbackSecondsLeft =
            (_fallbackSecondsLeft - 1).clamp(0, kFallbackAdDurationSeconds);
      });
      if (_fallbackSecondsLeft == 0) {
        timer.cancel();
        setState(() => _finished = true);
      }
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    _fallbackTicker?.cancel();
    super.dispose();
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      _muted = !_muted;
      controller.setVolume(_muted ? 0 : 1);
    });
  }

  void _claimReward() {
    AppState.instance.addBonusCoins(widget.rewardCoins);
    setState(() => _claimed = true);
  }

  double get _progress {
    if (_videoFailed) {
      return 1 - (_fallbackSecondsLeft / kFallbackAdDurationSeconds);
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return 0;
    final dur = controller.value.duration.inMilliseconds;
    if (dur == 0) return 0;
    return (controller.value.position.inMilliseconds / dur).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Block back button/gesture until the ad finishes - matches how
      // real rewarded ads behave.
      canPop: _finished,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: _claimed
                      ? _RewardContent(
                    rewardCoins: widget.rewardCoins,
                    onDone: () => Navigator.of(context).pop(),
                  )
                      : _buildAdArea(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 6,
                        backgroundColor: Colors.white24,
                        valueColor:
                        const AlwaysStoppedAnimation(goldAccent),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!_claimed)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _finished ? _claimReward : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: goldAccent,
                            disabledBackgroundColor: Colors.white24,
                            foregroundColor: Colors.black87,
                            disabledForegroundColor: Colors.white54,
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _finished
                                ? 'Claim ${widget.rewardCoins} Coins'
                                : 'Watching ad...',
                            style:
                            const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildAdArea() {
    final controller = _controller;

    if (_videoFailed) {
      // Fallback placeholder if the video asset couldn't load.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off_rounded,
              color: Colors.white38, size: 56),
          const SizedBox(height: 16),
          const Text('Advertisement',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text('${_fallbackSecondsLeft}s remaining',
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      );
    }

    if (!_videoReady || controller == null) {
      return const CircularProgressIndicator(color: Colors.white54);
    }

    return Stack(
      alignment: Alignment.topRight,
      children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: _toggleMute,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shown after the reward is claimed.
class _RewardContent extends StatelessWidget {
  final int rewardCoins;
  final VoidCallback onDone;
  const _RewardContent({required this.rewardCoins, required this.onDone});

  static const Color goldAccent = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: const Icon(Icons.emoji_events_rounded,
                color: goldAccent, size: 72),
          ),
          const SizedBox(height: 20),
          const Text(
            'Coins Collected!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '+$rewardCoins coins added to your balance',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: goldAccent,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Done',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}