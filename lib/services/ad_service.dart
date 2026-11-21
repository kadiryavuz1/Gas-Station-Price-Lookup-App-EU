import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static String get bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    // TODO: Replace with production IDs
    return '';
  }

  static String get appOpenAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/9257395912'
          : 'ca-app-pub-3940256099942544/5662855259';
    }
    // TODO: Replace with production IDs
    return 'ca-app-pub-3940256099942544/9257395912';
  }
}

/// Utility class to manage App Open Ads.
class AppOpenAdManager {
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;

  /// Load an App Open Ad.
  void loadAd({bool showImmediately = false}) {
    debugPrint('Attempting to load AppOpenAd with ID: ${AdService.appOpenAdUnitId}');
    AppOpenAd.load(
      adUnitId: AdService.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AppOpenAd loaded successfully');
          _appOpenAd = ad;
          if (showImmediately) {
            showAdIfAvailable();
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpenAd failed to load: ${error.message} (Code: ${error.code})');
        },
      ),
    );
  }

  /// Show the ad if available.
  void showAdIfAvailable() {
    if (_appOpenAd == null) {
      loadAd();
      return;
    }

    if (_isShowingAd) {
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
    );

    _appOpenAd!.show();
  }
}
