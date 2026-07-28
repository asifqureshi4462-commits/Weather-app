import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Centralized AdMob integration.
///
/// Ad unit IDs are read from the .env file (ADMOB_BANNER_UNIT_ID /
/// ADMOB_INTERSTITIAL_UNIT_ID), which GitHub Actions populates from repo
/// secrets at build time (see .github/workflows/build_apk.yml). If no .env
/// value is present (e.g. running locally without a .env), Google's public
/// test ad unit IDs are used instead so ads still render during development
/// without ever risking policy-violating test traffic on a real ad unit.
class AdService {
  AdService._();

  static const String _testBannerUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  static String get bannerUnitId {
    final id = dotenv.env['ADMOB_BANNER_UNIT_ID'];
    if (id == null || id.isEmpty || id.contains('your_')) {
      return _testBannerUnitId;
    }
    return id;
  }

  static String get interstitialUnitId {
    final id = dotenv.env['ADMOB_INTERSTITIAL_UNIT_ID'];
    if (id == null || id.isEmpty || id.contains('your_')) {
      return _testInterstitialUnitId;
    }
    return id;
  }

  static bool _initialized = false;
  static InterstitialAd? _interstitialAd;

  /// Must be called once before runApp(). Safe to call multiple times.
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadInterstitialAd();
    } catch (e) {
      debugPrint('AdService: MobileAds failed to initialize: $e');
    }
  }

  /// Creates a fresh, ready-to-load standard banner ad.
  static BannerAd createBannerAd({required VoidCallback onLoaded, VoidCallback? onFailed}) {
    return BannerAd(
      adUnitId: bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdService: banner failed to load: $error');
          ad.dispose();
          onFailed?.call();
        },
      ),
    );
  }

  static void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) {
          debugPrint('AdService: interstitial failed to load: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Shows the preloaded interstitial (if ready) then preloads the next one.
  /// Safe to call even if no ad is ready yet — it will simply no-op.
  static void showInterstitialIfReady({VoidCallback? onDismissed}) {
    final ad = _interstitialAd;
    if (ad == null) {
      onDismissed?.call();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        onDismissed?.call();
      },
    );
    ad.show();
  }
}
