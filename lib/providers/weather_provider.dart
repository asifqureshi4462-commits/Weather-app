import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();

  WeatherData? _currentWeather;
  Map<String, WeatherData> _favoritesWeather = {};
  List<String> _favoriteCities = [];
  int _activeCityIndex = 0;

  bool _isLoading = false;
  String? _errorMessage;

  String _unitSystem = 'metric'; // 'metric' (°C, km/h) or 'imperial' (°F, mph)
  String _themeMode = 'system'; // 'system', 'dark', 'light'

  WeatherData? get currentWeather => _currentWeather;
  Map<String, WeatherData> get favoritesWeather => _favoritesWeather;
  List<String> get favoriteCities => _favoriteCities;
  int get activeCityIndex => _activeCityIndex;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get unitSystem => _unitSystem;
  bool get isMetric => _unitSystem == 'metric';
  String get themeMode => _themeMode;

  bool _dailyNotifEnabled = true;
  int _dailyNotifHour = 8;
  int _dailyNotifMinute = 0;

  bool get dailyNotifEnabled => _dailyNotifEnabled;
  int get dailyNotifHour => _dailyNotifHour;
  int get dailyNotifMinute => _dailyNotifMinute;

  WeatherProvider() {
    init();
  }

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

      // Try GPS location first, fallback to first favorite city or London
      try {
        await loadWeatherByLocation();
      } catch (_) {
        if (_favoriteCities.isNotEmpty) {
          await loadWeatherForCity(_favoriteCities.first);
        } else {
          await loadWeatherForCity('London');
        }
      }

      await refreshAllFavorites();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWeatherForCity(String city) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _weatherService.fetchWeather(city);
      _currentWeather = data;
      _favoritesWeather[data.location.name] = data;

      final existingIdx = _favoriteCities.indexWhere(
          (c) => c.toLowerCase() == data.location.name.toLowerCase());
      if (existingIdx != -1) {
        _activeCityIndex = existingIdx;
      }

      await _processSevereAlerts(data);
      await syncDailyNotification();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _processSevereAlerts(WeatherData data) async {
    if (data.alerts.isEmpty) return;

    try {
      final processedIds = await _storageService.getProcessedAlertIds();
      List<String> updatedIds = List.from(processedIds);

      for (var alert in data.alerts) {
        if (!processedIds.contains(alert.id)) {
          updatedIds.add(alert.id);
          await _notificationService.showImmediateNotification(
            title: '⚠️ Weather Alert: ${alert.event}',
            body: alert.headline,
          );
        }
      }

      if (updatedIds.length != processedIds.length) {
        await _storageService.saveProcessedAlertIds(updatedIds);
      }
    } catch (e) {
      debugPrint('Error processing weather alerts: $e');
    }
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

    final rainChanceText = rainChance > 0
        ? '$rainChance% rain chance'
        : 'Low rain chance';

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

  Future<void> loadWeatherByLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pos = await _locationService.getCurrentPosition();
      if (pos == null) {
        throw Exception('Could not determine GPS coordinates.');
      }

      final query = '${pos.latitude},${pos.longitude}';
      final data = await _weatherService.fetchWeather(query);
      _currentWeather = data;
      _favoritesWeather[data.location.name] = data;

      // Ensure city is in favorites or at top
      if (!_favoriteCities.contains(data.location.name)) {
        _favoriteCities.insert(0, data.location.name);
        await _storageService.saveFavoriteCities(_favoriteCities);
      }
      _activeCityIndex = _favoriteCities.indexOf(data.location.name);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAllFavorites() async {
    for (String city in _favoriteCities) {
      try {
        final data = await _weatherService.fetchWeather(city);
        _favoritesWeather[data.location.name] = data;
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> addFavorite(String city) async {
    if (!_favoriteCities.contains(city)) {
      _favoriteCities.add(city);
      await _storageService.saveFavoriteCities(_favoriteCities);
      await loadWeatherForCity(city);
    }
  }

  Future<void> removeFavorite(String city) async {
    _favoriteCities.removeWhere((c) => c.toLowerCase() == city.toLowerCase());
    _favoritesWeather.remove(city);
    await _storageService.saveFavoriteCities(_favoriteCities);

    if (_favoriteCities.isNotEmpty) {
      _activeCityIndex = 0;
      await loadWeatherForCity(_favoriteCities.first);
    } else {
      _currentWeather = null;
      _errorMessage = 'No favorite locations added. Search and add a city!';
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
        _currentWeather = _favoritesWeather[cityName];
      } else {
        loadWeatherForCity(cityName);
      }
      notifyListeners();
    }
  }
}
