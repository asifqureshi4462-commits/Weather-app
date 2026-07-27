import React, { useState, useEffect } from 'react';
import JSZip from 'jszip';
import { motion, AnimatePresence } from 'motion/react';
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid
} from 'recharts';
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
  ChevronLeft,
  ChevronRight,
  Sparkles,
  Info,
  ShieldCheck,
  Terminal,
  FileCode,
  FolderTree,
  ExternalLink,
  ChevronDown,
  AlertTriangle,
  Sunrise,
  Sunset,
  Moon,
  ArrowUp,
  LayoutGrid,
  WifiOff,
  Wifi
} from 'lucide-react';

// Code files dictionary mapping file path to content for easy download/preview
const FLUTTER_FILES: Record<string, string> = {
  'pubspec.yaml': `name: atmosphere_weather
description: "A feature-rich Flutter Weather application with AI Insights, Home Screen Widgets, AdMob monetization, offline caching, multi-language support, and GitHub Actions CI/CD for release APKs."
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
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  sqflite: ^2.3.3
  geolocator: ^11.0.0
  permission_handler: ^11.3.1
  flutter_dotenv: ^5.1.0
  intl: ^0.19.0
  flutter_local_notifications: ^17.1.2
  fl_chart: ^0.68.0
  flutter_map: ^7.0.2
  latlong2: ^0.9.1
  screenshot: ^3.0.0
  share_plus: ^10.0.0
  google_mobile_ads: ^5.1.0
  home_widget: ^0.7.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - .env`,

  '.env.example': `WEATHER_API_KEY=your_weatherapi_key_here
AI_API_KEY=your_anthropic_claude_or_openai_api_key_here
ADMOB_APP_ID=ca-app-pub-3940256099942544~3347511713
ADMOB_BANNER_ID=ca-app-pub-3940256099942544/6300978111
ADMOB_INTERSTITIAL_ID=ca-app-pub-3940256099942544/1033173712`,

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
          echo "AI_API_KEY=\${{ secrets.AI_API_KEY }}" >> .env
          echo "ADMOB_APP_ID=\${{ secrets.ADMOB_APP_ID }}" >> .env
          echo "ADMOB_BANNER_UNIT_ID=\${{ secrets.ADMOB_BANNER_UNIT_ID }}" >> .env
          echo "ADMOB_INTERSTITIAL_UNIT_ID=\${{ secrets.ADMOB_INTERSTITIAL_UNIT_ID }}" >> .env
          echo "Created .env configuration with GitHub Secrets."

      - name: Repair & Generate Android Flutter v2 Embedding Project
        run: |
          echo "Generating clean Android project structure with Flutter v2 embedding..."
          flutter create --platforms=android --org com.example atmosphere_weather .

          MANIFEST="android/app/src/main/AndroidManifest.xml"
          echo "Injecting permissions and AdMob metadata into AndroidManifest.xml..."

          if ! grep -q "android.permission.INTERNET" "$MANIFEST"; then
            sed -i '/<manifest/a \    <uses-permission android:name="android.permission.INTERNET" />\n    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />\n    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />\n    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />' "$MANIFEST"
          fi

          if ! grep -q "flutterEmbedding" "$MANIFEST"; then
            sed -i 's|</application>|        <meta-data android:name="flutterEmbedding" android:value="2" />\n    </application>|' "$MANIFEST"
          fi

          ADMOB_ID="\${{ secrets.ADMOB_APP_ID }}"
          if [ -z "\$ADMOB_ID" ]; then
            ADMOB_ID="ca-app-pub-3940256099942544~3347511713"
          fi
          if ! grep -q "com.google.android.gms.ads.APPLICATION_ID" "$MANIFEST"; then
            sed -i "s|</application>|        <meta-data android:name=\"com.google.android.gms.ads.APPLICATION_ID\" android:value=\"\$ADMOB_ID\" />\n    </application>|" "$MANIFEST"
          else
            sed -i "s/ADMOB_APP_ID_PLACEHOLDER/\$ADMOB_ID/g" "$MANIFEST" || true
          fi

          MAIN_KT_DIR="android/app/src/main/kotlin/com/example/atmosphere_weather"
          mkdir -p "$MAIN_KT_DIR"
          printf 'package com.example.atmosphere_weather\n\nimport io.flutter.embedding.android.FlutterActivity\n\nclass MainActivity: FlutterActivity() {\n}\n' > "$MAIN_KT_DIR/MainActivity.kt"
          find android/ -name "MainActivity.java" -delete 2>/dev/null || true

          echo "Flutter Android v2 embedding setup generated."

      - name: Install Dependencies
        run: flutter pub get

      - name: FIX - Patch google_mobile_ads build.gradle for Gradle Compatibility
        run: |
          echo "=== Patching google_mobile_ads build.gradle if needed ==="
          GRADLE_FILES=$(find "$HOME/.pub-cache/hosted/pub.dev" -type f \( -name "build.gradle" -o -name "build.gradle.kts" \) | grep "google_mobile_ads" || true)
          if [ -n "$GRADLE_FILES" ]; then
            for FILE in $GRADLE_FILES; do
              echo "Processing $FILE..."
              sed -i 's/for\s*(configuration\s*in\s*configurations)/for (configuration in configurations.matching { it.name != "archives" })/g' "$FILE" 2>/dev/null || true
              sed -i 's/configurations\.all\s*\{/configurations.configureEach {/g' "$FILE" 2>/dev/null || true
              echo "Safely processed $FILE"
            done
          else
            echo "No google_mobile_ads gradle file required patching."
          fi

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
            - Features: Home Screen Weather Widgets, AI Vibe Summaries, AdMob Monetization, Multi-Language, Offline Caching
          files: build/app/outputs/flutter-apk/app-release.apk
        env:
          GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}`,

  'android/app/src/main/AndroidManifest.xml': `<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.atmosphere_weather">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:label="Atmosphere Weather"
        android:name="\${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <meta-data android:name="flutterEmbedding" android:value="2" />
        <meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="ADMOB_APP_ID_PLACEHOLDER" />

        <receiver
            android:name=".WeatherWidgetProvider"
            android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/weather_widget_info" />
        </receiver>

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <meta-data android:name="io.flutter.embedding.android.NormalTheme" android:resource="@style/NormalTheme" />

            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>`,

  'android/app/src/main/java/com/example/atmosphere_weather/MainActivity.kt': `package com.example.atmosphere_weather

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
}`,

  'lib/services/widget_service.dart': `import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/weather_model.dart';

class WidgetService {
  static const String _androidWidgetName = 'WeatherWidgetProvider';

  static Future<void> updateHomeWidget(WeatherData weather, {bool isMetric = true}) async {
    try {
      final tempStr = isMetric ? '\${weather.current.tempC.round()}°C' : '\${weather.current.tempF.round()}°F';
      final highLowStr = isMetric
          ? 'H: \${weather.daily.isNotEmpty ? weather.daily.first.maxTempC.round() : 0}°  L: \${weather.daily.isNotEmpty ? weather.daily.first.minTempC.round() : 0}°'
          : 'H: \${weather.daily.isNotEmpty ? weather.daily.first.maxTempF.round() : 0}°  L: \${weather.daily.isNotEmpty ? weather.daily.first.minTempF.round() : 0}°';

      final now = DateTime.now();
      final timeStr = '\${now.hour.toString().padLeft(2, '0')}:\${now.minute.toString().padLeft(2, '0')}';

      await HomeWidget.saveWidgetData<String>('cityName', weather.location.name);
      await HomeWidget.saveWidgetData<String>('temperature', tempStr);
      await HomeWidget.saveWidgetData<String>('condition', weather.current.conditionText);
      await HomeWidget.saveWidgetData<String>('highLow', highLowStr);
      await HomeWidget.saveWidgetData<String>('updatedAt', 'Updated \$timeStr');

      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: _androidWidgetName,
      );
      debugPrint('Home Screen Widget updated with \${weather.location.name} (\$tempStr)');
    } catch (e) {
      debugPrint('Error updating home screen widget: \$e');
    }
  }
}`,

  'android/app/src/main/res/layout/weather_widget_layout.xml': `<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="#1C2333"
    android:orientation="vertical"
    android:padding="12dp">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal">

        <LinearLayout
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:orientation="vertical">

            <TextView
                android:id="@+id/widget_city"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="City"
                android:textColor="#FFFFFF"
                android:textSize="14sp"
                android:textStyle="bold" />

            <TextView
                android:id="@+id/widget_condition"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="Sunny"
                android:textColor="#A0AEC0"
                android:textSize="11sp" />
        </LinearLayout>

        <TextView
            android:id="@+id/widget_temp"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="26°C"
            android:textColor="#38BDF8"
            android:textSize="26sp"
            android:textStyle="bold" />
    </LinearLayout>

    <View
        android:layout_width="match_parent"
        android:layout_height="1dp"
        android:layout_marginTop="8dp"
        android:layout_marginBottom="8dp"
        android:background="#2D3748" />

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:gravity="center_vertical"
        android:orientation="horizontal">

        <TextView
            android:id="@+id/widget_high_low"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="H: 29°  L: 20°"
            android:textColor="#CBD5E1"
            android:textSize="10sp" />

        <TextView
            android:id="@+id/widget_updated_at"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="Updated just now"
            android:textColor="#64748B"
            android:textSize="9sp" />
    </LinearLayout>
</LinearLayout>`,

  'android/app/src/main/res/xml/weather_widget_info.xml': `<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="180dp"
    android:minHeight="110dp"
    android:updatePeriodMillis="1800000"
    android:initialLayout="@layout/weather_widget_layout"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen" />`,

  'android/app/src/main/java/com/example/atmosphere_weather/WeatherWidgetProvider.kt': `package com.example.atmosphere_weather

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class WeatherWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.weather_widget_layout).apply {
                val cityName = widgetData.getString("cityName", "City")
                val temp = widgetData.getString("temperature", "--°")
                val condition = widgetData.getString("condition", "Clear")
                val highLow = widgetData.getString("highLow", "H:--° L:--°")
                val updatedAt = widgetData.getString("updatedAt", "Tap to open")

                setTextViewText(R.id.widget_city, cityName)
                setTextViewText(R.id.widget_temp, temp)
                setTextViewText(R.id.widget_condition, condition)
                setTextViewText(R.id.widget_high_low, highLow)
                setTextViewText(R.id.widget_updated_at, updatedAt)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}`,

  'lib/main.dart': `import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'providers/weather_provider.dart';
import 'screens/splash_screen.dart';

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

  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    debugPrint('AdMob initialization error: \$e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => WeatherProvider()..initializeSettingsAndLoad(),
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
                  const Text('AI Vibe, Multi-Language & Live Forecast', style: TextStyle(color: Colors.white70)),
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

  'lib/screens/home_screen.dart': `import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../models/weather_model.dart';
import '../services/ad_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getOfflineBannerText(DateTime? lastFetchTime) {
    if (lastFetchTime == null) {
      return 'Last updated recently (offline)';
    }
    final diffMins = DateTime.now().difference(lastFetchTime).inMinutes;
    if (diffMins <= 0) {
      return 'Last updated just now (offline)';
    } else if (diffMins == 1) {
      return 'Last updated 1 min ago (offline)';
    } else {
      return 'Last updated \$diffMins mins ago (offline)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = context.watch<WeatherProvider>();
    final weather = weatherProvider.weatherData;
    final isOffline = weatherProvider.isOffline;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.cloud_queue_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Atmosphere',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              weatherProvider.isMetric ? Icons.thermostat_rounded : Icons.square_foot_rounded,
              color: Colors.white,
            ),
            tooltip: 'Toggle °C / °F',
            onPressed: () {
              weatherProvider.setUnitPreference(!weatherProvider.isMetric);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh Weather',
            onPressed: () {
              AdService().recordUserAction();
              weatherProvider.fetchWeather(weatherProvider.currentCity);
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: (weather?.current.isDay ?? true)
                ? [const Color(0xFF0284C7), const Color(0xFF075985), const Color(0xFF0F172A)]
                : [const Color(0xFF0F172A), const Color(0xFF1E1B4B), const Color(0xFF020617)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Search Input Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search city (e.g. London, Tokyo)...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white70),
                      onPressed: () {
                        if (_searchController.text.trim().isNotEmpty) {
                          weatherProvider.fetchWeather(_searchController.text.trim());
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                        }
                      },
                    ),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.25),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.cyanAccent),
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      weatherProvider.fetchWeather(value.trim());
                      _searchController.clear();
                    }
                  },
                ),
              ),

              // Dynamic Clear, Non-Intrusive Offline Mode Banner
              if (isOffline)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.45),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.wifi_off_rounded,
                          size: 16,
                          color: Color(0xFFFCD34D),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getOfflineBannerText(weatherProvider.lastFetchTime),
                          style: const TextStyle(
                            color: Color(0xFFFEF3C7),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.5),
                            width: 0.8,
                          ),
                        ),
                        child: const Text(
                          'OFFLINE',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Loading Indicator or Error or Weather Content
              Expanded(
                child: weatherProvider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.cyanAccent),
                      )
                    : weatherProvider.errorMessage != null && weather == null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.amber),
                                  const SizedBox(height: 16),
                                  Text(
                                    weatherProvider.errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => weatherProvider.fetchWeather(weatherProvider.currentCity),
                                    child: const Text('Try Again'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : weather == null
                            ? const Center(child: Text('No weather data', style: TextStyle(color: Colors.white)))
                            : RefreshIndicator(
                                onRefresh: () async {
                                  await weatherProvider.fetchWeather(weatherProvider.currentCity);
                                },
                                child: SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Weather Hero Display
                                      _buildHeroWeatherCard(context, weather, weatherProvider.isMetric),
                                      const SizedBox(height: 16),

                                      // AI Vibe Summary Widget
                                      if (weatherProvider.aiVibe.isNotEmpty)
                                        _buildAiVibeCard(weatherProvider.aiVibe),

                                      const SizedBox(height: 16),

                                      // Hourly Forecast List
                                      _buildHourlySection(weather),

                                      const SizedBox(height: 16),

                                      // 7-Day Forecast
                                      _buildDailySection(weather, weatherProvider.isMetric),

                                      const SizedBox(height: 16),

                                      // Detailed Metrics Grid (Wind, Humidity, UV, AQI, Pressure)
                                      _buildMetricsGrid(weather, weatherProvider.isMetric),

                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroWeatherCard(BuildContext context, WeatherData weather, bool isMetric) {
    final tempStr = isMetric ? '\${weather.current.tempC.round()}°C' : '\${weather.current.tempF.round()}°F';
    final feelsLikeStr = isMetric ? '\${weather.current.feelsLikeC.round()}°C' : '\${weather.current.feelsLikeF.round()}°F';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(
            weather.location.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            weather.location.country,
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
          ),
          const SizedBox(height: 12),
          Text(
            tempStr,
            style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w200, color: Colors.white),
          ),
          Text(
            weather.current.conditionText,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Feels like \$feelsLikeStr',
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildAiVibeCard(String aiVibe) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              aiVibe,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlySection(WeatherData weather) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('HOURLY FORECAST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            itemBuilder: (context, index) {
              return Container(
                width: 70,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('\${index + 12}:00', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                    const Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 18),
                    Text('\${(weather.current.tempC + index % 3).round()}°', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailySection(WeatherData weather, bool isMetric) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('7-DAY FORECAST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
        const SizedBox(height: 8),
        ...weather.daily.map((day) {
          final high = isMetric ? '\${day.maxTempC.round()}°' : '\${day.maxTempF.round()}°';
          final low = isMetric ? '\${day.minTempC.round()}°' : '\${day.minTempF.round()}°';
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                SizedBox(width: 80, child: Text(day.date, style: const TextStyle(color: Colors.white, fontSize: 13))),
                Text(day.conditionText, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                Text('\$high / \$low', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMetricsGrid(WeatherData weather, bool isMetric) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        _buildMetricItem(Icons.air, 'WIND', isMetric ? '\${weather.current.windKph} km/h' : '\${weather.current.windMph} mph'),
        _buildMetricItem(Icons.water_drop, 'HUMIDITY', '\${weather.current.humidity}%'),
        _buildMetricItem(Icons.wb_sunny, 'UV INDEX', '\${weather.current.uvIndex}'),
        _buildMetricItem(Icons.compress, 'PRESSURE', '\${weather.current.pressureMb} hPa'),
      ],
    );
  }

  Widget _buildMetricItem(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ],
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
  final bool isBestDay;

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
    this.isBestDay = false,
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
      isBestDay: false,
    );
  }
}

class WeatherData {
  final LocationData location;
  final CurrentWeather current;
  final List<DailyForecast> daily;

  WeatherData({
    required this.location,
    required this.current,
    required this.daily,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final location = LocationData.fromJson(json['location'] as Map<String, dynamic>?);
    final current = CurrentWeather.fromJson(json['current'] as Map<String, dynamic>?);
    List<DailyForecast> dailyList = [];

    final forecastObj = json['forecast'] as Map<String, dynamic>?;
    final forecastDays = forecastObj?['forecastday'] as List<dynamic>?;

    if (forecastDays != null) {
      for (var dayJson in forecastDays) {
        if (dayJson is Map<String, dynamic>) {
          dailyList.add(DailyForecast.fromJson(dayJson));
        }
      }
    }

    // Calculate Best Day of the Week
    if (dailyList.isNotEmpty) {
      int bestIdx = 0;
      double bestScore = -999;

      for (int i = 0; i < dailyList.length; i++) {
        final d = dailyList[i];
        // Score based on low rain chance, comfortable temp (~22C), and low wind
        double tempPenalty = (d.avgTempC - 23.0).abs();
        double score = 100 - (d.chanceOfRain * 1.2) - (tempPenalty * 2.0) - (d.maxWindKph * 0.5);
        if (score > bestScore) {
          bestScore = score;
          bestIdx = i;
        }
      }

      dailyList = dailyList.asMap().entries.map((entry) {
        final idx = entry.key;
        final d = entry.value;
        if (idx == bestIdx) {
          return DailyForecast(
            date: d.date, maxTempC: d.maxTempC, maxTempF: d.maxTempF,
            minTempC: d.minTempC, minTempF: d.minTempF, avgTempC: d.avgTempC,
            avgTempF: d.avgTempF, conditionText: d.conditionText, conditionIcon: d.conditionIcon,
            chanceOfRain: d.chanceOfRain, totalRainMm: d.totalRainMm, maxWindKph: d.maxWindKph,
            avgHumidity: d.avgHumidity, uvIndex: d.uvIndex, sunrise: d.sunrise, sunset: d.sunset,
            isBestDay: true,
          );
        }
        return d;
      }).toList();
    }

    return WeatherData(
      location: location,
      current: current,
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

  Future<Map<String, dynamic>> fetchRawWeatherJson(String query) async {
    final key = _apiKey;
    if (key.isEmpty) {
      throw Exception('API Key is missing. Please set WEATHER_API_KEY in .env or GitHub Secrets.');
    }

    final url = Uri.parse('\$_baseUrl/forecast.json?key=\$key&q=\$query&days=7&aqi=yes&alerts=no');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
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

  Future<WeatherData> fetchWeather(String query) async {
    final rawMap = await fetchRawWeatherJson(query);
    return WeatherData.fromJson(rawMap);
  }
}`,

  'lib/providers/weather_provider.dart': `import 'dart:convert';
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

    // 1. Immediately attempt to load cached weather from disk storage (Offline First)
    await _loadFromPersistentCache(_currentCity);

    // 2. Fetch fresh weather data from WeatherAPI
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

      // Persist latest weather JSON to local disk storage
      await _saveToPersistentCache(_currentCity, rawJsonMap);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastCityKey, _currentCity);
      await prefs.setString(_lastFetchTimeKey, _lastFetchTime!.toIso8601String());

      // Sync Android Home Widget
      WidgetService.updateHomeWidget(_weatherData!, isMetric: _isMetric);

      // Generate AI Vibe summary
      _generateAiVibe();
    } catch (e) {
      debugPrint('Network error or offline: \$e. Falling back to persistent disk cache...');
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
      final cacheKey = '\$_cachedWeatherKeyPrefix\${city.toLowerCase().trim()}';
      final jsonString = jsonEncode(jsonMap);
      await prefs.setString(cacheKey, jsonString);
      await prefs.setString('last_cached_weather_json', jsonString);
      debugPrint('Successfully saved weather data to persistent cache for \$city');
    } catch (e) {
      debugPrint('Failed to write weather cache: \$e');
    }
  }

  Future<bool> _loadFromPersistentCache(String city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '\$_cachedWeatherKeyPrefix\${city.toLowerCase().trim()}';
      String? cachedJson = prefs.getString(cacheKey);

      // Fallback to most recent cached weather if specific city isn't found
      cachedJson ??= prefs.getString('last_cached_weather_json');

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
      debugPrint('Failed to read weather cache: \$e');
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
}`,

  'lib/services/ai_insight_service.dart': `import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_model.dart';

class AiInsightService {
  String get _aiApiKey => dotenv.env['AI_API_KEY'] ?? '';

  Future<String> generateDailyVibe(WeatherData weather, String language) async {
    final apiKey = _aiApiKey;
    if (apiKey.isEmpty) {
      return _fallbackDailyVibe(weather, language);
    }

    final prompt = '''
Summarize today's weather for \${weather.location.name} in 1 short, catchy Hinglish sentence:
Temp: \${weather.current.tempC}°C, Condition: \${weather.current.conditionText}, Rain chance: \${weather.daily.isNotEmpty ? weather.daily.first.chanceOfRain : 0}%.
Keep under 18 words.
''';

    try {
      final responseText = await _callAiApi(prompt, apiKey);
      if (responseText != null && responseText.trim().isNotEmpty) {
        return responseText.trim();
      }
    } catch (e) {
      debugPrint('AI Vibe call error: \$e');
    }
    return _fallbackDailyVibe(weather, language);
  }

  Future<String> answerWeatherQuery(String query, WeatherData weather, String language) async {
    final apiKey = _aiApiKey;
    if (apiKey.isEmpty) {
      return _fallbackChatAnswer(query, weather);
    }

    final prompt = '''
Answer weather query for \${weather.location.name} using this real data:
Current: \${weather.current.tempC}°C, \${weather.current.conditionText}, Humidity \${weather.current.humidity}%.
User Query: "\$query"
Reply in 2 short Hinglish sentences.
''';

    try {
      final responseText = await _callAiApi(prompt, apiKey);
      if (responseText != null && responseText.trim().isNotEmpty) {
        return responseText.trim();
      }
    } catch (e) {
      debugPrint('AI Chat error: \$e');
    }
    return _fallbackChatAnswer(query, weather);
  }

  Future<String?> _callAiApi(String prompt, String apiKey) async {
    if (apiKey.startsWith('sk-ant-') || apiKey.contains('claude')) {
      final url = Uri.parse('https://api.anthropic.com/v1/messages');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: json.encode({
          'model': 'claude-3-5-haiku-20241022',
          'max_tokens': 120,
          'messages': [
            {'role': 'user', 'content': prompt}
          ]
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['content'] as List<dynamic>?;
        if (content != null && content.isNotEmpty) {
          return content.first['text']?.toString();
        }
      }
    } else {
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer \$apiKey',
        },
        body: json.encode({
          'model': 'gpt-4o-mini',
          'max_tokens': 120,
          'messages': [
            {'role': 'user', 'content': prompt}
          ]
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          return choices.first['message']?['content']?.toString();
        }
      }
    }
    return null;
  }

  String _fallbackDailyVibe(WeatherData weather, String language) {
    final temp = weather.current.tempC;
    final cond = weather.current.conditionText.toLowerCase();

    if (cond.contains('rain')) {
      return 'Aaj barish hone ka emkan hai, chhatri saath rakhna mat bhoolna! ☔';
    } else if (temp > 30) {
      return 'Aaj kaafi garmi hai! Khub paani piyo aur cotton kapde pehno. ☀️';
    } else if (temp < 15) {
      return 'Aaj thandak hai, halki jacket ya sweater pehen kar niklo. 🧥';
    } else {
      return 'Mausam Behad khushgowar hai! Aaj outdoor plans ke liye behtareen din hai. ✨';
    }
  }

  String _fallbackChatAnswer(String query, WeatherData weather) {
    return 'Current weather in \${weather.location.name}: \${weather.current.tempC}°C, \${weather.current.conditionText}. Rain chance: \${weather.daily.isNotEmpty ? weather.daily.first.chanceOfRain : 0}%.';
  }
}`,

  'lib/services/ad_service.dart': `import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;
  int _userActionCount = 0;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  // Official Google AdMob Test Unit IDs (Safe fallbacks if production secrets are missing)
  static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

  String get bannerAdUnitId {
    final envId = dotenv.env['ADMOB_BANNER_UNIT_ID'] ?? dotenv.env['ADMOB_BANNER_ID'];
    if (envId != null && envId.isNotEmpty && !envId.contains('PLACEHOLDER')) {
      return envId;
    }
    return _testBannerId;
  }

  String get interstitialAdUnitId {
    final envId = dotenv.env['ADMOB_INTERSTITIAL_UNIT_ID'] ?? dotenv.env['ADMOB_INTERSTITIAL_ID'];
    if (envId != null && envId.isNotEmpty && !envId.contains('PLACEHOLDER')) {
      return envId;
    }
    return _testInterstitialId;
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      _loadInterstitialAd();
    } catch (e) {
      debugPrint('AdMob Init Exception: \$e');
    }
  }

  void _loadInterstitialAd() {
    if (_isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitialAd(); // Preload next interstitial silently
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load: \${error.message}');
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  /// Increments action counter. Displays interstitial every 3rd action (e.g. manual refresh or radar view).
  void recordUserAction() {
    _userActionCount++;
    if (_userActionCount % 3 == 0) {
      showInterstitialIfReady();
    }
  }

  void showInterstitialIfReady() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
    } else {
      _loadInterstitialAd();
    }
  }
}`
};

const WIND_DIR_DEGREES: Record<string, number> = {
  N: 0,
  NNE: 22.5,
  NE: 45,
  ENE: 67.5,
  E: 90,
  ESE: 112.5,
  SE: 135,
  SSE: 157.5,
  S: 180,
  SSW: 202.5,
  SW: 225,
  WSW: 247.5,
  W: 270,
  WNW: 292.5,
  NW: 315,
  NNW: 337.5,
};

const getWindDegrees = (dirStr: string): number => {
  if (!dirStr) return 0;
  const upper = dirStr.trim().toUpperCase();
  if (WIND_DIR_DEGREES[upper] !== undefined) {
    return WIND_DIR_DEGREES[upper];
  }
  const parsed = parseFloat(dirStr);
  return isNaN(parsed) ? 0 : parsed;
};

interface MockCityWeather {
  name: string;
  country: string;
  lat: number;
  lon: number;
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
  sunrise: string;
  sunset: string;
  sunProgress: number;
  hourly: { time: string; tempC: number; tempF: number; condition: string; rainChance: number }[];
  daily: { day: string; condition: string; highC: number; lowC: number; highF: number; lowF: number; rainChance: number }[];
}

const MOCK_WEATHER_DATABASE: Record<string, MockCityWeather> = {
  London: {
    name: 'London',
    country: 'United Kingdom',
    lat: 51.5074,
    lon: -0.1278,
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
    sunrise: '05:42 AM',
    sunset: '08:35 PM',
    sunProgress: 65,
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
    lat: 40.7128,
    lon: -74.0060,
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
    sunrise: '05:58 AM',
    sunset: '08:12 PM',
    sunProgress: 72,
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
    lat: 35.6762,
    lon: 139.6503,
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
    isDay: false,
    sunrise: '04:45 AM',
    sunset: '06:50 PM',
    sunProgress: 80,
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
  Miami: {
    name: 'Miami',
    country: 'United States',
    lat: 25.7617,
    lon: -80.1918,
    tempC: 29,
    tempF: 84,
    feelsLikeC: 33,
    feelsLikeF: 91,
    condition: 'Severe Thunderstorm',
    humidity: 88,
    windKph: 35,
    windMph: 22,
    windDir: 'SSE',
    uvIndex: 8.9,
    aqiEpa: 3,
    aqiPm25: 22.5,
    pressureMb: 1005,
    visibilityKm: 5,
    isDay: true,
    sunrise: '06:30 AM',
    sunset: '08:10 PM',
    sunProgress: 55,
    hourly: [
      { time: 'Now', tempC: 29, tempF: 84, condition: 'Severe Thunderstorm', rainChance: 95 },
      { time: '2 PM', tempC: 28, tempF: 82, condition: 'Thunderstorm', rainChance: 90 },
      { time: '3 PM', tempC: 27, tempF: 80, condition: 'Heavy Rain', rainChance: 85 },
      { time: '4 PM', tempC: 27, tempF: 80, condition: 'Light Rain', rainChance: 40 },
    ],
    daily: [
      { day: 'Today', condition: 'Severe Thunderstorm', highC: 30, lowC: 24, highF: 86, lowF: 75, rainChance: 95 },
      { day: 'Mon', condition: 'Heavy Rain', highC: 29, lowC: 24, highF: 84, lowF: 75, rainChance: 75 },
      { day: 'Tue', condition: 'Sunny', highC: 31, lowC: 25, highF: 88, lowF: 77, rainChance: 10 },
      { day: 'Wed', condition: 'Sunny', highC: 32, lowC: 25, highF: 90, lowF: 77, rainChance: 10 },
      { day: 'Thu', condition: 'Partly Cloudy', highC: 30, lowC: 24, highF: 86, lowF: 75, rainChance: 20 },
      { day: 'Fri', condition: 'Thunderstorm', highC: 29, lowC: 23, highF: 84, lowF: 73, rainChance: 80 },
      { day: 'Sat', condition: 'Sunny', highC: 31, lowC: 25, highF: 88, lowF: 77, rainChance: 10 },
    ],
  },
  Chicago: {
    name: 'Chicago',
    country: 'United States',
    lat: 41.8781,
    lon: -87.6298,
    tempC: -2,
    tempF: 28,
    feelsLikeC: -8,
    feelsLikeF: 17,
    condition: 'Heavy Snow & Gale Warning',
    humidity: 85,
    windKph: 45,
    windMph: 28,
    windDir: 'NNW',
    uvIndex: 1.0,
    aqiEpa: 1,
    aqiPm25: 7.0,
    pressureMb: 998,
    visibilityKm: 3,
    isDay: false,
    sunrise: '05:40 AM',
    sunset: '08:20 PM',
    sunProgress: 42,
    hourly: [
      { time: 'Now', tempC: -2, tempF: 28, condition: 'Heavy Snow', rainChance: 90 },
      { time: '2 PM', tempC: -1, tempF: 30, condition: 'Heavy Snow', rainChance: 85 },
      { time: '3 PM', tempC: -3, tempF: 26, condition: 'Snow Squall', rainChance: 95 },
      { time: '4 PM', tempC: -4, tempF: 24, condition: 'Light Snow', rainChance: 60 },
    ],
    daily: [
      { day: 'Today', condition: 'Heavy Snow', highC: 0, lowC: -6, highF: 32, lowF: 21, rainChance: 90 },
      { day: 'Mon', condition: 'Light Snow', highC: -1, lowC: -7, highF: 30, lowF: 19, rainChance: 50 },
      { day: 'Tue', condition: 'Cloudy', highC: 1, lowC: -5, highF: 34, lowF: 23, rainChance: 20 },
      { day: 'Wed', condition: 'Sunny', highC: 3, lowC: -3, highF: 37, lowF: 26, rainChance: 5 },
      { day: 'Thu', condition: 'Partly Cloudy', highC: 4, lowC: -2, highF: 39, lowF: 28, rainChance: 10 },
      { day: 'Fri', condition: 'Sunny', highC: 5, lowC: -1, highF: 41, lowF: 30, rainChance: 5 },
      { day: 'Sat', condition: 'Partly Cloudy', highC: 6, lowC: 0, highF: 43, lowF: 32, rainChance: 10 },
    ],
  },
};

interface AlertBannerProps {
  condition: string;
  cityName: string;
}

const SEVERE_KEYWORDS = [
  'thunderstorm',
  'storm',
  'heavy rain',
  'extreme',
  'snow',
  'squall',
  'tornado',
  'hurricane',
  'gale',
  'warning',
  'blizzard'
];

function AlertBanner({ condition, cityName }: AlertBannerProps) {
  const isSevere = SEVERE_KEYWORDS.some((keyword) =>
    condition.toLowerCase().includes(keyword)
  );

  if (!isSevere) return null;

  return (
    <div className="p-3.5 rounded-xl bg-gradient-to-r from-amber-500/25 via-red-500/30 to-amber-500/25 border border-amber-500/50 text-amber-200 flex items-start gap-3 shadow-lg animate-pulse">
      <AlertTriangle className="w-5 h-5 text-amber-400 flex-shrink-0 mt-0.5" />
      <div className="flex-1 text-left">
        <div className="flex items-center justify-between">
          <span className="font-bold text-[11px] uppercase tracking-wider text-amber-300">Weather Alert</span>
          <span className="text-[9px] font-bold bg-red-900/90 text-red-200 px-1.5 py-0.5 rounded border border-red-500/60 font-mono">
            WARNING
          </span>
        </div>
        <p className="text-[11px] mt-1 text-amber-100 font-medium leading-tight">
          {condition} active in {cityName}. Stay alert for potential hazards and follow local guidance.
        </p>
      </div>
    </div>
  );
}

export default function App() {
  const [activeTab, setActiveTab] = useState<'preview' | 'code' | 'instructions'>('preview');
  const [selectedCity, setSelectedCity] = useState<string>('London');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [isMetric, setIsMetric] = useState<boolean>(true);
  const [isOffline, setIsOffline] = useState<boolean>(true);
  const [favorites, setFavorites] = useState<string[]>(['London', 'New York', 'Tokyo', 'Miami', 'Chicago']);
  const [activeFile, setActiveFile] = useState<string>('pubspec.yaml');
  const [copiedFile, setCopiedFile] = useState<boolean>(false);
  const [isZipping, setIsZipping] = useState<boolean>(false);
  const [dragDirection, setDragDirection] = useState<'left' | 'right' | null>(null);
  const [overrideIsDayMap, setOverrideIsDayMap] = useState<Record<string, boolean>>({});

  // Auto-detect Celsius or Fahrenheit based on user locale, timezone, or geolocation on app load
  useEffect(() => {
    const detectLocaleUnit = () => {
      try {
        const languages = navigator.languages || [navigator.language];
        const isUSLocale = languages.some(
          (lang) => lang && (lang.toUpperCase().endsWith('-US') || lang.toUpperCase() === 'EN-US')
        );

        const timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone || '';
        const isUSTimeZone =
          timeZone.startsWith('America/') &&
          (timeZone.includes('New_York') ||
            timeZone.includes('Chicago') ||
            timeZone.includes('Los_Angeles') ||
            timeZone.includes('Denver') ||
            timeZone.includes('Phoenix') ||
            timeZone.includes('Anchorage') ||
            timeZone.includes('Honolulu') ||
            timeZone.includes('Detroit') ||
            timeZone.includes('Indiana') ||
            timeZone.includes('Kentucky') ||
            timeZone.includes('Boise'));

        if (isUSLocale || isUSTimeZone) {
          setIsMetric(false);
        } else {
          setIsMetric(true);
        }
      } catch {
        setIsMetric(true);
      }
    };

    detectLocaleUnit();

    if ('geolocation' in navigator) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const { latitude, longitude } = position.coords;
          const isUSCoords =
            (latitude >= 24.39 && latitude <= 49.38 && longitude >= -125.0 && longitude <= -66.93) ||
            (latitude >= 18.91 && latitude <= 28.4 && longitude >= -178.33 && longitude <= -154.8) ||
            (latitude >= 51.2 && latitude <= 71.38 && longitude >= -179.15 && longitude <= -129.97);

          if (isUSCoords) {
            setIsMetric(false);
          }
        },
        () => {},
        { timeout: 3000 }
      );
    }
  }, []);

  const cityKeys = Object.keys(MOCK_WEATHER_DATABASE);

  const handleNextCity = () => {
    const curIdx = cityKeys.indexOf(selectedCity);
    const nextIdx = (curIdx + 1) % cityKeys.length;
    setDragDirection('left');
    setSelectedCity(cityKeys[nextIdx]);
  };

  const handlePrevCity = () => {
    const curIdx = cityKeys.indexOf(selectedCity);
    const prevIdx = (curIdx - 1 + cityKeys.length) % cityKeys.length;
    setDragDirection('right');
    setSelectedCity(cityKeys[prevIdx]);
  };

  const baseWeather = MOCK_WEATHER_DATABASE[selectedCity] || MOCK_WEATHER_DATABASE['London'];
  const currentWeather = {
    ...baseWeather,
    isDay: overrideIsDayMap[selectedCity] !== undefined ? overrideIsDayMap[selectedCity] : baseWeather.isDay,
  };

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
                <div className={`w-full h-full rounded-[32px] overflow-hidden flex flex-col relative transition-all duration-700 ease-in-out text-white pt-7 ${
                  currentWeather.isDay
                    ? 'bg-gradient-to-b from-sky-500 via-sky-800 to-indigo-950'
                    : 'bg-gradient-to-b from-slate-950 via-indigo-950 to-black'
                }`}>
                  {/* Atmospheric Glow Overlay */}
                  <div
                    className={`absolute -top-16 -right-16 w-56 h-56 rounded-full blur-3xl pointer-events-none transition-all duration-700 ${
                      currentWeather.isDay ? 'bg-amber-400/25 opacity-100' : 'bg-indigo-500/30 opacity-80'
                    }`}
                  />

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
                        onClick={() =>
                          setOverrideIsDayMap((prev) => ({
                            ...prev,
                            [selectedCity]: !currentWeather.isDay,
                          }))
                        }
                        className={`p-1.5 rounded-full backdrop-blur border text-xs font-semibold transition flex items-center gap-1 ${
                          currentWeather.isDay
                            ? 'bg-amber-400/20 border-amber-300/40 text-amber-200 hover:bg-amber-400/30'
                            : 'bg-indigo-900/60 border-indigo-400/40 text-indigo-200 hover:bg-indigo-800/60'
                        }`}
                        title={`Switch to ${currentWeather.isDay ? 'Night' : 'Day'} mode`}
                      >
                        {currentWeather.isDay ? (
                          <Sun className="w-3.5 h-3.5 text-amber-300" />
                        ) : (
                          <Moon className="w-3.5 h-3.5 text-indigo-300" />
                        )}
                      </button>
                      <button
                        onClick={() => setIsOffline(!isOffline)}
                        className={`p-1.5 rounded-full backdrop-blur border text-xs font-semibold transition flex items-center gap-1 ${
                          isOffline
                            ? 'bg-amber-500/30 border-amber-400/60 text-amber-200 hover:bg-amber-500/40'
                            : 'bg-emerald-500/20 border-emerald-400/40 text-emerald-300 hover:bg-emerald-500/30'
                        }`}
                        title={isOffline ? 'Offline mode active (Click to go Online)' : 'Online mode (Click to simulate Offline mode)'}
                      >
                        {isOffline ? (
                          <WifiOff className="w-3.5 h-3.5 text-amber-300" />
                        ) : (
                          <Wifi className="w-3.5 h-3.5 text-emerald-300" />
                        )}
                      </button>
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
                  <div className="px-4 mb-2 z-20">
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

                  {/* Dynamic Clear, Non-Intrusive Offline Mode Banner */}
                  <AnimatePresence>
                    {isOffline && (
                      <motion.div
                        initial={{ opacity: 0, height: 0, marginBottom: 0 }}
                        animate={{ opacity: 1, height: 'auto', marginBottom: 8 }}
                        exit={{ opacity: 0, height: 0, marginBottom: 0 }}
                        transition={{ duration: 0.25, ease: 'easeInOut' }}
                        className="mx-4 overflow-hidden z-20"
                      >
                        <div className="p-2.5 rounded-xl bg-amber-500/20 border border-amber-500/40 backdrop-blur text-amber-200 flex items-center justify-between gap-2 shadow-sm">
                          <div className="flex items-center gap-2">
                            <div className="p-1 bg-amber-500/25 rounded-lg text-amber-300 flex-shrink-0">
                              <WifiOff className="w-3.5 h-3.5" />
                            </div>
                            <span className="text-[11px] font-semibold text-amber-100 tracking-tight">
                              Last updated 12 mins ago (offline)
                            </span>
                          </div>
                          <span className="text-[9px] font-extrabold bg-amber-500/30 text-amber-300 px-1.5 py-0.5 rounded border border-amber-500/50 tracking-wider font-mono">
                            OFFLINE
                          </span>
                        </div>
                      </motion.div>
                    )}
                  </AnimatePresence>

                  {/* Scrollable Mobile Body */}
                  <div className="flex-1 overflow-y-auto px-4 pb-6 space-y-4 text-xs scrollbar-thin scrollbar-thumb-slate-700">
                    {/* Hero Current Weather Card with Horizontal Drag Gesture */}
                    <div className="relative overflow-hidden rounded-2xl">
                      <AnimatePresence mode="wait" custom={dragDirection}>
                        <motion.div
                          key={selectedCity}
                          drag="x"
                          dragConstraints={{ left: 0, right: 0 }}
                          dragElastic={0.25}
                          onDragEnd={(_, info) => {
                            if (info.offset.x < -35 || info.velocity.x < -180) {
                              handleNextCity();
                            } else if (info.offset.x > 35 || info.velocity.x > 180) {
                              handlePrevCity();
                            }
                          }}
                          initial={{
                            opacity: 0,
                            x: dragDirection === 'left' ? 80 : dragDirection === 'right' ? -80 : 0,
                            scale: 0.95
                          }}
                          animate={{ opacity: 1, x: 0, scale: 1 }}
                          exit={{
                            opacity: 0,
                            x: dragDirection === 'left' ? -80 : dragDirection === 'right' ? 80 : 0,
                            scale: 0.95
                          }}
                          transition={{ duration: 0.25, ease: 'easeOut' }}
                          className="p-5 rounded-2xl bg-black/30 backdrop-blur border border-white/15 flex flex-col items-center text-center shadow-lg cursor-grab active:cursor-grabbing select-none relative group touch-pan-y"
                        >
                          {/* Left/Right Arrow Nav Buttons */}
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              handlePrevCity();
                            }}
                            className="absolute left-2 top-1/2 -translate-y-1/2 p-1.5 rounded-full bg-black/40 backdrop-blur border border-white/10 text-slate-300 opacity-60 hover:opacity-100 hover:text-white transition shadow-sm z-10"
                            title="Previous city (Swipe Right)"
                          >
                            <ChevronLeft className="w-3.5 h-3.5" />
                          </button>
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              handleNextCity();
                            }}
                            className="absolute right-2 top-1/2 -translate-y-1/2 p-1.5 rounded-full bg-black/40 backdrop-blur border border-white/10 text-slate-300 opacity-60 hover:opacity-100 hover:text-white transition shadow-sm z-10"
                            title="Next city (Swipe Left)"
                          >
                            <ChevronRight className="w-3.5 h-3.5" />
                          </button>

                          <p className="text-base font-bold text-white">{currentWeather.name}</p>
                          <p className="text-[10px] text-cyan-200 mb-2">{currentWeather.country}</p>

                          <div className="flex items-center gap-2 my-2">
                            {currentWeather.isDay ? (
                              currentWeather.condition.includes('Sunny') ? (
                                <Sun className="w-16 h-16 text-amber-400 animate-spin-slow" />
                              ) : currentWeather.condition.includes('Rain') ? (
                                <CloudRain className="w-16 h-16 text-cyan-300" />
                              ) : currentWeather.condition.includes('Snow') ? (
                                <CloudSnow className="w-16 h-16 text-sky-200" />
                              ) : (
                                <Cloud className="w-16 h-16 text-slate-200" />
                              )
                            ) : (
                              currentWeather.condition.includes('Clear') || currentWeather.condition.includes('Sunny') ? (
                                <Moon className="w-16 h-16 text-indigo-200 animate-pulse drop-shadow-[0_0_12px_rgba(165,180,252,0.6)]" />
                              ) : currentWeather.condition.includes('Rain') ? (
                                <CloudRain className="w-16 h-16 text-indigo-300" />
                              ) : currentWeather.condition.includes('Snow') ? (
                                <CloudSnow className="w-16 h-16 text-sky-200" />
                              ) : (
                                <Cloud className="w-16 h-16 text-slate-400" />
                              )
                            )}
                            <span className="text-5xl font-extralight tracking-tighter">
                              {isMetric ? `${currentWeather.tempC}°` : `${currentWeather.tempF}°`}
                            </span>
                          </div>

                          <p className="font-semibold text-sm">{currentWeather.condition}</p>
                          <p className="text-[11px] text-slate-300">
                            Feels like {isMetric ? `${currentWeather.feelsLikeC}°C` : `${currentWeather.feelsLikeF}°F`}
                          </p>

                          {/* Saved City Pagination Dots */}
                          <div className="flex items-center justify-center gap-1.5 mt-3">
                            {cityKeys.map((city, idx) => {
                              const curIdx = cityKeys.indexOf(selectedCity);
                              return (
                                <button
                                  key={city}
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    setDragDirection(idx > curIdx ? 'left' : 'right');
                                    setSelectedCity(city);
                                  }}
                                  className={`h-1.5 rounded-full transition-all ${
                                    city === selectedCity ? 'w-4 bg-cyan-400' : 'w-1.5 bg-white/30 hover:bg-white/50'
                                  }`}
                                  title={`View ${city}`}
                                />
                              );
                            })}
                          </div>
                          <span className="text-[9px] text-slate-400/80 mt-1 font-mono tracking-wider">
                            ‹ Drag card left / right to switch cities ›
                          </span>
                        </motion.div>
                      </AnimatePresence>
                    </div>

                    {/* Conditional Severe Weather Alert Banner */}
                    <AlertBanner condition={currentWeather.condition} cityName={currentWeather.name} />

                    {/* Hourly Forecast Recharts Temperature Trend */}
                    <div className="p-3 rounded-xl bg-black/20 border border-white/10 space-y-2">
                      <div className="flex items-center justify-between">
                        <p className="text-[10px] font-bold text-slate-300 uppercase tracking-wider flex items-center gap-1">
                          <Thermometer className="w-3 h-3 text-cyan-400" />
                          Hourly Temperature Trend
                        </p>
                        <span className="text-[9px] font-semibold text-cyan-300 bg-cyan-950/60 px-1.5 py-0.5 rounded border border-cyan-800/40 font-mono">
                          {isMetric ? '°C' : '°F'}
                        </span>
                      </div>
                      <div className="h-32 w-full pt-1">
                        <ResponsiveContainer width="100%" height="100%">
                          <AreaChart
                            data={currentWeather.hourly.map((h) => ({
                              time: h.time,
                              temp: isMetric ? h.tempC : h.tempF,
                              rainChance: h.rainChance,
                              condition: h.condition,
                            }))}
                            margin={{ top: 10, right: 10, left: -25, bottom: 0 }}
                          >
                            <defs>
                              <linearGradient id="tempGradient" x1="0" y1="0" x2="0" y2="1">
                                <stop offset="5%" stopColor="#22d3ee" stopOpacity={0.4} />
                                <stop offset="95%" stopColor="#22d3ee" stopOpacity={0.0} />
                              </linearGradient>
                            </defs>
                            <CartesianGrid strokeDasharray="3 3" stroke="#ffffff15" vertical={false} />
                            <XAxis
                              dataKey="time"
                              tick={{ fill: '#94a3b8', fontSize: 9 }}
                              axisLine={false}
                              tickLine={false}
                            />
                            <YAxis
                              domain={['dataMin - 2', 'dataMax + 2']}
                              tick={{ fill: '#94a3b8', fontSize: 9 }}
                              axisLine={false}
                              tickLine={false}
                              tickFormatter={(val) => `${val}°`}
                            />
                            <Tooltip
                              content={({ active, payload }) => {
                                if (active && payload && payload.length) {
                                  const data = payload[0].payload;
                                  return (
                                    <div className="bg-slate-900/90 border border-white/20 p-2 rounded-lg backdrop-blur text-[10px] text-white shadow-xl space-y-0.5">
                                      <p className="font-bold text-cyan-300">{data.time}</p>
                                      <p className="font-semibold text-xs">
                                        {data.temp}{isMetric ? '°C' : '°F'}
                                      </p>
                                      <p className="text-slate-300 text-[9px]">{data.condition}</p>
                                      {data.rainChance > 0 && (
                                        <p className="text-cyan-400 text-[9px] font-bold">
                                          💧 {data.rainChance}% rain
                                        </p>
                                      )}
                                    </div>
                                  );
                                }
                                return null;
                              }}
                            />
                            <Area
                              type="monotone"
                              dataKey="temp"
                              stroke="#22d3ee"
                              strokeWidth={2}
                              fillOpacity={1}
                              fill="url(#tempGradient)"
                              dot={{ r: 3, fill: '#0891b2', stroke: '#22d3ee', strokeWidth: 1.5 }}
                              activeDot={{ r: 5, fill: '#38bdf8', stroke: '#ffffff', strokeWidth: 2 }}
                            />
                          </AreaChart>
                        </ResponsiveContainer>
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
                        <div className="flex items-center gap-1.5 text-[9px] text-slate-300 pt-0.5">
                          <div className="w-4 h-4 rounded-full bg-cyan-950/80 border border-cyan-400/40 flex items-center justify-center shadow-inner">
                            <ArrowUp
                              className="w-2.5 h-2.5 text-cyan-400 transition-transform duration-500 ease-out"
                              style={{ transform: `rotate(${getWindDegrees(currentWeather.windDir)}deg)` }}
                            />
                          </div>
                          <span className="font-semibold text-cyan-200">{currentWeather.windDir}</span>
                          <span className="text-[8px] text-slate-400 font-mono">({getWindDegrees(currentWeather.windDir)}°)</span>
                        </div>
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

                    {/* Sun Phase Card */}
                    <div className="p-3 rounded-xl bg-black/20 border border-white/10 space-y-2.5">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-1.5 text-slate-300">
                          <Sun className="w-3.5 h-3.5 text-amber-400" />
                          <span className="text-[10px] font-bold tracking-wider uppercase">Sun Phase</span>
                        </div>
                        <span className="text-[9px] font-semibold text-amber-300 bg-amber-950/60 px-1.5 py-0.5 rounded border border-amber-800/40">
                          {currentWeather.isDay ? 'Daylight' : 'Night'}
                        </span>
                      </div>

                      <div className="space-y-2">
                        <div className="flex items-center justify-between text-[11px] font-semibold">
                          <div className="flex items-center gap-1 text-amber-300">
                            <Sunrise className="w-3.5 h-3.5 text-amber-400" />
                            <span>{currentWeather.sunrise}</span>
                          </div>
                          <div className="text-[10px] text-slate-400 font-normal">
                            ~14h daylight
                          </div>
                          <div className="flex items-center gap-1 text-orange-400">
                            <Sunset className="w-3.5 h-3.5 text-orange-400" />
                            <span>{currentWeather.sunset}</span>
                          </div>
                        </div>

                        {/* Progress Bar */}
                        <div className="relative pt-1 pb-0.5">
                          <div className="h-2 w-full bg-slate-800/80 rounded-full overflow-hidden p-0.5 border border-white/10 relative">
                            <div
                              className="h-full rounded-full bg-gradient-to-r from-amber-400 via-orange-400 to-amber-500 transition-all duration-500 relative"
                              style={{ width: `${currentWeather.sunProgress}%` }}
                            >
                              <div className="absolute right-0 top-1/2 -translate-y-1/2 translate-x-1/2 w-2.5 h-2.5 rounded-full bg-amber-200 border border-white shadow-[0_0_6px_rgba(251,191,36,0.9)]" />
                            </div>
                          </div>
                        </div>

                        <div className="flex justify-between text-[9px] text-slate-400 font-medium pt-0.5">
                          <span>Dawn</span>
                          <span className="text-amber-200 font-bold">{currentWeather.sunProgress}% Progress</span>
                          <span>Dusk</span>
                        </div>
                      </div>
                    </div>

                    {/* Static Map Location Preview Component */}
                    <div className="p-3 rounded-xl bg-black/20 border border-white/10 space-y-2">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-1.5 text-slate-300">
                          <MapPin className="w-3.5 h-3.5 text-red-400" />
                          <span className="text-[10px] font-bold tracking-wider uppercase">Location Map</span>
                        </div>
                        <span className="text-[9px] font-mono text-cyan-300 bg-cyan-950/60 px-1.5 py-0.5 rounded border border-cyan-800/40">
                          {currentWeather.lat > 0 ? `${currentWeather.lat.toFixed(4)}° N` : `${Math.abs(currentWeather.lat).toFixed(4)}° S`},{' '}
                          {currentWeather.lon > 0 ? `${currentWeather.lon.toFixed(4)}° E` : `${Math.abs(currentWeather.lon).toFixed(4)}° W`}
                        </span>
                      </div>

                      <a
                        href={`https://www.openstreetmap.org/?mlat=${currentWeather.lat}&mlon=${currentWeather.lon}#map=12/${currentWeather.lat}/${currentWeather.lon}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="group relative block overflow-hidden rounded-lg border border-white/10 bg-slate-800 hover:border-cyan-400/50 transition-all shadow-sm"
                        title={`Open ${currentWeather.name} map on OpenStreetMap`}
                      >
                        {/* Map Tile Preview */}
                        <div className="relative h-28 w-full bg-slate-950 overflow-hidden">
                          <img
                            src={`https://tile.openstreetmap.org/12/${Math.floor((currentWeather.lon + 180) / 360 * 4096)}/${Math.floor((1 - Math.log(Math.tan(currentWeather.lat * Math.PI / 180) + 1 / Math.cos(currentWeather.lat * Math.PI / 180)) / Math.PI) / 2 * 4096)}.png`}
                            alt={`Map view of ${currentWeather.name}`}
                            className="w-full h-full object-cover opacity-80 group-hover:scale-105 group-hover:opacity-100 transition-all duration-300 filter contrast-125"
                            onError={(e) => {
                              e.currentTarget.src = 'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=400&auto=format&fit=crop&q=80';
                            }}
                          />
                          <div className="absolute inset-0 bg-gradient-to-t from-slate-950/80 via-transparent to-transparent pointer-events-none" />

                          {/* Map Pin Marker */}
                          <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
                            <div className="relative flex items-center justify-center">
                              <div className="w-7 h-7 rounded-full bg-red-500/30 animate-ping absolute" />
                              <div className="w-8 h-8 rounded-full bg-red-500/20 border border-red-400 flex items-center justify-center shadow-lg relative z-10 backdrop-blur-xs">
                                <MapPin className="w-4 h-4 text-red-400 fill-red-500" />
                              </div>
                            </div>
                          </div>

                          {/* External Link Badge */}
                          <div className="absolute bottom-2 right-2 px-2 py-1 rounded bg-black/70 backdrop-blur border border-white/20 text-[10px] text-slate-200 flex items-center gap-1 group-hover:bg-cyan-500 group-hover:text-slate-950 group-hover:font-bold transition-all">
                            <span>Open in Map</span>
                            <ExternalLink className="w-2.5 h-2.5" />
                          </div>
                        </div>
                      </a>
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

            {/* Side Controls & Home Screen Widget Simulator */}
            <div className="lg:col-span-6 space-y-6">
              {/* Home Screen Widget Live Preview Box */}
              <div className="bg-slate-900 border border-slate-800 rounded-2xl p-5 space-y-4 relative overflow-hidden">
                <div className="flex items-center justify-between">
                  <h2 className="text-sm font-bold text-white flex items-center gap-2">
                    <LayoutGrid className="w-4 h-4 text-cyan-400" />
                    Android / iOS Home Screen Widget Preview
                  </h2>
                  <span className="text-[10px] font-mono text-cyan-400 bg-cyan-950/80 px-2 py-0.5 rounded border border-cyan-800/50">
                    home_widget ^0.7.0
                  </span>
                </div>
                <p className="text-xs text-slate-400 leading-relaxed">
                  Users can view live weather directly on their phone home screen without opening the app. Tap 'Force Widget Sync' to simulate background updates!
                </p>

                {/* Simulated Android Home Screen Widget (2x2 / 4x2 AppWidget) */}
                <div className="bg-slate-950/90 border border-slate-700/80 rounded-2xl p-4 space-y-3 shadow-xl relative backdrop-blur">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-bold text-white flex items-center gap-1.5">
                        <MapPin className="w-3.5 h-3.5 text-cyan-400" />
                        {currentWeather.name}
                      </p>
                      <p className="text-[11px] text-slate-400 font-medium">{currentWeather.condition}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-2xl font-black text-cyan-400 tracking-tight">
                        {isMetric ? `${currentWeather.tempC}°C` : `${currentWeather.tempF}°F`}
                      </p>
                    </div>
                  </div>

                  <div className="h-px bg-slate-800 w-full" />

                  <div className="flex items-center justify-between text-[11px] text-slate-300">
                    <span className="font-semibold text-slate-200">
                      H: {isMetric ? `${currentWeather.daily[0]?.highC ?? 29}°` : `${currentWeather.daily[0]?.highF ?? 84}°`} &nbsp;
                      L: {isMetric ? `${currentWeather.daily[0]?.lowC ?? 20}°` : `${currentWeather.daily[0]?.lowF ?? 68}°`}
                    </span>
                    <span className="text-[10px] font-mono text-slate-500">
                      Updated just now
                    </span>
                  </div>
                </div>

                <div className="flex items-center justify-between pt-1">
                  <span className="text-[11px] text-slate-400">Sync status:</span>
                  <button
                    onClick={() => {
                      const toast = document.getElementById('widget-toast');
                      if (toast) {
                        toast.classList.remove('opacity-0', 'translate-y-2');
                        toast.classList.add('opacity-100', 'translate-y-0');
                        setTimeout(() => {
                          toast.classList.remove('opacity-100', 'translate-y-0');
                          toast.classList.add('opacity-0', 'translate-y-2');
                        }, 2500);
                      }
                    }}
                    className="px-3 py-1.5 bg-cyan-500 hover:bg-cyan-400 text-slate-950 font-bold rounded-xl text-xs flex items-center gap-1.5 transition shadow-sm active:scale-95"
                  >
                    <Sparkles className="w-3.5 h-3.5" />
                    Force Widget Sync
                  </button>
                </div>

                {/* Widget Sync Toast Notification */}
                <div
                  id="widget-toast"
                  className="opacity-0 translate-y-2 transition-all duration-300 pointer-events-none absolute bottom-3 left-5 right-5 bg-emerald-500 text-slate-950 px-3 py-2 rounded-xl font-bold text-xs flex items-center justify-between shadow-xl"
                >
                  <span className="flex items-center gap-1.5">
                    <Check className="w-4 h-4" />
                    Synced {currentWeather.name} ({isMetric ? `${currentWeather.tempC}°C` : `${currentWeather.tempF}°F`}) to AppWidget!
                  </span>
                  <span className="text-[10px] font-mono opacity-80">200 OK</span>
                </div>
              </div>

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

                <div className="pt-2 border-t border-slate-800 flex items-center justify-between text-xs">
                  <span className="text-slate-400">Offline Simulation:</span>
                  <button
                    onClick={() => setIsOffline(!isOffline)}
                    className={`px-3 py-1 font-semibold rounded-lg border transition flex items-center gap-1.5 ${
                      isOffline
                        ? 'bg-amber-500/20 text-amber-300 border-amber-500/40 hover:bg-amber-500/30'
                        : 'bg-emerald-500/20 text-emerald-300 border-emerald-500/40 hover:bg-emerald-500/30'
                    }`}
                  >
                    {isOffline ? <WifiOff className="w-3.5 h-3.5" /> : <Wifi className="w-3.5 h-3.5" />}
                    {isOffline ? 'Offline Mode (Active)' : 'Online Mode'}
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
