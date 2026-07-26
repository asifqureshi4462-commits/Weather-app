import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../widgets/weather_background.dart';
import '../widgets/current_weather_card.dart';
import '../widgets/hourly_forecast_list.dart';
import '../widgets/daily_forecast_list.dart';
import '../widgets/weather_details_grid.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WeatherProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.my_location_rounded, color: Colors.white),
              tooltip: 'GPS Location',
              onPressed: () {
                provider.loadWeatherByLocation().catchError((err) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err.toString().replaceAll('Exception: ', ''))),
                  );
                });
              },
            ),
            const Text(
              'Atmosphere',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            tooltip: 'Search City',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks_rounded, color: Colors.white),
            tooltip: 'Favorites',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: WeatherBackground(
        conditionText: provider.currentWeather?.current.conditionText ?? 'Clear',
        isDay: provider.currentWeather?.current.isDay ?? true,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              if (provider.currentWeather != null) {
                await provider.loadWeatherForCity(provider.currentWeather!.location.name);
              } else {
                await provider.init();
              }
            },
            child: _buildBody(provider),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(WeatherProvider provider) {
    if (provider.isLoading && provider.currentWeather == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Fetching weather forecast...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (provider.errorMessage != null && provider.currentWeather == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 72, color: Colors.white70),
              const SizedBox(height: 16),
              const Text(
                'Unable to Load Weather',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry Connection'),
                onPressed: () => provider.init(),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Search Another City'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    final weather = provider.currentWeather;
    if (weather == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          CurrentWeatherCard(
            weather: weather,
            isMetric: provider.isMetric,
            isFavorite: provider.isFavorite(weather.location.name),
            onFavoriteToggle: () {
              if (provider.isFavorite(weather.location.name)) {
                provider.removeFavorite(weather.location.name);
              } else {
                provider.addFavorite(weather.location.name);
              }
            },
          ),
          HourlyForecastList(
            hourlyList: weather.hourly,
            isMetric: provider.isMetric,
          ),
          DailyForecastList(
            dailyList: weather.daily,
            isMetric: provider.isMetric,
          ),
          WeatherDetailsGrid(
            weather: weather,
            isMetric: provider.isMetric,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
