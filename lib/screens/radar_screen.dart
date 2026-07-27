import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Centralized AdMob ad management.
/// - Loads a banner once per screen visit (no auto-reload loops).
/// - Shows an interstitial only after [_actionsBeforeInterstitial]
///   user-triggered actions (never on app launch/splash).
/// - Never throws - every ad call is wrapped so the app can't crash
///   if AdMob fails to initialize (e.g. no internet).
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoaded = false;

  int _actionCounter = 0;
  static const int _actionsBeforeInterstitial = 3;

  String get _bannerUnitId => dotenv.env['ADMOB_BANNER_UNIT_ID'] ?? '';
  String get _interstitialUnitId => dotenv.env['ADMOB_INTERSTITIAL_UNIT_ID'] ?? '';

  /// Call once, early in main() after dotenv is loaded.
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      _loadInterstitialAd();
    } catch (e) {
      debugPrint('AdMob initialization failed (ads disabled this session): $e');
      _isInitialized = false;
    }
  }

  // ---------------- Banner Ad ----------------

  BannerAd? get bannerAd => _isBannerLoaded ? _bannerAd : null;
  bool get isBannerReady => _isBannerLoaded && _bannerAd != null;

  /// Loads a banner ad once. Safe to call multiple times - it will not
  /// reload if a banner is already loaded or in-flight for this session.
  Future<void> loadBannerAd({required VoidCallback onLoaded}) async {
    if (!_isInitialized || _bannerUnitId.isEmpty) return;
    if (_bannerAd != null) return; // already loaded/loading

    try {
      final banner = BannerAd(
        adUnitId: _bannerUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _isBannerLoaded = true;
            onLoaded();
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner ad failed to load: $error');
            _isBannerLoaded = false;
            ad.dispose();
            _bannerAd = null;
          },
        ),
      );
      _bannerAd = banner;
      await banner.load();
    } catch (e) {
      debugPrint('Banner ad load exception: $e');
      _isBannerLoaded = false;
      _bannerAd = null;
    }
  }

  void disposeBannerAd() {
    try {
      _bannerAd?.dispose();
    } catch (_) {}
    _bannerAd = null;
    _isBannerLoaded = false;
  }

  // ---------------- Interstitial Ad ----------------

  void _loadInterstitialAd() {
    if (!_isInitialized || _interstitialUnitId.isEmpty) return;
    try {
      InterstitialAd.load(
        adUnitId: _interstitialUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialLoaded = true;
            _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _interstitialAd = null;
                _isInterstitialLoaded = false;
                _loadInterstitialAd(); // preload the next one for later
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('Interstitial failed to show: $error');
                ad.dispose();
                _interstitialAd = null;
                _isInterstitialLoaded = false;
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial ad failed to load: $error');
            _isInterstitialLoaded = false;
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      debugPrint('Interstitial load exception: $e');
    }
  }

  /// Call this whenever the user performs a "countable" action:
  /// a manual weather refresh, or opening the radar screen.
  /// Shows an interstitial only every [_actionsBeforeInterstitial] actions.
  /// NEVER call this from splash screen, app init, or during data loading.
  void recordUserAction() {
    if (!_isInitialized) return;
    _actionCounter++;
    if (_actionCounter >= _actionsBeforeInterstitial) {
      _actionCounter = 0;
      _maybeShowInterstitial();
    }
  }

  void _maybeShowInterstitial() {
    try {
      if (_isInterstitialLoaded && _interstitialAd != null) {
        _interstitialAd!.show();
      }
    } catch (e) {
      debugPrint('Interstitial show exception: $e');
    }
  }

  void dispose() {
    disposeBannerAd();
    try {
      _interstitialAd?.dispose();
    } catch (_) {}
    _interstitialAd = null;
    _isInterstitialLoaded = false;
  }
}
