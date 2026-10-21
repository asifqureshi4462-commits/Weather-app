import 'package:flutter/material.dart';

class WeatherBackground extends StatelessWidget {
  final String conditionText;
  final bool isDay;
  final Widget child;

  const WeatherBackground({
    super.key,
    required this.conditionText,
    required this.isDay,
    required this.child,
  });

  List<Color> _getGradientColors(BuildContext context) {
    final lower = conditionText.toLowerCase();

    if (!isDay) {
      return const [
        Color(0xFF0F2027),
        Color(0xFF203A43),
        Color(0xFF2C5364),
      ];
    }

    if (lower.contains('rain') || lower.contains('drizzle') || lower.contains('shower')) {
      return const [
        Color(0xFF373B44),
        Color(0xFF4286F4),
        Color(0xFF3A6073),
      ];
    } else if (lower.contains('snow') || lower.contains('ice') || lower.contains('sleet') || lower.contains('blizzard')) {
      return const [
        Color(0xFF83A4D4),
        Color(0xFFB6FBFF),
      ];
    } else if (lower.contains('thunder') || lower.contains('storm')) {
      return const [
        Color(0xFF141E30),
        Color(0xFF243B55),
        Color(0xFF3F2B96),
      ];
    } else if (lower.contains('cloud') || lower.contains('overcast') || lower.contains('mist') || lower.contains('fog')) {
      return const [
        Color(0xFF606C38),
        Color(0xFF283618),
        Color(0xFF4A5568),
      ];
    } else {
      // Clear / Sunny
      return const [
        Color(0xFF2980B9),
        Color(0xFF6DD5FA),
        Color(0xFFFFFFFF),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getGradientColors(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: child,
    );
  }
}
