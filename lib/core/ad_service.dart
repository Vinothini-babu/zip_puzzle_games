import 'dart:async';
import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Real rewarded ads via AdMob.
///
/// These are GOOGLE'S OFFICIAL PUBLIC TEST AD UNIT IDs — safe to ship
/// while you're testing, they always have ads available and never
/// generate real revenue. Before you publish to the Play Store / App
/// Store, replace [_rewardedAdUnitId] with the ad unit ID from your own
/// AdMob account (admob.google.com -> Apps -> your app -> Ad units).
class AdService {
  static bool _initialized = false;
  static RewardedAd? _rewardedAd;
  static bool _loading = false;

  static String get _rewardedAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/5224354917';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/1712485313';
    return 'ca-app-pub-3940256099942544/5224354917';
  }

  /// Call once at app startup (see main.dart).
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await MobileAds.instance.initialize();
    _preload();
  }

  static void _preload() {
    if (_loading || _rewardedAd != null) return;
    _loading = true;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _loading = false;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _loading = false;
        },
      ),
    );
  }

  /// Shows a real rewarded ad and returns true only if the player
  /// watched it and earned the reward.
  ///
  /// If no ad is ready yet (no internet, still loading, no fill for this
  /// device/region) this falls back to granting the reward anyway after
  /// a short pause, so a missing ad never blocks the player. Delete the
  /// fallback block below once you want to strictly require a watched ad.
  static Future<bool> showRewarded() async {
    final ad = _rewardedAd;
    if (ad == null) {
      _preload(); // try to have one ready for next time
      await Future.delayed(const Duration(milliseconds: 500));
      return true; // ---- fallback: remove this line to require a real ad
    }

    _rewardedAd = null;
    final completer = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _preload();
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _preload();
        if (!completer.isCompleted) completer.complete(true); // fallback
      },
    );

    ad.show(onUserEarnedReward: (ad, reward) {
      if (!completer.isCompleted) completer.complete(true);
    });

    return completer.future;
  }
}