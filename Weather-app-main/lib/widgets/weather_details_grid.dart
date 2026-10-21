
import 'package:flutter/material.dart';
import '../models/weather_model.dart';

class WeatherDetailsGrid extends StatelessWidget {
  final WeatherData weather;
  final bool isMetric;

  const WeatherDetailsGrid({
    super.key,
    required this.weather,
    required this.isMetric,
  });

  String _getUvCategory(double uv) {
    if (uv <= 2) return 'Low';
    if (uv <= 5) return 'Moderate';
    if (uv <= 7) return 'High';
    if (uv <= 10) return 'Very High';
    return 'Extreme';
  }

  String _getAqiCategory(int epaIndex) {
    switch (epaIndex) {
      case 1:
        return 'Good (1)';
      case 2:
        return 'Moderate (2)';
      case 3:
        return 'Unhealthy for Sensitive (3)';
      case 4:
        return 'Unhealthy (4)';
      case 5:
        return 'Very Unhealthy (5)';
      case 6:
        return 'Hazardous (6)';
      default:
        return 'Moderate';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cur = weather.current;
    final todayForecast = weather.daily.isNotEmpty ? weather.daily.first : null;

    final windSpeed = isMetric ? '${cur.windKph.round()} km/h' : '${cur.windMph.round()} mph';
    final visibility = isMetric ? '${cur.visibilityKm.round()} km' : '${cur.visibilityMiles.round()} mi';
    final pressure = isMetric ? '${cur.pressureMb.round()} hPa' : '${cur.pressureIn.toStringAsFixed(2)} inHg';

    final items = [
      _DetailItem(
        icon: Icons.water_drop_rounded,
        title: 'HUMIDITY',
        value: '${cur.humidity}%',
        subtitle: 'Dew point is comfortable',
      ),
      _DetailItem(
        icon: Icons.air_rounded,
        title: 'WIND',
        value: windSpeed,
        subtitle: 'Direction: ${cur.windDir} (${cur.windDegree}°)',
      ),
      _DetailItem(
        icon: Icons.wb_sunny_rounded,
        title: 'UV INDEX',
        value: '${cur.uvIndex.toStringAsFixed(1)}',
        subtitle: _getUvCategory(cur.uvIndex),
      ),
      _DetailItem(
        icon: Icons.grain_rounded,
        title: 'AIR QUALITY (AQI)',
        value: _getAqiCategory(cur.aqiEpaIndex),
        subtitle: 'PM2.5: ${cur.aqiPm25.round()} µg/m³',
      ),
      _DetailItem(
        icon: Icons.wb_twilight_rounded,
        title: 'SUNRISE / SUNSET',
        value: todayForecast?.sunrise ?? '06:00 AM',
        subtitle: 'Sunset: ${todayForecast?.sunset ?? "06:30 PM"}',
      ),
      _DetailItem(
        icon: Icons.umbrella_rounded,
        title: 'PRECIPITATION',
        value: todayForecast != null ? '${todayForecast.totalRainMm} mm' : '0.0 mm',
        subtitle: todayForecast != null ? 'Chance: ${todayForecast.chanceOfRain}%' : '0%',
      ),
      _DetailItem(
        icon: Icons.speed_rounded,
        title: 'PRESSURE',
        value: pressure,
        subtitle: 'Atmospheric pressure',
      ),
      _DetailItem(
        icon: Icons.visibility_rounded,
        title: 'VISIBILITY',
        value: visibility,
        subtitle: cur.visibilityKm >= 10 ? 'Clear view' : 'Reduced visibility',
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.dashboard_rounded, color: Colors.white70, size: 18),
                SizedBox(width: 8),
                Text(
                  'ATMOSPHERIC DETAILS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return TweenAnimationBuilder<double>(
                key: ValueKey('${weather.location.name}_${weather.current.tempC}_$index'),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 70)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 16),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(item.icon, size: 18, color: Colors.white70),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        item.value,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DetailItem {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  _DetailItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });
}
