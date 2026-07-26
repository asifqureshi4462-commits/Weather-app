import React, { useState, useEffect } from 'react';
import JSZip from 'jszip';
import {
  Cloud,
  Sun,
  CloudRain,
  CloudSnow,
  CloudLightning,
  Wind,
  Droplets,
  Eye,
  Compass,
  Gauge,
  Thermometer,
  Search,
  Bookmark,
  Settings as SettingsIcon,
  MapPin,
  RefreshCw,
  Download,
  Copy,
  Check,
  Code,
  Smartphone,
  Github,
  ChevronRight,
  Sparkles,
  Info,
  ShieldCheck,
  Terminal,
  FileCode,
  FolderTree,
  ExternalLink,
  ChevronDown
} from 'lucide-react';

// Code files dictionary mapping file path to content for easy download/preview
const FLUTTER_FILES: Record<string, string> = {
  'pubspec.yaml': `name: atmosphere_weather
description: "A feature-rich Flutter Weather application with GitHub Actions CI/CD pipeline for automated APK builds."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.1
  provider: ^6.1.2
  shared_preferences: ^2.2.3
  geolocator: ^11.0.0
  permission_handler: ^11.3.1
  flutter_dotenv: ^5.1.0
  intl: ^0.19.0
  flutter_local_notifications: ^17.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - .env`,

  '.env.example': `WEATHER_API_KEY=your_weatherapi_key_here`,

  '.gitignore': `# Miscellaneous
*.class
*.log
.DS_Store

# Flutter / Dart
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/

# Secrets
.env
*.key
*.keystore`,

  '.github/workflows/build_apk.yml': `name: Build & Release Flutter Android APK

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  build:
    name: Build Release APK
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Setup Java JDK
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Setup Flutter SDK
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true

      - name: Inject .env File from GitHub Secrets
        run: |
          echo "WEATHER_API_KEY=\${{ secrets.WEATHER_API_KEY }}" > .env
          echo "Created .env configuration file."

      - name: Install Dependencies
        run: flutter pub get

      - name: Build Release APK
        run: flutter build apk --release

      - name: Upload APK Artifact
        uses: actions/upload-artifact@v4
        with:
          name: Atmosphere-Weather-v1.0.\${{ github.run_number }}.apk
          path: build/app/outputs/flutter-apk/app-release.apk

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        if: github.ref == 'refs/heads/main'
        with:
          tag_name: v1.0.\${{ github.run_number }}
          name: Release v1.0.\${{ github.run_number }}
          body: |
            ## Atmosphere Weather Android APK Release
            - Automated GitHub Actions build for run #\${{ github.run_number }}
            - Built with Flutter Stable SDK & Java 17
          files: build/app/outputs/flutter-apk/app-release.apk
        env:
          GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}`,

  'android/app/src/main/AndroidManifest.xml': `<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.atmosphere_weather">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <application
        android:label="Atmosphere Weather"
        android:name="\${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>`,

  'lib/main.dart': `import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/weather_provider.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  runApp(
    ChangeNotifierProvider(
      create: (_) => WeatherProvider(),
      child: const AtmosphereApp(),
    ),
  );
}

class AtmosphereApp extends StatelessWidget {
  const AtmosphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'Atmosphere Weather',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}`,

  'lib/screens/splash_screen.dart': `import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 40),
              Column(
                children: [
                  Image.asset('assets/app_logo.png', width: 140, height: 140),
                  const SizedBox(height: 24),
                  const Text('Atmosphere Weather', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  const Text('Live Forecast & Severe Weather Radar', style: TextStyle(color: Colors.white70)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.bottom(24.0),
                child: Text('Developed by Asif Qureshi', style: TextStyle(color: Colors.white90, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}`,

  'lib/models/weather_model.dart': `import 'package:flutter/foundation.dart';

class LocationData {
  final String name;
  final String region;
  final String country;
  final double lat;
  final double lon;
  final String localtime;

  LocationData({
    required this.name,
    required this.region,
    required this.country,
    required this.lat,
    required this.lon,
    required this.localtime,
  });

  factory LocationData.fromJson(Map<String, dynamic>? json) {
    return LocationData(
      name: json?['name']?.toString() ?? 'Unknown City',
      region: json?['region']?.toString() ?? '',
      country: json?['country']?.toString() ?? '',
      lat: (json?['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json?['lon'] as num?)?.toDouble() ?? 0.0,
      localtime: json?['localtime']?.toString() ?? '',
    );
  }
}

class CurrentWeather {
  final double tempC;
  final double tempF;
  final double feelsLikeC;
  final double feelsLikeF;
  final String conditionText;
  final String conditionIcon;
  final int conditionCode;
  final int humidity;
  final double windKph;
  final double windMph;
  final int windDegree;
  final String windDir;
  final double uvIndex;
  final double aqiPm25;
  final double aqiPm10;
  final int aqiEpaIndex;
  final double pressureMb;
  final double pressureIn;
  final double visibilityKm;
  final double visibilityMiles;
  final bool isDay;

  CurrentWeather({
    required this.tempC,
    required this.tempF,
    required this.feelsLikeC,
    required this.feelsLikeF,
    required this.conditionText,
    required this.conditionIcon,
    required this.conditionCode,
    required this.humidity,
    required this.windKph,
    required this.windMph,
    required this.windDegree,
    required this.windDir,
    required this.uvIndex,
    required this.aqiPm25,
    required this.aqiPm10,
    required this.aqiEpaIndex,
    required this.pressureMb,
    required this.pressureIn,
    required this.visibilityKm,
    required this.visibilityMiles,
    required this.isDay,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic>? json) {
    final cond = json?['condition'] as Map<String, dynamic>?;
    final aqi = json?['air_quality'] as Map<String, dynamic>?;

    return CurrentWeather(
      tempC: (json?['temp_c'] as num?)?.toDouble() ?? 0.0,
      tempF: (json?['temp_f'] as num?)?.toDouble() ?? 32.0,
      feelsLikeC: (json?['feelslike_c'] as num?)?.toDouble() ?? 0.0,
      feelsLikeF: (json?['feelslike_f'] as num?)?.toDouble() ?? 32.0,
      conditionText: cond?['text']?.toString() ?? 'Clear',
      conditionIcon: cond?['icon']?.toString() ?? '',
      conditionCode: (cond?['code'] as num?)?.toInt() ?? 1000,
      humidity: (json?['humidity'] as num?)?.toInt() ?? 0,
      windKph: (json?['wind_kph'] as num?)?.toDouble() ?? 0.0,
      windMph: (json?['wind_mph'] as num?)?.toDouble() ?? 0.0,
      windDegree: (json?['wind_degree'] as num?)?.toInt() ?? 0,
      windDir: json?['wind_dir']?.toString() ?? 'N',
      uvIndex: (json?['uv'] as num?)?.toDouble() ?? 0.0,
      aqiPm25: (aqi?['pm2_5'] as num?)?.toDouble() ?? 0.0,
      aqiPm10: (aqi?['pm10'] as num?)?.toDouble() ?? 0.0,
      aqiEpaIndex: (aqi?['us-epa-index'] as num?)?.toInt() ?? 1,
      pressureMb: (json?['pressure_mb'] as num?)?.toDouble() ?? 1013.0,
      pressureIn: (json?['pressure_in'] as num?)?.toDouble() ?? 29.92,
      visibilityKm: (json?['vis_km'] as num?)?.toDouble() ?? 10.0,
      visibilityMiles: (json?['vis_miles'] as num?)?.toDouble() ?? 6.2,
      isDay: ((json?['is_day'] as num?)?.toInt() ?? 1) == 1,
    );
  }
}

class HourlyForecast {
  final String time;
  final double tempC;
  final double tempF;
  final String conditionText;
  final String conditionIcon;
  final int chanceOfRain;
  final double rainMm;
  final bool isDay;

  HourlyForecast({
    required this.time,
    required this.tempC,
    required this.tempF,
    required this.conditionText,
    required this.conditionIcon,
    required this.chanceOfRain,
    required this.rainMm,
    required this.isDay,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    final cond = json['condition'] as Map<String, dynamic>?;
    return HourlyForecast(
      time: json['time']?.toString() ?? '',
      tempC: (json['temp_c'] as num?)?.toDouble() ?? 0.0,
      tempF: (json['temp_f'] as num?)?.toDouble() ?? 32.0,
      conditionText: cond?['text']?.toString() ?? 'Clear',
      conditionIcon: cond?['icon']?.toString() ?? '',
      chanceOfRain: (json['chance_of_rain'] as num?)?.toInt() ?? 0,
      rainMm: (json['precip_mm'] as num?)?.toDouble() ?? 0.0,
      isDay: ((json['is_day'] as num?)?.toInt() ?? 1) == 1,
    );
  }
}

class DailyForecast {
  final String date;
  final double maxTempC;
  final double maxTempF;
  final double minTempC;
  final double minTempF;
  final double avgTempC;
  final double avgTempF;
  final String conditionText;
  final String conditionIcon;
  final int chanceOfRain;
  final double totalRainMm;
  final double maxWindKph;
  final int avgHumidity;
  final double uvIndex;
  final String sunrise;
  final String sunset;

  DailyForecast({
    required this.date,
    required this.maxTempC,
    required this.maxTempF,
    required this.minTempC,
    required this.minTempF,
    required this.avgTempC,
    required this.avgTempF,
    required this.conditionText,
    required this.conditionIcon,
    required this.chanceOfRain,
    required this.totalRainMm,
    required this.maxWindKph,
    required this.avgHumidity,
    required this.uvIndex,
    required this.sunrise,
    required this.sunset,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    final day = json['day'] as Map<String, dynamic>?;
    final cond = day?['condition'] as Map<String, dynamic>?;
    final astro = json['astro'] as Map<String, dynamic>?;

    return DailyForecast(
      date: json['date']?.toString() ?? '',
      maxTempC: (day?['maxtemp_c'] as num?)?.toDouble() ?? 0.0,
      maxTempF: (day?['maxtemp_f'] as num?)?.toDouble() ?? 32.0,
      minTempC: (day?['mintemp_c'] as num?)?.toDouble() ?? 0.0,
      minTempF: (day?['mintemp_f'] as num?)?.toDouble() ?? 32.0,
      avgTempC: (day?['avgtemp_c'] as num?)?.toDouble() ?? 0.0,
      avgTempF: (day?['avgtemp_f'] as num?)?.toDouble() ?? 32.0,
      conditionText: cond?['text']?.toString() ?? 'Clear',
      conditionIcon: cond?['icon']?.toString() ?? '',
      chanceOfRain: (day?['daily_chance_of_rain'] as num?)?.toInt() ?? 0,
      totalRainMm: (day?['totalprecip_mm'] as num?)?.toDouble() ?? 0.0,
      maxWindKph: (day?['maxwind_kph'] as num?)?.toDouble() ?? 0.0,
      avgHumidity: (day?['avghumidity'] as num?)?.toInt() ?? 0,
      uvIndex: (day?['uv'] as num?)?.toDouble() ?? 0.0,
      sunrise: astro?['sunrise']?.toString() ?? '06:00 AM',
      sunset: astro?['sunset']?.toString() ?? '06:30 PM',
    );
  }
}

class WeatherData {
  final LocationData location;
  final CurrentWeather current;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;

  WeatherData({
    required this.location,
    required this.current,
    required this.hourly,
    required this.daily,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final location = LocationData.fromJson(json['location'] as Map<String, dynamic>?);
    final current = CurrentWeather.fromJson(json['current'] as Map<String, dynamic>?);

    List<HourlyForecast> hourlyList = [];
    List<DailyForecast> dailyList = [];

    final forecastObj = json['forecast'] as Map<String, dynamic>?;
    final forecastDays = forecastObj?['forecastday'] as List<dynamic>?;

    if (forecastDays != null) {
      for (var dayJson in forecastDays) {
        if (dayJson is Map<String, dynamic>) {
          dailyList.add(DailyForecast.fromJson(dayJson));
          final hourArray = dayJson['hour'] as List<dynamic>?;
          if (hourArray != null) {
            for (var hourJson in hourArray) {
              if (hourJson is Map<String, dynamic>) {
                hourlyList.add(HourlyForecast.fromJson(hourJson));
              }
            }
          }
        }
      }
    }

    return WeatherData(
      location: location,
      current: current,
      hourly: hourlyList,
      daily: dailyList,
    );
  }
}`,

  'lib/services/weather_service.dart': `import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_model.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.weatherapi.com/v1';

  String get _apiKey => dotenv.env['WEATHER_API_KEY'] ?? '';

  Future<WeatherData> fetchWeather(String query) async {
    final key = _apiKey;
    if (key.isEmpty) {
      throw Exception('API Key is missing. Please set WEATHER_API_KEY in .env or GitHub Secrets.');
    }

    final url = Uri.parse('\$_baseUrl/forecast.json?key=\$key&q=\$query&days=7&aqi=yes&alerts=no');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        return WeatherData.fromJson(json.decode(response.body));
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        throw Exception('Location not found.');
      } else {
        throw Exception('Failed to load weather data (\${response.statusCode}).');
      }
    } on SocketException {
      throw Exception('No Internet connection. Check your network.');
    } catch (e) {
      throw Exception('Error loading weather: \$e');
    }
  }
}`
};

interface MockCityWeather {
  name: string;
  country: string;
  tempC: number;
  tempF: number;
  feelsLikeC: number;
  feelsLikeF: number;
  condition: string;
  humidity: number;
  windKph: number;
  windMph: number;
  windDir: string;
  uvIndex: number;
  aqiEpa: number;
  aqiPm25: number;
  pressureMb: number;
  visibilityKm: number;
  isDay: boolean;
  hourly: { time: string; tempC: number; tempF: number; condition: string; rainChance: number }[];
  daily: { day: string; condition: string; highC: number; lowC: number; highF: number; lowF: number; rainChance: number }[];
}

const MOCK_WEATHER_DATABASE: Record<string, MockCityWeather> = {
  London: {
    name: 'London',
    country: 'United Kingdom',
    tempC: 18,
    tempF: 64,
    feelsLikeC: 17,
    feelsLikeF: 63,
    condition: 'Partly Cloudy',
    humidity: 68,
    windKph: 14,
    windMph: 9,
    windDir: 'WSW',
    uvIndex: 4.2,
    aqiEpa: 1,
    aqiPm25: 8.4,
    pressureMb: 1018,
    visibilityKm: 10,
    isDay: true,
    hourly: [
      { time: 'Now', tempC: 18, tempF: 64, condition: 'Partly Cloudy', rainChance: 10 },
      { time: '2 PM', tempC: 19, tempF: 66, condition: 'Sunny', rainChance: 0 },
      { time: '3 PM', tempC: 20, tempF: 68, condition: 'Sunny', rainChance: 0 },
      { time: '4 PM', tempC: 19, tempF: 66, condition: 'Partly Cloudy', rainChance: 15 },
      { time: '5 PM', tempC: 18, tempF: 64, condition: 'Light Rain', rainChance: 45 },
      { time: '6 PM', tempC: 17, tempF: 63, condition: 'Cloudy', rainChance: 20 },
    ],
    daily: [
      { day: 'Today', condition: 'Partly Cloudy', highC: 20, lowC: 12, highF: 68, lowF: 54, rainChance: 15 },
      { day: 'Mon', condition: 'Light Rain', highC: 17, lowC: 11, highF: 63, lowF: 52, rainChance: 60 },
      { day: 'Tue', condition: 'Sunny', highC: 22, lowC: 13, highF: 72, lowF: 55, rainChance: 0 },
      { day: 'Wed', condition: 'Cloudy', highC: 19, lowC: 12, highF: 66, lowF: 54, rainChance: 10 },
      { day: 'Thu', condition: 'Thunderstorm', highC: 18, lowC: 14, highF: 64, lowF: 57, rainChance: 80 },
      { day: 'Fri', condition: 'Sunny', highC: 21, lowC: 13, highF: 70, lowF: 55, rainChance: 5 },
      { day: 'Sat', condition: 'Partly Cloudy', highC: 23, lowC: 15, highF: 73, lowF: 59, rainChance: 10 },
    ],
  },
  'New York': {
    name: 'New York',
    country: 'United States',
    tempC: 26,
    tempF: 79,
    feelsLikeC: 28,
    feelsLikeF: 82,
    condition: 'Sunny',
    humidity: 52,
    windKph: 18,
    windMph: 11,
    windDir: 'ENE',
    uvIndex: 7.5,
    aqiEpa: 2,
    aqiPm25: 14.1,
    pressureMb: 1014,
    visibilityKm: 10,
    isDay: true,
    hourly: [
      { time: 'Now', tempC: 26, tempF: 79, condition: 'Sunny', rainChance: 0 },
      { time: '2 PM', tempC: 28, tempF: 82, condition: 'Sunny', rainChance: 0 },
      { time: '3 PM', tempC: 29, tempF: 84, condition: 'Sunny', rainChance: 0 },
      { time: '4 PM', tempC: 28, tempF: 82, condition: 'Sunny', rainChance: 5 },
      { time: '5 PM', tempC: 27, tempF: 80, condition: 'Clear', rainChance: 5 },
    ],
    daily: [
      { day: 'Today', condition: 'Sunny', highC: 29, lowC: 20, highF: 84, lowF: 68, rainChance: 0 },
      { day: 'Mon', condition: 'Sunny', highC: 30, lowC: 21, highF: 86, lowF: 70, rainChance: 5 },
      { day: 'Tue', condition: 'Partly Cloudy', highC: 28, lowC: 19, highF: 82, lowF: 66, rainChance: 20 },
      { day: 'Wed', condition: 'Heavy Rain', highC: 24, lowC: 18, highF: 75, lowF: 64, rainChance: 90 },
      { day: 'Thu', condition: 'Clear', highC: 27, lowC: 19, highF: 80, lowF: 66, rainChance: 0 },
      { day: 'Fri', condition: 'Sunny', highC: 29, lowC: 20, highF: 84, lowF: 68, rainChance: 0 },
      { day: 'Sat', condition: 'Sunny', highC: 31, lowC: 22, highF: 88, lowF: 72, rainChance: 0 },
    ],
  },
  Tokyo: {
    name: 'Tokyo',
    country: 'Japan',
    tempC: 22,
    tempF: 72,
    feelsLikeC: 22,
    feelsLikeF: 72,
    condition: 'Light Rain',
    humidity: 82,
    windKph: 12,
    windMph: 7,
    windDir: 'SSE',
    uvIndex: 3.1,
    aqiEpa: 1,
    aqiPm25: 6.2,
    pressureMb: 1010,
    visibilityKm: 8,
    isDay: true,
    hourly: [
      { time: 'Now', tempC: 22, tempF: 72, condition: 'Light Rain', rainChance: 65 },
      { time: '2 PM', tempC: 23, tempF: 73, condition: 'Moderate Rain', rainChance: 80 },
      { time: '3 PM', tempC: 22, tempF: 72, condition: 'Light Rain', rainChance: 50 },
      { time: '4 PM', tempC: 21, tempF: 70, condition: 'Cloudy', rainChance: 30 },
    ],
    daily: [
      { day: 'Today', condition: 'Light Rain', highC: 23, lowC: 17, highF: 73, lowF: 63, rainChance: 70 },
      { day: 'Mon', condition: 'Cloudy', highC: 24, lowC: 18, highF: 75, lowF: 64, rainChance: 20 },
      { day: 'Tue', condition: 'Sunny', highC: 26, lowC: 19, highF: 79, lowF: 66, rainChance: 5 },
      { day: 'Wed', condition: 'Sunny', highC: 27, lowC: 20, highF: 80, lowF: 68, rainChance: 0 },
      { day: 'Thu', condition: 'Partly Cloudy', highC: 25, lowC: 19, highF: 77, lowF: 66, rainChance: 15 },
      { day: 'Fri', condition: 'Light Rain', highC: 22, lowC: 16, highF: 72, lowF: 60, rainChance: 55 },
      { day: 'Sat', condition: 'Sunny', highC: 25, lowC: 18, highF: 77, lowF: 64, rainChance: 0 },
    ],
  },
};

export default function App() {
  const [activeTab, setActiveTab] = useState<'preview' | 'code' | 'instructions'>('preview');
  const [selectedCity, setSelectedCity] = useState<string>('London');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [isMetric, setIsMetric] = useState<boolean>(true);
  const [favorites, setFavorites] = useState<string[]>(['London', 'New York', 'Tokyo']);
  const [activeFile, setActiveFile] = useState<string>('pubspec.yaml');
  const [copiedFile, setCopiedFile] = useState<boolean>(false);
  const [isZipping, setIsZipping] = useState<boolean>(false);

  const currentWeather = MOCK_WEATHER_DATABASE[selectedCity] || MOCK_WEATHER_DATABASE['London'];

  const handleCopyCode = () => {
    const content = FLUTTER_FILES[activeFile];
    if (content) {
      navigator.clipboard.writeText(content);
      setCopiedFile(true);
      setTimeout(() => setCopiedFile(false), 2000);
    }
  };

  const handleDownloadZip = async () => {
    setIsZipping(true);
    try {
      const zip = new JSZip();

      // Add all defined files
      Object.entries(FLUTTER_FILES).forEach(([path, content]) => {
        zip.file(path, content);
      });

      // Add README.md
      zip.file(
        'README.md',
        `# Atmosphere Weather App
Full Flutter Weather Application with GitHub Actions CI/CD workflow for automated APK releases.
Check .github/workflows/build_apk.yml for the Android build pipeline.`
      );

      const content = await zip.generateAsync({ type: 'blob' });
      const url = window.URL.createObjectURL(content);
      const link = document.createElement('a');
      link.href = url;
      link.download = 'atmosphere_weather_flutter_repo.zip';
      link.click();
      window.URL.revokeObjectURL(url);
    } catch (err) {
      console.error('Failed to create ZIP:', err);
    } finally {
      setIsZipping(false);
    }
  };

  const toggleFavorite = (cityName: string) => {
    if (favorites.includes(cityName)) {
      setFavorites(favorites.filter((c) => c !== cityName));
    } else {
      setFavorites([...favorites, cityName]);
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col font-sans">
      {/* Top Header */}
      <header className="border-b border-slate-800 bg-slate-900/80 backdrop-blur sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 py-3 flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-gradient-to-tr from-cyan-500 to-indigo-600 rounded-xl shadow-lg shadow-cyan-500/20">
              <Cloud className="w-6 h-6 text-white" />
            </div>
            <div>
              <h1 className="font-bold text-lg leading-tight flex items-center gap-2">
                Atmosphere Weather
                <span className="text-xs font-normal px-2 py-0.5 rounded-full bg-cyan-500/10 text-cyan-400 border border-cyan-500/20">
                  Flutter + Actions CI/CD
                </span>
              </h1>
              <p className="text-xs text-slate-400">Complete, production-ready source code repository & build pipeline</p>
            </div>
          </div>

          {/* Navigation Tabs */}
          <div className="flex items-center gap-1 bg-slate-800/80 p-1 rounded-xl border border-slate-700">
            <button
              onClick={() => setActiveTab('preview')}
              className={`flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs font-medium transition ${
                activeTab === 'preview'
                  ? 'bg-cyan-500 text-slate-950 shadow font-semibold'
                  : 'text-slate-300 hover:text-white'
              }`}
            >
              <Smartphone className="w-4 h-4" />
              Live Flutter UI Preview
            </button>
            <button
              onClick={() => setActiveTab('code')}
              className={`flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs font-medium transition ${
                activeTab === 'code'
                  ? 'bg-cyan-500 text-slate-950 shadow font-semibold'
                  : 'text-slate-300 hover:text-white'
              }`}
            >
              <Code className="w-4 h-4" />
              Flutter Code Explorer
            </button>
            <button
              onClick={() => setActiveTab('instructions')}
              className={`flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs font-medium transition ${
                activeTab === 'instructions'
                  ? 'bg-cyan-500 text-slate-950 shadow font-semibold'
                  : 'text-slate-300 hover:text-white'
              }`}
            >
              <Github className="w-4 h-4" />
              Build APK Guide (Phone Only)
            </button>
          </div>

          {/* ZIP Download Action */}
          <button
            onClick={handleDownloadZip}
            disabled={isZipping}
            className="flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-emerald-500 to-teal-600 hover:from-emerald-400 hover:to-teal-500 text-slate-950 font-bold text-xs rounded-xl shadow-lg transition active:scale-95 disabled:opacity-50"
          >
            <Download className="w-4 h-4" />
            {isZipping ? 'Bundling Zip...' : 'Download Repo (.ZIP)'}
          </button>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="flex-1 max-w-7xl w-full mx-auto p-4 md:p-6">
        {/* TAB 1: LIVE FLUTTER UI SIMULATOR */}
        {activeTab === 'preview' && (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
            {/* Phone Screen Mockup Frame */}
            <div className="lg:col-span-6 flex justify-center">
              <div className="w-full max-w-[390px] h-[780px] bg-slate-900 rounded-[40px] p-3 border-4 border-slate-700 shadow-2xl relative flex flex-col overflow-hidden">
                {/* Phone Notch */}
                <div className="absolute top-0 left-1/2 -translate-x-1/2 w-36 h-6 bg-slate-950 rounded-b-2xl z-30 flex items-center justify-center">
                  <div className="w-12 h-1 bg-slate-800 rounded-full"></div>
                </div>

                {/* Inner Mobile Screen Canvas */}
                <div className="w-full h-full rounded-[32px] overflow-hidden flex flex-col relative bg-gradient-to-b from-sky-700 via-indigo-900 to-slate-950 text-white pt-7">
                  {/* Flutter AppBar */}
                  <div className="px-4 py-2 flex items-center justify-between z-20">
                    <div className="flex items-center gap-2">
                      <div className="w-7 h-7 rounded-lg overflow-hidden border border-white/20 shadow-sm flex-shrink-0">
                        <img src="assets/app_logo.png" alt="Logo" className="w-full h-full object-cover" onError={(e) => { e.currentTarget.src = 'assets/splash_icon.png'; }} />
                      </div>
                      <span className="font-bold text-lg tracking-tight">Atmosphere</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => setIsMetric(!isMetric)}
                        className="px-2 py-0.5 bg-white/10 backdrop-blur rounded-full text-xs font-semibold hover:bg-white/20 transition"
                      >
                        {isMetric ? '°C' : '°F'}
                      </button>
                      <button
                        onClick={() => toggleFavorite(selectedCity)}
                        className="p-1.5 rounded-full bg-white/10 hover:bg-white/20 transition"
                      >
                        <Bookmark
                          className={`w-4 h-4 ${
                            favorites.includes(selectedCity) ? 'fill-red-400 text-red-400' : 'text-white'
                          }`}
                        />
                      </button>
                    </div>
                  </div>

                  {/* Search Bar */}
                  <div className="px-4 mb-3 z-20">
                    <div className="relative">
                      <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-300" />
                      <input
                        type="text"
                        placeholder="Search city (e.g. London, Tokyo)..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="w-full bg-black/30 backdrop-blur text-xs pl-9 pr-3 py-2 rounded-xl border border-white/10 focus:outline-none focus:border-cyan-400 text-white placeholder-slate-300"
                      />
                    </div>

                    {/* Search Suggestions Dropdown */}
                    {searchQuery.trim().length > 0 && (
                      <div className="mt-1 bg-slate-900/95 border border-slate-700 rounded-xl p-2 space-y-1 shadow-xl z-50">
                        {Object.keys(MOCK_WEATHER_DATABASE)
                          .filter((c) => c.toLowerCase().includes(searchQuery.toLowerCase()))
                          .map((city) => (
                            <button
                              key={city}
                              onClick={() => {
                                setSelectedCity(city);
                                setSearchQuery('');
                              }}
                              className="w-full text-left px-3 py-1.5 hover:bg-cyan-500/20 rounded-lg text-xs flex items-center justify-between"
                            >
                              <span>{city}</span>
                              <ChevronRight className="w-3 h-3 text-slate-400" />
                            </button>
                          ))}
                      </div>
                    )}
                  </div>

                  {/* Scrollable Mobile Body */}
                  <div className="flex-1 overflow-y-auto px-4 pb-6 space-y-4 text-xs scrollbar-thin scrollbar-thumb-slate-700">
                    {/* Hero Current Weather Card */}
                    <div className="p-5 rounded-2xl bg-black/30 backdrop-blur border border-white/15 flex flex-col items-center text-center shadow-lg">
                      <p className="text-base font-bold text-white">{currentWeather.name}</p>
                      <p className="text-[10px] text-cyan-200 mb-2">{currentWeather.country}</p>

                      <div className="flex items-center gap-2 my-2">
                        {currentWeather.condition.includes('Sunny') ? (
                          <Sun className="w-16 h-16 text-amber-400 animate-spin-slow" />
                        ) : currentWeather.condition.includes('Rain') ? (
                          <CloudRain className="w-16 h-16 text-cyan-300" />
                        ) : (
                          <Cloud className="w-16 h-16 text-slate-200" />
                        )}
                        <span className="text-5xl font-extralight tracking-tighter">
                          {isMetric ? `${currentWeather.tempC}°` : `${currentWeather.tempF}°`}
                        </span>
                      </div>

                      <p className="font-semibold text-sm">{currentWeather.condition}</p>
                      <p className="text-[11px] text-slate-300">
                        Feels like {isMetric ? `${currentWeather.feelsLikeC}°C` : `${currentWeather.feelsLikeF}°F`}
                      </p>
                    </div>

                    {/* Hourly Forecast Horizontal Scroll */}
                    <div className="space-y-1.5">
                      <p className="text-[10px] font-bold text-slate-300 uppercase tracking-wider flex items-center gap-1">
                        <Thermometer className="w-3 h-3 text-cyan-400" />
                        Hourly Forecast (24 hrs)
                      </p>
                      <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-none">
                        {currentWeather.hourly.map((h, idx) => (
                          <div
                            key={idx}
                            className="flex-shrink-0 w-16 p-2 rounded-xl bg-black/20 border border-white/10 flex flex-col items-center gap-1 text-center"
                          >
                            <span className="text-[10px] text-slate-300">{h.time}</span>
                            <Cloud className="w-4 h-4 text-cyan-200" />
                            {h.rainChance > 0 && (
                              <span className="text-[9px] text-cyan-400 font-bold">{h.rainChance}%</span>
                            )}
                            <span className="font-bold text-xs">
                              {isMetric ? `${h.tempC}°` : `${h.tempF}°`}
                            </span>
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* 7-Day Forecast */}
                    <div className="p-3 rounded-xl bg-black/20 border border-white/10 space-y-2">
                      <p className="text-[10px] font-bold text-slate-300 uppercase tracking-wider flex items-center gap-1">
                        <Cloud className="w-3 h-3 text-cyan-400" />
                        7-Day Forecast
                      </p>
                      <div className="space-y-1.5">
                        {currentWeather.daily.map((d, idx) => (
                          <div key={idx} className="flex items-center justify-between text-[11px] border-b border-white/5 pb-1">
                            <span className="w-12 font-medium">{d.day}</span>
                            <div className="flex items-center gap-1 flex-1 px-2">
                              <Cloud className="w-3.5 h-3.5 text-cyan-300" />
                              <span className="text-[10px] text-slate-300 truncate max-w-[80px]">{d.condition}</span>
                            </div>
                            <div className="flex items-center gap-2 font-semibold">
                              <span>{isMetric ? `${d.highC}°` : `${d.highF}°`}</span>
                              <span className="text-slate-400 font-normal">
                                {isMetric ? `${d.lowC}°` : `${d.lowF}°`}
                              </span>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* Atmospheric Details Grid */}
                    <div className="grid grid-cols-2 gap-2">
                      <div className="p-2.5 rounded-xl bg-black/20 border border-white/10 flex flex-col justify-between">
                        <div className="flex items-center gap-1.5 text-slate-300">
                          <Droplets className="w-3.5 h-3.5 text-cyan-400" />
                          <span className="text-[10px] font-bold">HUMIDITY</span>
                        </div>
                        <span className="text-base font-bold my-1">{currentWeather.humidity}%</span>
                        <span className="text-[9px] text-slate-400">Dew point comfortable</span>
                      </div>

                      <div className="p-2.5 rounded-xl bg-black/20 border border-white/10 flex flex-col justify-between">
                        <div className="flex items-center gap-1.5 text-slate-300">
                          <Wind className="w-3.5 h-3.5 text-cyan-400" />
                          <span className="text-[10px] font-bold">WIND</span>
                        </div>
                        <span className="text-base font-bold my-1">
                          {isMetric ? `${currentWeather.windKph} km/h` : `${currentWeather.windMph} mph`}
                        </span>
                        <span className="text-[9px] text-slate-400">Dir: {currentWeather.windDir}</span>
                      </div>

                      <div className="p-2.5 rounded-xl bg-black/20 border border-white/10 flex flex-col justify-between">
                        <div className="flex items-center gap-1.5 text-slate-300">
                          <Sun className="w-3.5 h-3.5 text-amber-400" />
                          <span className="text-[10px] font-bold">UV INDEX</span>
                        </div>
                        <span className="text-base font-bold my-1">{currentWeather.uvIndex}</span>
                        <span className="text-[9px] text-slate-400">Moderate level</span>
                      </div>

                      <div className="p-2.5 rounded-xl bg-black/20 border border-white/10 flex flex-col justify-between">
                        <div className="flex items-center gap-1.5 text-slate-300">
                          <Gauge className="w-3.5 h-3.5 text-cyan-400" />
                          <span className="text-[10px] font-bold">AIR QUALITY</span>
                        </div>
                        <span className="text-base font-bold my-1">AQI {currentWeather.aqiEpa}</span>
                        <span className="text-[9px] text-slate-400">PM2.5: {currentWeather.aqiPm25}</span>
                      </div>
                    </div>

                    {/* Developer Branding Footer */}
                    <div className="pt-3 pb-2 text-center border-t border-white/10">
                      <p className="text-[11px] font-semibold text-cyan-200 tracking-wide">
                        Developed by Asif Qureshi
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Side Controls & Feature Breakdown */}
            <div className="lg:col-span-6 space-y-6">
              <div className="bg-slate-900 border border-slate-800 rounded-2xl p-5 space-y-4">
                <h2 className="text-base font-bold text-white flex items-center gap-2">
                  <Sparkles className="w-5 h-5 text-cyan-400" />
                  Interactive Preview Controls
                </h2>
                <p className="text-xs text-slate-400 leading-relaxed">
                  Select sample locations or toggle temperature units to test the responsive UI states modeled directly after the Flutter app code.
                </p>

                <div className="flex flex-wrap gap-2">
                  {Object.keys(MOCK_WEATHER_DATABASE).map((city) => (
                    <button
                      key={city}
                      onClick={() => setSelectedCity(city)}
                      className={`px-3 py-1.5 rounded-xl text-xs font-medium border transition ${
                        selectedCity === city
                          ? 'bg-cyan-500 text-slate-950 font-bold border-cyan-400 shadow-md'
                          : 'bg-slate-800 text-slate-300 border-slate-700 hover:border-slate-600'
                      }`}
                    >
                      {city}
                    </button>
                  ))}
                </div>

                <div className="pt-2 border-t border-slate-800 flex items-center justify-between text-xs">
                  <span className="text-slate-400">Unit Preference:</span>
                  <button
                    onClick={() => setIsMetric(!isMetric)}
                    className="px-3 py-1 bg-slate-800 hover:bg-slate-700 text-cyan-400 font-semibold rounded-lg border border-slate-700"
                  >
                    {isMetric ? 'Metric (°C, km/h)' : 'Imperial (°F, mph)'}
                  </button>
                </div>
              </div>

              {/* Technical Features Highlights */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-4 space-y-2">
                  <div className="p-2 bg-cyan-500/10 text-cyan-400 rounded-lg w-fit">
                    <ShieldCheck className="w-5 h-5" />
                  </div>
                  <h3 className="text-sm font-bold text-white">Full Null-Safety & Error Defense</h3>
                  <p className="text-xs text-slate-400">
                    Comprehensive JSON parsing fallback checks so the app never throws runtime exceptions even on missing network or API fields.
                  </p>
                </div>

                <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-4 space-y-2">
                  <div className="p-2 bg-indigo-500/10 text-indigo-400 rounded-lg w-fit">
                    <Terminal className="w-5 h-5" />
                  </div>
                  <h3 className="text-sm font-bold text-white">GitHub Actions CI/CD Pipeline</h3>
                  <p className="text-xs text-slate-400">
                    Fully automated workflow builds release APKs directly on GitHub servers and creates tagged GitHub Releases upon push.
                  </p>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* TAB 2: FLUTTER CODE EXPLORER */}
        {activeTab === 'code' && (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
            {/* File Tree Sidebar */}
            <div className="lg:col-span-4 bg-slate-900 border border-slate-800 rounded-2xl p-4 space-y-3">
              <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 flex items-center gap-2">
                <FolderTree className="w-4 h-4 text-cyan-400" />
                Repository File Tree
              </h3>
              <div className="space-y-1 text-xs">
                {Object.keys(FLUTTER_FILES).map((filePath) => (
                  <button
                    key={filePath}
                    onClick={() => setActiveFile(filePath)}
                    className={`w-full text-left px-3 py-2 rounded-xl transition flex items-center justify-between font-mono ${
                      activeFile === filePath
                        ? 'bg-cyan-500/20 text-cyan-300 border border-cyan-500/30 font-semibold'
                        : 'text-slate-400 hover:bg-slate-800 hover:text-slate-200'
                    }`}
                  >
                    <span className="truncate">{filePath}</span>
                    <FileCode className="w-3.5 h-3.5 flex-shrink-0 ml-2" />
                  </button>
                ))}
              </div>
            </div>

            {/* Code View Canvas */}
            <div className="lg:col-span-8 bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden flex flex-col">
              <div className="bg-slate-950 px-4 py-3 border-b border-slate-800 flex items-center justify-between">
                <span className="font-mono text-xs text-cyan-400">{activeFile}</span>
                <button
                  onClick={handleCopyCode}
                  className="flex items-center gap-1.5 px-3 py-1 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-medium rounded-lg border border-slate-700 transition"
                >
                  {copiedFile ? (
                    <>
                      <Check className="w-3.5 h-3.5 text-emerald-400" />
                      Copied!
                    </>
                  ) : (
                    <>
                      <Copy className="w-3.5 h-3.5 text-slate-400" />
                      Copy File
                    </>
                  )}
                </button>
              </div>
              <pre className="p-4 text-xs font-mono text-slate-300 overflow-x-auto bg-slate-950/60 max-h-[600px] leading-relaxed scrollbar-thin scrollbar-thumb-slate-800">
                {FLUTTER_FILES[activeFile]}
              </pre>
            </div>
          </div>
        )}

        {/* TAB 3: GITHUB ACTIONS BUILD GUIDE */}
        {activeTab === 'instructions' && (
          <div className="max-w-4xl mx-auto bg-slate-900 border border-slate-800 rounded-2xl p-6 md:p-8 space-y-6">
            <div className="border-b border-slate-800 pb-4">
              <h2 className="text-xl font-bold text-white flex items-center gap-2">
                <Github className="w-6 h-6 text-cyan-400" />
                Build APK Using Phone Only (GitHub Actions Workflow)
              </h2>
              <p className="text-xs text-slate-400 mt-1">
                You do not need a computer or Android Studio. GitHub Actions will build the release APK for you in the cloud!
              </p>
            </div>

            <div className="space-y-6 text-xs leading-relaxed text-slate-300">
              <div className="space-y-2">
                <h3 className="text-sm font-bold text-cyan-300 flex items-center gap-2">
                  <span className="w-6 h-6 rounded-full bg-cyan-500/20 text-cyan-400 flex items-center justify-center font-bold text-xs">
                    1
                  </span>
                  Get Your Free WeatherAPI Key
                </h3>
                <p className="pl-8 text-slate-400">
                  Open your mobile browser and register for a free key at{' '}
                  <a
                    href="https://www.weatherapi.com/signup.aspx"
                    target="_blank"
                    rel="noreferrer"
                    className="text-cyan-400 underline inline-flex items-center gap-0.5"
                  >
                    weatherapi.com <ExternalLink className="w-3 h-3" />
                  </a>
                  . Copy your key from the account dashboard.
                </p>
              </div>

              <div className="space-y-2">
                <h3 className="text-sm font-bold text-cyan-300 flex items-center gap-2">
                  <span className="w-6 h-6 rounded-full bg-cyan-500/20 text-cyan-400 flex items-center justify-center font-bold text-xs">
                    2
                  </span>
                  Create GitHub Repository & Add Secret
                </h3>
                <div className="pl-8 space-y-2 text-slate-400">
                  <p>Open GitHub on your mobile phone and create a new repository (e.g. <code className="text-cyan-300 bg-slate-950 px-1.5 py-0.5 rounded">atmosphere-weather</code>).</p>
                  <p>In your GitHub repository settings:</p>
                  <ul className="list-disc pl-5 space-y-1">
                    <li>Go to <strong>Settings</strong> &rarr; <strong>Secrets and variables</strong> &rarr; <strong>Actions</strong>.</li>
                    <li>Tap <strong>New repository secret</strong>.</li>
                    <li>Name: <code className="text-emerald-400 bg-slate-950 px-1.5 py-0.5 rounded">WEATHER_API_KEY</code></li>
                    <li>Secret: Paste your WeatherAPI key.</li>
                  </ul>
                </div>
              </div>

              <div className="space-y-2">
                <h3 className="text-sm font-bold text-cyan-300 flex items-center gap-2">
                  <span className="w-6 h-6 rounded-full bg-cyan-500/20 text-cyan-400 flex items-center justify-center font-bold text-xs">
                    3
                  </span>
                  Push Source Code & Download APK
                </h3>
                <div className="pl-8 space-y-2 text-slate-400">
                  <p>Upload or push this repository to your <code className="text-cyan-300">main</code> branch.</p>
                  <p>GitHub Actions will automatically start building. After 3-4 minutes:</p>
                  <ul className="list-disc pl-5 space-y-1">
                    <li>Go to the <strong>Actions</strong> tab to view the live build status.</li>
                    <li>Download the compiled APK directly under <strong>Artifacts</strong> or <strong>Releases</strong>!</li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
