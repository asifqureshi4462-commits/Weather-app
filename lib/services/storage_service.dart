import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyFavorites = 'favorite_cities';
  static const String _keyUnit = 'unit_system'; // 'metric' or 'imperial'
  static const String _keyTheme = 'theme_mode'; // 'system', 'dark', 'light'
  static const String _keyCustomApiKey = 'custom_api_key';

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
}
