import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';

class DailyForecastList extends StatelessWidget {
  final List<DailyForecast> dailyList;
  final bool isMetric;

  const DailyForecastList({
    super.key,
    required this.dailyList,
    required this.isMetric,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyList.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text(
                '7-DAY FORECAST',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dailyList.length,
            separatorBuilder: (_, __) => Divider(
              color: Colors.white.withValues(alpha: 0.1),
              height: 16,
            ),
            itemBuilder: (context, index) {
              final day = dailyList[index];

              DateTime dt;
              try {
                dt = DateTime.parse(day.date);
              } catch (_) {
                dt = DateTime.now().add(Duration(days: index));
              }

              final dayName = index == 0 ? 'Today' : DateFormat('EEEE').format(dt);

              final maxTemp = isMetric ? '${day.maxTempC.round()}°' : '${day.maxTempF.round()}°';
              final minTemp = isMetric ? '${day.minTempC.round()}°' : '${day.minTempF.round()}°';

              String iconUrl = day.conditionIcon;
              if (iconUrl.startsWith('//')) {
                iconUrl = 'https:$iconUrl';
              }

              return Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      dayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (iconUrl.isNotEmpty)
                    Image.network(
                      iconUrl,
                      width: 32,
                      height: 32,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.wb_sunny_outlined,
                        size: 24,
                        color: Colors.white70,
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (day.chanceOfRain > 0)
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${day.chanceOfRain}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.lightBlueAccent,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      day.conditionText,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    maxTemp,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    minTemp,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
