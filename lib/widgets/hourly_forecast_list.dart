import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';

class HourlyForecastList extends StatelessWidget {
  final List<HourlyForecast> hourlyList;
  final bool isMetric;

  const HourlyForecastList({
    super.key,
    required this.hourlyList,
    required this.isMetric,
  });

  @override
  Widget build(BuildContext context) {
    if (hourlyList.isEmpty) return const SizedBox.shrink();

    // Show upcoming 24 hours
    final items = hourlyList.take(24).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.access_time_rounded, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text(
                'HOURLY FORECAST (24 HRS)',
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
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final temp = isMetric ? '${item.tempC.round()}°' : '${item.tempF.round()}°';

              DateTime dt;
              try {
                dt = DateTime.parse(item.time);
              } catch (_) {
                dt = DateTime.now().add(Duration(hours: index));
              }

              final timeStr = index == 0 ? 'Now' : DateFormat('ha').format(dt);

              String iconUrl = item.conditionIcon;
              if (iconUrl.startsWith('//')) {
                iconUrl = 'https:$iconUrl';
              }

              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    if (iconUrl.isNotEmpty)
                      Image.network(
                        iconUrl,
                        width: 36,
                        height: 36,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.cloud,
                          size: 30,
                          color: Colors.white70,
                        ),
                      ),
                    if (item.chanceOfRain > 0)
                      Text(
                        '${item.chanceOfRain}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.lightBlueAccent,
                        ),
                      ),
                    Text(
                      temp,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
