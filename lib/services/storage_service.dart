import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyFavorites = 'favorite_cities';
  static const String _keyUnit = 'unit_system'; // 'metric' or 'imperial'
  static const String _keyTheme = 'theme_mode'; // 'system', 'dark', 'light'
  static const String _keyCustomApiKey = 'custom_api_key';
  static const String _keyDailyNotifEnabled = 'daily_notif_enabled';
  static const String _keyDailyNotifHour = 'daily_notif_hour';
  static const String _keyDailyNotifMinute = 'daily_notif_minute';
  static const String _keyProcessedAlerts = 'processed_alert_ids';

  Future<List<String>> getFavoriteCities() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyFavorites) ?? ['London', 'New York', 'Tokyo'];
  }

  Future<void> saveFavoriteCities(List<String> cities) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyFavorites, cities);
  }

  Future<void> addFavoriteCity(String city) async {
    final cities = await getFavoriteCities();
    if (!cities.contains(city)) {
      cities.add(city);
      await saveFavoriteCities(cities);
    }
  }

  Future<void> removeFavoriteCity(String city) async {
    final cities = await getFavoriteCities();
    cities.removeWhere((c) => c.toLowerCase() == city.toLowerCase());
    await saveFavoriteCities(cities);
  }

  Future<String> getUnitSystem() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUnit) ?? 'metric';
  }

  Future<void> setUnitSystem(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUnit, unit);
  }

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTheme) ?? 'system';
  }

  Future<void> setThemeMode(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, theme);
  }

  Future<String?> getCustomApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCustomApiKey);
  }

  Future<void> setCustomApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomApiKey, key);
  }

  Future<bool> getDailyNotifEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDailyNotifEnabled) ?? true;
  }

  Future<void> setDailyNotifEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDailyNotifEnabled, enabled);
  }

  Future<int> getDailyNotifHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDailyNotifHour) ?? 8;
  }

  Future<int> getDailyNotifMinute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDailyNotifMinute) ?? 0;
  }

  Future<void> setDailyNotifTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailyNotifHour, hour);
    await prefs.setInt(_keyDailyNotifMinute, minute);
  }

  Future<List<String>> getProcessedAlertIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyProcessedAlerts) ?? [];
  }

  Future<void> saveProcessedAlertIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyProcessedAlerts, ids);
  }
}
