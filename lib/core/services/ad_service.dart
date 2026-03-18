import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:popgrid/core/services/ad_config.dart';

/// Singleton service managing all ad types (banner, interstitial, rewarded).
/// Register with GetIt and call [initialize] before use.
class AdService {
  // ── Ad-Free gate ─────────────────────────────────────────────────────
  bool _isAdFree = false;
  bool get isAdFree => _isAdFree;

  set isAdFree(bool value) {
    _isAdFree = value;
    if (value) {
      disposeBanner();
      _disposeInterstitial();
      _disposeRewarded();
    }
  }

  // ── Banner ───────────────────────────────────────────────────────────
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  BannerAd? get bannerAd => _bannerAd;
  bool get isBannerLoaded => _isBannerLoaded && !_isAdFree;

  // ── Interstitial ─────────────────────────────────────────────────────
  InterstitialAd? _interstitialAd;
  bool _isInterstitialReady = false;
  int _gamesCompletedCount = 0;
  DateTime? _lastInterstitialShown;

  // ── Rewarded ─────────────────────────────────────────────────────────
  RewardedAd? _rewardedAd;
  bool _isRewardedReady = false;

  bool get isRewardedReady => _isRewardedReady && !_isAdFree;

  // ── Initialization ───────────────────────────────────────────────────

  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
    } catch (_) {
      // Silent failure — ads are non-critical.
    }
  }

  // ── Banner API ───────────────────────────────────────────────────────

  Future<void> loadBanner({required double width, VoidCallback? onLoaded}) async {
    if (_isAdFree) return;

    disposeBanner();

    final adSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width.truncate(),
    );
    if (adSize == null) return;

    _bannerAd = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _isBannerLoaded = true;
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerLoaded = false;
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );

    try {
      await _bannerAd!.load();
    } catch (_) {
      _isBannerLoaded = false;
      _bannerAd = null;
    }
  }

  void disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerLoaded = false;
  }

  // ── Interstitial API ─────────────────────────────────────────────────

  void onGameCompleted() {
    _gamesCompletedCount++;
  }

  bool get shouldShowInterstitial {
    if (_isAdFree) return false;
    if (!_isInterstitialReady) return false;
    if (_gamesCompletedCount < AdConfig.interstitialGameInterval) return false;

    // Cooldown check
    if (_lastInterstitialShown != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialShown!);
      if (elapsed.inSeconds < AdConfig.interstitialCooldownSeconds) return false;
    }

    return true;
  }

  Future<void> preloadInterstitial() async {
    if (_isAdFree) return;

    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialReady = false;
              preloadInterstitial(); // Preload next
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialReady = false;
              preloadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (_) {
          _isInterstitialReady = false;
        },
      ),
    );
  }

  Future<void> showInterstitial() async {
    if (!shouldShowInterstitial) return;

    _gamesCompletedCount = 0;
    _lastInterstitialShown = DateTime.now();

    try {
      await _interstitialAd?.show();
    } catch (_) {
      // Silent failure
    }
  }

  void _disposeInterstitial() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialReady = false;
  }

  // ── Rewarded API ─────────────────────────────────────────────────────

  Future<void> preloadRewarded() async {
    if (_isAdFree) return;

    RewardedAd.load(
      adUnitId: AdConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedReady = true;
        },
        onAdFailedToLoad: (_) {
          _isRewardedReady = false;
        },
      ),
    );
  }

  /// Shows a rewarded ad. Returns `true` if the user earned the reward.
  Future<bool> showRewarded() async {
    if (!isRewardedReady || _rewardedAd == null) return false;

    final completer = Completer<bool>();
    bool rewarded = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _isRewardedReady = false;
        preloadRewarded(); // Preload next
        if (!completer.isCompleted) completer.complete(rewarded);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _isRewardedReady = false;
        preloadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (_, reward) {
          rewarded = true;
        },
      );
    } catch (_) {
      if (!completer.isCompleted) completer.complete(false);
    }

    return completer.future;
  }

  void _disposeRewarded() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedReady = false;
  }

  // ── Cleanup ──────────────────────────────────────────────────────────

  void dispose() {
    disposeBanner();
    _disposeInterstitial();
    _disposeRewarded();
  }
}

/// A widget that displays a banner ad.
/// Wraps [AdWidget] with proper sizing and ad-free gating.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key, required this.adService});

  final AdService adService;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ad == null && !widget.adService.isAdFree) {
      _loadBanner();
    }
  }

  Future<void> _loadBanner() async {
    final width = MediaQuery.of(context).size.width.truncate();
    final adSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (adSize == null || !mounted) return;

    final ad = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() { _ad = null; _isLoaded = false; });
        },
      ),
    );

    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _ad == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
