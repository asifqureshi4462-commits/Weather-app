import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_model.dart';
import 'storage_service.dart';

class WeatherService {
  static const String _host = 'api.weatherapi.com';
  final StorageService _storage = StorageService();

  /// Key from Settings (custom override) first, then .env / GitHub secret.
  Future<String> _resolveApiKey() async {
    try {
      final custom = (await _storage.getCustomApiKey())?.trim() ?? '';
      if (custom.isNotEmpty) return custom;
    } catch (_) {}

    String? key;
    try {
      key = dotenv.env['WEATHER_API_KEY'];
    } catch (_) {
      key = null;
    }
    if (key == null || key.trim().isEmpty || key.trim() == 'your_weatherapi_key_here') {
      return '';
    }
    return key.trim();
  }

  String _extractError(String body, String fallback) {
    try {
      final decoded = json.decode(body);
      final msg = decoded['error']?['message'];
      if (msg != null && msg.toString().isNotEmpty) return msg.toString();
    } catch (_) {}
    return fallback;
  }

  Future<WeatherData> fetchWeather(String query) async {
    final key = await _resolveApiKey();
    if (key.isEmpty) {
      throw Exception(
          'API Key is missing. Add your WeatherAPI.com key in Settings > API Key Override, or set WEATHER_API_KEY in GitHub Secrets.');
    }

    final uri = Uri.https(_host, '/v1/forecast.json', {
      'key': key,
      'q': query,
      'days': '7',
      'aqi': 'yes',
      'alerts': 'yes',
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data as Map<String, dynamic>);
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        throw Exception(_extractError(response.body, 'Location not found.'));
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(_extractError(response.body,
            'Invalid or expired API key. Please check your WeatherAPI.com API key.'));
      } else {
        throw Exception('Failed to load weather data (Status Code: ${response.statusCode}).');
      }
    } on TimeoutException {
      throw Exception('The weather server took too long to respond. Please try again.');
    } on SocketException {
      throw Exception('No Internet connection. Please check your network and try again.');
    } on http.ClientException catch (e) {
      final text = e.message.toLowerCase();
      if (text.contains('socket') || text.contains('host lookup') || text.contains('network')) {
        throw Exception('No Internet connection. Please check your network and try again.');
      }
      throw Exception('Network connection failed while connecting to weather service.');
    } on FormatException {
      throw Exception('Received invalid format response from weather server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<List<Map<String, String>>> searchCities(String query) async {
    final key = await _resolveApiKey();
    if (key.isEmpty || query.trim().length < 2) {
      return [];
    }

    final uri = Uri.https(_host, '/v1/search.json', {'key': key, 'q': query.trim()});

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body) as List<dynamic>;
        return list.map((item) {
          final name = item['name']?.toString() ?? '';
          final region = item['region']?.toString() ?? '';
          final country = item['country']?.toString() ?? '';
          final lat = item['lat']?.toString() ?? '';
          final lon = item['lon']?.toString() ?? '';

          String fullName = name;
          if (region.isNotEmpty) fullName += ', $region';
          if (country.isNotEmpty) fullName += ', $country';

          return <String, String>{
            'name': name,
            'fullName': fullName,
            'query': name,
            'lat': lat,
            'lon': lon,
          };
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
