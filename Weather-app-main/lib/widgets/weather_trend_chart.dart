import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';

enum ChartType { temperature, humidity }

class HourlyTrendChart extends StatelessWidget {
  final List<HourlyForecast> hourlyList;
  final bool isMetric;
  final ChartType chartType;

  const HourlyTrendChart({
    super.key,
    required this.hourlyList,
    required this.isMetric,
    required this.chartType,
  });

  @override
  Widget build(BuildContext context) {
    if (hourlyList.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('No hourly chart data available.'),
        ),
      );
    }

    // Limit to next 24 hours
    final displayList = hourlyList.take(24).toList();

    List<FlSpot> spots = [];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < displayList.length; i++) {
      final h = displayList[i];
      final val = chartType == ChartType.temperature
          ? (isMetric ? h.tempC : h.tempF)
          : h.chanceOfRain.toDouble(); // or humidity

      if (val < minY) minY = val;
      if (val > maxY) maxY = val;

      spots.add(FlSpot(i.toDouble(), val));
    }

    if (minY == maxY) {
      minY -= 2;
      maxY += 2;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = chartType == ChartType.temperature
        ? (isDark ? Colors.amberAccent : Colors.orange.shade700)
        : (isDark ? Colors.cyanAccent : Colors.blue.shade700);

    return Container(
      height: 200,
      padding: const EdgeInsets.only(right: 18, left: 6, top: 18, bottom: 12),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? Colors.white10 : Colors.black12,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  return Text(
                    chartType == ChartType.temperature
                        ? '${value.round()}°'
                        : '${value.round()}%',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 4,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < displayList.length) {
                    final timeStr = displayList[index].time;
                    try {
                      final dt = DateTime.parse(timeStr);
                      return Text(
                        DateFormat('ha').format(dt).toLowerCase(),
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 10,
                        ),
                      );
                    } catch (_) {
                      return Text(
                        '$index h',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 10,
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (displayList.length - 1).toDouble(),
          minY: (minY - 3).floorToDouble(),
          maxY: (maxY + 3).ceilToDouble(),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.35),
                    primaryColor.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DailyTrendChart extends StatelessWidget {
  final List<DailyForecast> dailyList;
  final bool isMetric;

  const DailyTrendChart({
    super.key,
    required this.dailyList,
    required this.isMetric,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyList.isEmpty) return const SizedBox.shrink();

    List<FlSpot> highSpots = [];
    List<FlSpot> lowSpots = [];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < dailyList.length; i++) {
      final d = dailyList[i];
      final maxVal = isMetric ? d.maxTempC : d.maxTempF;
      final minVal = isMetric ? d.minTempC : d.minTempF;

      if (minVal < minY) minY = minVal;
      if (maxVal > maxY) maxY = maxVal;

      highSpots.add(FlSpot(i.toDouble(), maxVal));
      lowSpots.add(FlSpot(i.toDouble(), minVal));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 200,
      padding: const EdgeInsets.only(right: 18, left: 6, top: 18, bottom: 12),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? Colors.white10 : Colors.black12,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.round()}°',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < dailyList.length) {
                    final dateStr = dailyList[index].date;
                    try {
                      final dt = DateTime.parse(dateStr);
                      return Text(
                        DateFormat('E').format(dt),
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    } catch (_) {
                      return Text(
                        'D$index',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 10,
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (dailyList.length - 1).toDouble(),
          minY: (minY - 4).floorToDouble(),
          maxY: (maxY + 4).ceilToDouble(),
          lineBarsData: [
            // Max High Temp Line
            LineChartBarData(
              spots: highSpots,
              isCurved: true,
              color: Colors.orangeAccent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
            ),
            // Min Low Temp Line
            LineChartBarData(
              spots: lowSpots,
              isCurved: true,
              color: Colors.cyanAccent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}
