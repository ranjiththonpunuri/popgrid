import 'dart:io';

/// Configuration for Google Mobile Ads.
class AdConfig {
  AdConfig._();

  // ── Frequency / UX settings ──────────────────────────────────────────
  static const int interstitialGameInterval = 3;
  static const int interstitialCooldownSeconds = 180; // 3 minutes
  static const int freeUndosPerGame = 1;

  // ── Banner ───────────────────────────────────────────────────────────
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-7743725593722600/2350182038';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-7743725593722600/2350182038'; // TODO: Replace with iOS ad unit ID
    }
    return '';
  }

  // ── Interstitial ─────────────────────────────────────────────────────
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-7743725593722600/4848520732';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-7743725593722600/4848520732'; // TODO: Replace with iOS ad unit ID
    }
    return '';
  }

  // ── Rewarded ─────────────────────────────────────────────────────────
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-7743725593722600/6720538437';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-7743725593722600/6720538437'; // TODO: Replace with iOS ad unit ID
    }
    return '';
  }
}
