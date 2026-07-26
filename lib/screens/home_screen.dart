import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather_model.dart';
import '../providers/weather_provider.dart';
import '../widgets/weather_background.dart';
import '../widgets/current_weather_card.dart';
import '../widgets/hourly_forecast_list.dart';
import '../widgets/daily_forecast_list.dart';
import '../widgets/weather_details_grid.dart';
import '../widgets/weather_trend_chart.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import 'radar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ChartType _selectedChartType = ChartType.temperature;

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
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/app_logo.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.wb_sunny_rounded, color: Colors.amberAccent),
              ),
            ),
            const SizedBox(width: 8),
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
            icon: const Icon(Icons.map_rounded, color: Colors.white),
            tooltip: 'Live Weather Radar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RadarScreen()),
              );
            },
          ),
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
          if (weather.alerts.isNotEmpty) _buildAlertsBanner(context, weather.alerts),
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
          _buildTrendChartsCard(context, weather, provider.isMetric),
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

  Widget _buildAlertsBanner(BuildContext context, List<WeatherAlert> alerts) {
    final alert = alerts.first;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.redAccent.shade700,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showAlertDetailsSheet(context, alerts),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ ${alert.event} (${alerts.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alert.headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAlertDetailsSheet(BuildContext context, List<WeatherAlert> alerts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView.separated(
                controller: scrollController,
                itemCount: alerts.length,
                separatorBuilder: (_, __) => const Divider(height: 32),
                itemBuilder: (context, index) {
                  final a = alerts[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_rounded, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              a.event,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        a.headline,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent.shade200,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Affected Areas: ${a.areas}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (a.effective.isNotEmpty || a.expires.isNotEmpty)
                        Text(
                          'Period: ${a.effective} - ${a.expires}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        'Description',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        a.desc,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                      if (a.instruction.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Instructions / Safety Measures',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          a.instruction,
                          style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.amber),
                        ),
                      ],
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTrendChartsCard(BuildContext context, WeatherData weather, bool isMetric) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.show_chart_rounded, color: Colors.amberAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Weather Trends',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SegmentedButton<ChartType>(
                segments: const [
                  ButtonSegment(
                    value: ChartType.temperature,
                    label: Text('24h Temp', style: TextStyle(fontSize: 11)),
                  ),
                  ButtonSegment(
                    value: ChartType.humidity,
                    label: Text('Rain %', style: TextStyle(fontSize: 11)),
                  ),
                ],
                selected: {_selectedChartType},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedChartType = newSelection.first;
                  });
                },
                style: const ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          HourlyTrendChart(
            hourlyList: weather.hourly,
            isMetric: isMetric,
            chartType: _selectedChartType,
          ),
          const Divider(color: Colors.white12, height: 24),
          const Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: Colors.cyanAccent, size: 16),
              SizedBox(width: 6),
              Text(
                '7-Day High / Low Range',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          DailyTrendChart(
            dailyList: weather.daily,
            isMetric: isMetric,
          ),
        ],
      ),
    );
  }
}
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
          if (weather.alerts.isNotEmpty) _buildAlertsBanner(context, weather.alerts),
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
          _buildTrendChartsCard(context, weather, provider.isMetric),
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

  Widget _buildAlertsBanner(BuildContext context, List<WeatherAlert> alerts) {
    final alert = alerts.first;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.redAccent.shade700,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showAlertDetailsSheet(context, alerts),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ ${alert.event} (${alerts.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alert.headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white90,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAlertDetailsSheet(BuildContext context, List<WeatherAlert> alerts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView.separated(
                controller: scrollController,
                itemCount: alerts.length,
                separatorBuilder: (_, __) => const Divider(height: 32),
                itemBuilder: (context, index) {
                  final a = alerts[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_rounded, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              a.event,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        a.headline,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent.shade200,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Affected Areas: ${a.areas}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (a.effective.isNotEmpty || a.expires.isNotEmpty)
                        Text(
                          'Period: ${a.effective} - ${a.expires}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        'Description',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        a.desc,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                      if (a.instruction.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Instructions / Safety Measures',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          a.instruction,
                          style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.amber),
                        ),
                      ],
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTrendChartsCard(BuildContext context, WeatherData weather, bool isMetric) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.show_chart_rounded, color: Colors.amberAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Weather Trends',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SegmentedButton<ChartType>(
                segments: const [
                  ButtonSegment(
                    value: ChartType.temperature,
                    label: Text('24h Temp', style: TextStyle(fontSize: 11)),
                  ),
                  ButtonSegment(
                    value: ChartType.humidity,
                    label: Text('Rain %', style: TextStyle(fontSize: 11)),
                  ),
                ],
                selected: {_selectedChartType},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedChartType = newSelection.first;
                  });
                },
                style: const ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          HourlyTrendChart(
            hourlyList: weather.hourly,
            isMetric: isMetric,
            chartType: _selectedChartType,
          ),
          const Divider(color: Colors.white12, height: 24),
          const Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: Colors.cyanAccent, size: 16),
              SizedBox(width: 6),
              Text(
                '7-Day High / Low Range',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          DailyTrendChart(
            dailyList: weather.daily,
            isMetric: isMetric,
          ),
        ],
      ),
    );
  }
}
