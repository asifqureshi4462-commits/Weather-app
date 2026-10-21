import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/smart_alert_service.dart';

export '../services/location_service.dart' show LocationIssue;

class WeatherProvider with ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();

  WeatherData? _currentWeather;
  WeatherData? _gpsWeather;
  final Map<String, WeatherData> _favoritesWeather = {};
  List<String> _favoriteCities = [];
  List<WeatherAlert> _currentAlerts = [];
  int _activeCityIndex = 0;

  bool _isLoading = false;
  bool _isLocating = false;
  String? _errorMessage;
  String? _toast;

  // Location state
  LocationIssue _locationIssue = LocationIssue.none;
  bool _usingGps = false;
  bool _userPickedCity = false; // user manually chose a city -> don't auto-switch to GPS
  DateTime? _lastUpdated;
  StreamSubscription<bool>? _serviceSub;

  // Settings
  String _unitSystem = 'metric'; // 'metric' (°C, km/h) or 'imperial' (°F, mph)
  String _themeMode = 'system'; // 'system', 'dark', 'light'
  bool _dailyNotifEnabled = true;
  int _dailyNotifHour = 8;
  int _dailyNotifMinute = 0;
  bool _alertsEnabled = true;
  bool _notificationsGranted = false;
  bool _notifPromptDismissed = false;

  final Completer<void> _readyCompleter = Completer<void>();

  WeatherData? get currentWeather => _currentWeather;
  WeatherData? get gpsWeather => _gpsWeather;
  Map<String, WeatherData> get favoritesWeather => _favoritesWeather;
  List<String> get favoriteCities => _favoriteCities;
  List<WeatherAlert> get currentAlerts => _currentAlerts;
  int get activeCityIndex => _activeCityIndex;

  bool get isLoading => _isLoading;
  bool get isLocating => _isLocating;
  String? get errorMessage => _errorMessage;

  LocationIssue get locationIssue => _locationIssue;
  bool get usingGps => _usingGps;
  DateTime? get lastUpdated => _lastUpdated;

  String get unitSystem => _unitSystem;
  bool get isMetric => _unitSystem == 'metric';
  String get themeMode => _themeMode;

  bool get dailyNotifEnabled => _dailyNotifEnabled;
  int get dailyNotifHour => _dailyNotifHour;
  int get dailyNotifMinute => _dailyNotifMinute;
  bool get alertsEnabled => _alertsEnabled;
  bool get notificationsGranted => _notificationsGranted;
  bool get notifPromptDismissed => _notifPromptDismissed;

  /// Completes once the first startup load (GPS attempt + weather) has finished.
  Future<void> get ready => _readyCompleter.future;

  WeatherProvider() {
    init();
  }

  /// One-shot message for a snackbar (non-blocking errors / info).
  String? consumeToast() {
    final t = _toast;
    _toast = null;
    return t;
  }

  String _clean(Object e) => e.toString().replaceAll('Exception: ', '');

  // ---------------------------------------------------------------------------
  // Startup
  // ---------------------------------------------------------------------------
  Future<void> init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _notificationService.init();

      _unitSystem = await _storageService.getUnitSystem();
      _themeMode = await _storageService.getThemeMode();
      _favoriteCities = await _storageService.getFavoriteCities();

      _dailyNotifEnabled = await _storageService.getDailyNotifEnabled();
      _dailyNotifHour = await _storageService.getDailyNotifHour();
      _dailyNotifMinute = await _storageService.getDailyNotifMinute();
      _alertsEnabled = await _storageService.getAlertsEnabled();
      _notifPromptDismissed = await _storageService.getNotifPromptDismissed();
      _notificationsGranted = await _notificationService.areNotificationsEnabled();

      _userPickedCity = false;

      // 1) Try GPS first. 2) If GPS is off / denied / fails, fall back to a saved city.
      final gpsOk = await refreshLocation();
      if (!gpsOk && _currentWeather == null) {
        final fallbackCity = _favoriteCities.isNotEmpty ? _favoriteCities.first : 'London';
        await loadWeatherForCity(fallbackCity, userInitiated: false);
      }

      _listenToServiceStatus();
      unawaited(refreshAllFavorites());
    } catch (e) {
      _errorMessage = _clean(e);
    } finally {
      _isLoading = false;
      if (!_readyCompleter.isCompleted) _readyCompleter.complete();
      notifyListeners();
    }
  }

  /// Automatically refresh the weather the moment the user turns GPS on.
  void _listenToServiceStatus() {
    if (_serviceSub != null) return;
    try {
      _serviceSub = _locationService.serviceEnabledStream.listen(
        (enabled) async {
          if (enabled) {
            if (!_userPickedCity) await refreshLocation();
          } else {
            _locationIssue = LocationIssue.serviceDisabled;
            notifyListeners();
          }
        },
        onError: (_) {},
      );
    } catch (e) {
      debugPrint('Could not listen to GPS status: $e');
    }
  }

  /// Called every time the app comes back to the foreground.
  Future<void> onAppResumed() async {
    if (!_readyCompleter.isCompleted) return;

    try {
      final granted = await _notificationService.areNotificationsEnabled();
      if (granted != _notificationsGranted) {
        _notificationsGranted = granted;
        notifyListeners();
        if (granted) await syncDailyNotification();
      }

      final stale = _lastUpdated == null ||
          DateTime.now().difference(_lastUpdated!) > const Duration(minutes: 10);

      if (_userPickedCity) {
        if (stale && _currentWeather != null) {
          await loadWeatherForCity(_currentWeather!.location.name);
        }
      } else {
        await refreshLocation();
      }
    } catch (e) {
      debugPrint('onAppResumed error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Location / weather loading
  // ---------------------------------------------------------------------------
  /// Gets the GPS position and loads weather for it. Returns true on success.
  /// When it fails because of GPS/permission, [locationIssue] tells the UI why.
  Future<bool> refreshLocation({bool askPermission = false}) async {
    if (_isLocating) return false;

    _isLocating = true;
    notifyListeners();

    try {
      final pos = await _locationService.getCurrentPosition(askPermission: askPermission);
      final query =
          '${pos.latitude.toStringAsFixed(4)},${pos.longitude.toStringAsFixed(4)}';
      final data = await _weatherService.fetchWeather(query);

      _gpsWeather = data;
      _usingGps = true;
      _userPickedCity = false;
      _locationIssue = LocationIssue.none;
      _errorMessage = null;
      _favoritesWeather[data.location.name] = data;

      await _applyWeather(data);
      return true;
    } on LocationException catch (e) {
      _locationIssue = e.issue;
      if (e.issue == LocationIssue.unavailable) _toast = e.message;
      return false;
    } catch (e) {
      final msg = _clean(e);
      if (_currentWeather == null) {
        _errorMessage = msg;
      } else {
        _toast = msg;
      }
      return false;
    } finally {
      _isLocating = false;
      notifyListeners();
    }
  }

  Future<void> loadWeatherForCity(String city, {bool userInitiated = true}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _weatherService.fetchWeather(city);
      _favoritesWeather[data.location.name] = data;
      _usingGps = false;
      if (userInitiated) _userPickedCity = true;
      await _applyWeather(data);
    } catch (e) {
      final msg = _clean(e);
      if (_currentWeather == null) {
        _errorMessage = msg;
      } else {
        _toast = msg;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Pull-to-refresh / manual refresh.
  Future<void> refreshCurrent() async {
    if (_currentWeather == null) {
      await init();
      return;
    }
    if (_usingGps && !_userPickedCity) {
      final ok = await refreshLocation();
      if (ok) return;
    }
    await loadWeatherForCity(_currentWeather!.location.name, userInitiated: _userPickedCity);
  }

  /// Switch back to the GPS weather (used by "My Location" in Saved Locations).
  Future<void> useGpsLocation() async {
    _userPickedCity = false;
    if (_gpsWeather != null) {
      _usingGps = true;
      await _applyWeather(_gpsWeather!);
    }
    unawaited(refreshLocation());
  }

  Future<void> _applyWeather(WeatherData data) async {
    _currentWeather = data;
    _lastUpdated = DateTime.now();
    _currentAlerts = SmartAlertService.combine(data, includeSmart: _alertsEnabled);

    final idx = _favoriteCities
        .indexWhere((c) => c.toLowerCase() == data.location.name.toLowerCase());
    if (idx != -1) _activeCityIndex = idx;

    notifyListeners();

    await _processAlertNotifications();
    await syncDailyNotification();
  }

  Future<void> refreshAllFavorites() async {
    for (final city in List<String>.from(_favoriteCities)) {
      try {
        final data = await _weatherService.fetchWeather(city);
        _favoritesWeather[data.location.name] = data;
      } catch (_) {}
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Location helpers used by the UI
  // ---------------------------------------------------------------------------
  Future<bool> requestLocationPermission() async {
    final granted = await _locationService.requestPermission();
    // Always re-check: this updates locationIssue (e.g. permission ok but GPS still off).
    await refreshLocation(askPermission: false);
    return granted;
  }

  Future<bool> openLocationSettings() => _locationService.openLocationSettings();

  Future<bool> openAppSettings() => _locationService.openAppSettings();

  // ---------------------------------------------------------------------------
  // Alerts & notifications
  // ---------------------------------------------------------------------------
  Future<void> _processAlertNotifications() async {
    if (!_alertsEnabled || _currentAlerts.isEmpty) return;

    try {
      final processed = await _storageService.getProcessedAlertIds();
      final updated = List<String>.from(processed);
      var sent = 0;

      for (final alert in _currentAlerts) {
        if (sent >= 3) break; // avoid notification spam
        if (processed.contains(alert.id)) continue;

        updated.add(alert.id);
        sent++;
        await _notificationService.showImmediateNotification(
          title: '⚠️ ${alert.event}',
          body: alert.headline,
          id: 3000 + (alert.id.hashCode & 0xFFFF),
        );
      }

      if (updated.length != processed.length) {
        await _storageService.saveProcessedAlertIds(updated);
      }
    } catch (e) {
      debugPrint('Error processing weather alerts: $e');
    }
  }

  Future<void> setAlertsEnabled(bool enabled) async {
    _alertsEnabled = enabled;
    await _storageService.setAlertsEnabled(enabled);
    if (_currentWeather != null) {
      _currentAlerts = SmartAlertService.combine(_currentWeather!, includeSmart: enabled);
    }
    notifyListeners();
    if (enabled) await _processAlertNotifications();
  }

  Future<bool> requestNotificationPermission() async {
    final granted = await _notificationService.requestPermissions();
    _notificationsGranted = granted;
    if (granted) await syncDailyNotification();
    notifyListeners();
    return granted;
  }

  Future<bool> isNotificationPermanentlyDenied() =>
      _notificationService.isPermanentlyDenied();

  Future<void> dismissNotifPrompt() async {
    _notifPromptDismissed = true;
    await _storageService.setNotifPromptDismissed(true);
  }

  /// Sends a real notification right now. Returns false if permission was refused.
  Future<bool> sendTestNotification() async {
    var granted = await _notificationService.areNotificationsEnabled();
    if (!granted) granted = await requestNotificationPermission();
    if (!granted) return false;

    final city = _currentWeather?.location.name ?? 'your area';
    await _notificationService.showImmediateNotification(
      title: '⚠️ Test Weather Alert',
      body: 'Notifications are working! You will receive weather alerts for $city here.',
      id: 9001,
    );
    return true;
  }

  Future<void> syncDailyNotification() async {
    if (!_dailyNotifEnabled || _currentWeather == null) {
      await _notificationService.cancelDailySummary();
      return;
    }

    final weather = _currentWeather!;
    final tempText = isMetric
        ? '${weather.current.tempC.round()}°C'
        : '${weather.current.tempF.round()}°F';

    final rainChance = weather.hourly.isNotEmpty
        ? weather.hourly.first.chanceOfRain
        : (weather.daily.isNotEmpty ? weather.daily.first.chanceOfRain : 0);

    final rainChanceText = rainChance > 0 ? '$rainChance% rain chance' : 'Low rain chance';

    await _notificationService.scheduleDailyMorningSummary(
      hour: _dailyNotifHour,
      minute: _dailyNotifMinute,
      cityName: weather.location.name,
      condition: weather.current.conditionText,
      tempText: tempText,
      rainChanceText: rainChanceText,
    );
  }

  Future<void> setDailyNotifEnabled(bool enabled) async {
    _dailyNotifEnabled = enabled;
    await _storageService.setDailyNotifEnabled(enabled);
    await syncDailyNotification();
    notifyListeners();
  }

  Future<void> setDailyNotifTime(int hour, int minute) async {
    _dailyNotifHour = hour;
    _dailyNotifMinute = minute;
    await _storageService.setDailyNotifTime(hour, minute);
    await syncDailyNotification();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Favorites & preferences
  // ---------------------------------------------------------------------------
  Future<void> addFavorite(String city) async {
    if (!isFavorite(city)) {
      _favoriteCities.add(city);
      await _storageService.saveFavoriteCities(_favoriteCities);
    }
    final current = _currentWeather;
    if (current != null) {
      _favoritesWeather[current.location.name] = current;
    }
    notifyListeners();
  }

  Future<void> removeFavorite(String city) async {
    _favoriteCities.removeWhere((c) => c.toLowerCase() == city.toLowerCase());
    _favoritesWeather.removeWhere((key, _) => key.toLowerCase() == city.toLowerCase());
    await _storageService.saveFavoriteCities(_favoriteCities);

    final current = _currentWeather;
    final removedCurrent = current != null && current.location.name.toLowerCase() == city.toLowerCase();

    // Only switch away if the city being shown was the one removed (and it isn't the GPS city).
    final isGpsCity = _gpsWeather != null && _gpsWeather!.location.name.toLowerCase() == city.toLowerCase();
    if (removedCurrent && !isGpsCity) {
      if (_gpsWeather != null) {
        _userPickedCity = false;
        _usingGps = true;
        await _applyWeather(_gpsWeather!);
      } else if (_favoriteCities.isNotEmpty) {
        _activeCityIndex = 0;
        await loadWeatherForCity(_favoriteCities.first);
      } else {
        _currentWeather = null;
        _currentAlerts = [];
        _errorMessage = 'No favorite locations added. Search and add a city!';
      }
    }
    notifyListeners();
  }

  bool isFavorite(String cityName) {
    return _favoriteCities.any((c) => c.toLowerCase() == cityName.toLowerCase());
  }

  Future<void> toggleUnitSystem() async {
    _unitSystem = _unitSystem == 'metric' ? 'imperial' : 'metric';
    await _storageService.setUnitSystem(_unitSystem);
    notifyListeners();
    await syncDailyNotification();
  }

  Future<void> setThemeMode(String mode) async {
    _themeMode = mode;
    await _storageService.setThemeMode(mode);
    notifyListeners();
  }

  void setActiveCityIndex(int index) {
    if (index >= 0 && index < _favoriteCities.length) {
      _activeCityIndex = index;
      final cityName = _favoriteCities[index];
      if (_favoritesWeather.containsKey(cityName)) {
        _userPickedCity = true;
        _usingGps = false;
        _currentWeather = _favoritesWeather[cityName];
        _currentAlerts =
            SmartAlertService.combine(_currentWeather!, includeSmart: _alertsEnabled);
      } else {
        loadWeatherForCity(cityName);
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _serviceSub?.cancel();
    super.dispose();
  }
}
