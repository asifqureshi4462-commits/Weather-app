import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_model.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.weatherapi.com/v1';

  String get _apiKey {
    final key = dotenv.env['WEATHER_API_KEY'];
    if (key == null || key.isEmpty || key == 'your_weatherapi_key_here') {
      return '';
    }
    return key;
  }

  Future<WeatherData> fetchWeather(String query) async {
    final key = _apiKey;
    if (key.isEmpty) {
      throw Exception('API Key is missing. Please configure WEATHER_API_KEY in your .env or GitHub Secrets.');
    }

    final url = Uri.parse('$_baseUrl/forecast.json?key=$key&q=$query&days=7&aqi=yes&alerts=yes');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        final errorJson = json.decode(response.body);
        final msg = errorJson['error']?['message'] ?? 'Location not found.';
        throw Exception(msg);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Invalid API Key provided. Please check your WeatherAPI.com API key.');
      } else {
        throw Exception('Failed to load weather data (Status Code: ${response.statusCode}).');
      }
    } on SocketException {
      throw Exception('No Internet connection. Please check your network and try again.');
    } on http.ClientException {
      throw Exception('Network connection failed while connecting to weather service.');
    } on FormatException {
      throw Exception('Received invalid format response from weather server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<List<Map<String, String>>> searchCities(String query) async {
    final key = _apiKey;
    if (key.isEmpty || query.trim().length < 2) {
      return [];
    }

    final url = Uri.parse('$_baseUrl/search.json?key=$key&q=${Uri.encodeComponent(query)}');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((item) {
          final name = item['name']?.toString() ?? '';
          final region = item['region']?.toString() ?? '';
          final country = item['country']?.toString() ?? '';
          final lat = item['lat']?.toString() ?? '';
          final lon = item['lon']?.toString() ?? '';

          String fullName = name;
          if (region.isNotEmpty) fullName += ', $region';
          if (country.isNotEmpty) fullName += ', $country';

          return {
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
