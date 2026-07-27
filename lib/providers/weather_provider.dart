import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/ai_insight_service.dart';
import '../services/widget_service.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final AiInsightService _aiInsightService = AiInsightService();

  WeatherData? _weatherData;
  bool _isLoading = false;
  bool _isOffline = false;
  String? _errorMessage;
  String _aiVibe = '';
  DateTime? _lastFetchTime;
  String _currentCity = 'London';
  bool _isMetric = true;
  String _selectedLanguage = 'English';

  static const String _cachedWeatherKeyPrefix = 'cached_weather_';
  static const String _lastCityKey = 'last_selected_city';
  static const String _lastFetchTimeKey = 'last_fetch_time';

  WeatherData? get weatherData => _weatherData;
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  String? get errorMessage => _errorMessage;
  String get aiVibe => _aiVibe;
  DateTime? get lastFetchTime => _lastFetchTime;
  String get currentCity => _currentCity;
  bool get isMetric => _isMetric;
  String get selectedLanguage => _selectedLanguage;

  Future<void> initializeSettingsAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    _currentCity = prefs.getString(_lastCityKey) ?? 'London';
    _isMetric = prefs.getBool('is_metric') ?? true;
    _selectedLanguage = prefs.getString('language') ?? 'English';

    // Load from local persistent cache first
    await _loadFromPersistentCache(_currentCity);

    // Fetch fresh weather data from API
    await fetchWeather(_currentCity);
  }

  Future<void> setUnitPreference(bool metric) async {
    _isMetric = metric;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_metric', metric);
    if (_weatherData != null) {
      WidgetService.updateHomeWidget(_weatherData!, isMetric: _isMetric);
    }
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _selectedLanguage = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    if (_weatherData != null) {
      _generateAiVibe();
    }
    notifyListeners();
  }

  Future<void> fetchWeather(String cityName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rawJsonMap = await _weatherService.fetchRawWeatherJson(cityName);
      _weatherData = WeatherData.fromJson(rawJsonMap);
      _currentCity = _weatherData!.location.name;
      _isOffline = false;
      _lastFetchTime = DateTime.now();

      await _saveToPersistentCache(_currentCity, rawJsonMap);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastCityKey, _currentCity);
      await prefs.setString(_lastFetchTimeKey, _lastFetchTime!.toIso8601String());

      WidgetService.updateHomeWidget(_weatherData!, isMetric: _isMetric);
      _generateAiVibe();
    } catch (e) {
      debugPrint('Network error: $e. Loading from cache...');
      final cacheLoaded = await _loadFromPersistentCache(cityName);
      if (cacheLoaded) {
        _isOffline = true;
        _errorMessage = null;
      } else {
        _isOffline = true;
        _errorMessage = 'No internet connection and no cached weather data found.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveToPersistentCache(String city, Map<String, dynamic> jsonMap) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachedWeatherKeyPrefix${city.toLowerCase().trim()}';
      final jsonString = jsonEncode(jsonMap);
      await prefs.setString(cacheKey, jsonString);
      await prefs.setString('last_cached_weather_json', jsonString);
    } catch (e) {
      debugPrint('Failed to write weather cache: $e');
    }
  }

  Future<bool> _loadFromPersistentCache(String city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachedWeatherKeyPrefix${city.toLowerCase().trim()}';
      String? cachedJson = prefs.getString(cacheKey) ?? prefs.getString('last_cached_weather_json');

      if (cachedJson != null && cachedJson.isNotEmpty) {
        final decodedMap = jsonDecode(cachedJson) as Map<String, dynamic>;
        _weatherData = WeatherData.fromJson(decodedMap);
        _isOffline = true;

        final savedTimeStr = prefs.getString(_lastFetchTimeKey);
        if (savedTimeStr != null) {
          _lastFetchTime = DateTime.tryParse(savedTimeStr);
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Failed to read weather cache: $e');
    }
    return false;
  }

  Future<void> _generateAiVibe() async {
    if (_weatherData == null) return;
    try {
      _aiVibe = await _aiInsightService.generateDailyVibe(_weatherData!, _selectedLanguage);
      notifyListeners();
    } catch (_) {}
  }
}
