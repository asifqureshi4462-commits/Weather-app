# Atmosphere Weather App (Flutter + GitHub Actions CI/CD)

A complete, production-ready, null-safe Flutter Weather Application with automated GitHub Actions build workflow that builds release APKs automatically without requiring a PC.

---

## 📱 Features

- **Current Weather Hero**: Real-time temperature, feels like, condition icon, location details.
- **Hourly Forecast**: Next 24-hour horizontal forecast with rain probability.
- **7-Day Forecast**: Weekly forecast list with high/low temperature ranges.
- **City Search & Autocomplete**: Search any city worldwide with instant API suggestions.
- **GPS Auto-Detect**: One-tap current location weather via `geolocator`.
- **Multiple Saved Favorites**: Swipeable/manageable favorite cities stored in `shared_preferences`.
- **Detailed Atmospheric Data**: Humidity, Wind speed & direction, UV Index, Air Quality Index (AQI PM2.5/PM10), Sunrise/Sunset times, Precipitation, Atmospheric Pressure, Visibility.
- **Unit Toggle**: Celsius (°C, km/h) / Fahrenheit (°F, mph).
- **Dynamic Themes**: Weather-adaptive gradient background based on weather conditions + Material 3 Light/Dark mode.
- **Resilient Error Handling**: Graceful fallback UI for offline mode, invalid API key, or location timeouts.

---

## 📁 Repository Folder Structure

```
atmosphere_weather/
├── .github/
│   └── workflows/
│       └── build_apk.yml          # GitHub Actions APK CI/CD workflow
├── android/
│   └── app/
│       └── src/
│           └── main/
│               └── AndroidManifest.xml
├── lib/
│   ├── main.dart                  # Entry point & MaterialApp setup
│   ├── models/
│   │   └── weather_model.dart     # Weather, Location, Hourly, Daily JSON models
│   ├── services/
│   │   ├── weather_service.dart   # WeatherAPI HTTP service
│   │   ├── location_service.dart  # GPS location detector
│   │   ├── storage_service.dart   # SharedPreferences manager
│   │   └── notification_service.dart # Local notifications
│   ├── providers/
│   │   └── weather_provider.dart  # Provider state controller
│   ├── screens/
│   │   ├── home_screen.dart       # Main weather display screen
│   │   ├── search_screen.dart     # City search & autocomplete
│   │   ├── favorites_screen.dart  # Saved locations manager
│   │   └── settings_screen.dart   # Units & Theme settings
│   └── widgets/
│       ├── weather_background.dart # Condition-based dynamic background
│       ├── current_weather_card.dart # Hero weather card
│       ├── hourly_forecast_list.dart# 24-hr horizontal list
│       ├── daily_forecast_list.dart # 7-day forecast list
│       └── weather_details_grid.dart # Atmospheric metrics grid
├── .env.example
├── .gitignore
├── pubspec.yaml
└── README.md
```

---

## 🚀 How to Build APK using ONLY your Phone (No PC Required)

### Step 1: Get a Free Weather API Key
1. Go to [https://www.weatherapi.com/signup.aspx](https://www.weatherapi.com/signup.aspx) on your mobile browser.
2. Register for a free account (no credit card required).
3. Copy your API key from the Dashboard (e.g. `1a2b3c4d5e6f...`).

### Step 2: Create a GitHub Repository & Add Secret
1. Go to [GitHub.com](https://github.com) or open the **GitHub Mobile App**.
2. Tap **+** -> **New Repository**, name it `atmosphere-weather`, and set it to **Public** or **Private**.
3. Push or commit this code into the `main` branch of your repository.
4. On your GitHub repository page:
   - Go to **Settings** -> **Secrets and variables** -> **Actions**.
   - Tap **New repository secret**.
   - **Name**: `WEATHER_API_KEY`
   - **Secret**: Paste your WeatherAPI.com API key.
   - Tap **Add secret**.

### Step 3: Trigger the Build & Download APK
1. Every time you push code to `main` (or trigger manually via the **Actions** tab -> **Build & Release Flutter Android APK** -> **Run workflow**), GitHub Actions will start.
2. Wait ~3-5 minutes while GitHub Action sets up Flutter, builds your release APK, and generates a GitHub Release.
3. Once completed:
   - Go to the **Releases** section on your GitHub repo page to download `app-release.apk`.
   - OR go to **Actions** -> select the latest run -> scroll to **Artifacts** -> tap to download `Atmosphere-Weather-v1.0.X.apk`!
4. Install the APK directly on your Android phone!
