import 'dart:math' as math;
import '../models/weather_model.dart';

/// Builds helpful weather alerts from the forecast itself (rain soon, storms,
/// heat, cold, wind, UV, air quality, fog) so alerts work even when the weather
/// API has no official government warning for the area.
class SmartAlertService {
  /// Official API alerts + smart alerts, most severe first.
  static List<WeatherAlert> combine(WeatherData data, {required bool includeSmart}) {
    final list = <WeatherAlert>[...data.alerts];
    if (includeSmart) {
      try {
        list.addAll(generate(data));
      } catch (_) {
        // Never let alert generation break the app.
      }
    }
    list.sort((a, b) => rank(a.severity).compareTo(rank(b.severity)));
    return list;
  }

  static int rank(String severity) {
    switch (severity.toLowerCase()) {
      case 'extreme':
        return 0;
      case 'severe':
        return 1;
      case 'moderate':
        return 2;
      default:
        return 3;
    }
  }

  static List<WeatherAlert> generate(WeatherData w) {
    final out = <WeatherAlert>[];
    final city = w.location.name;
    final now = _parse(w.location.localtime) ?? DateTime.now();
    final dateKey = '${now.year}-${now.month}-${now.day}';
    final c = w.current;
    final today = w.daily.isNotEmpty ? w.daily.first : null;

    // Hours from now until the next 8 hours.
    final startOfHour = DateTime(now.year, now.month, now.day, now.hour);
    final upcoming = <HourlyForecast>[];
    for (final h in w.hourly) {
      final t = _parse(h.time);
      if (t == null) continue;
      if (!t.isBefore(startOfHour) && t.difference(startOfHour).inHours < 8) {
        upcoming.add(h);
      }
    }

    // Thunderstorm
    HourlyForecast? stormHour;
    for (final h in upcoming) {
      if (_has(h.conditionText, ['thunder'])) {
        stormHour = h;
        break;
      }
    }
    final stormNow = _has(c.conditionText, ['thunder']);
    if (stormNow || stormHour != null) {
      final when = stormNow ? 'right now' : 'around ${_clock(stormHour!.time)}';
      out.add(_mk(
        type: 'storm',
        city: city,
        dateKey: dateKey,
        event: 'Thunderstorm Warning',
        severity: 'Severe',
        urgency: stormNow ? 'Immediate' : 'Expected',
        headline: 'Thunderstorm possible $when in $city.',
        desc: 'Thunderstorms with lightning and heavy rain are forecast for your area.',
        instruction: 'Stay indoors, avoid open fields and tall trees, and unplug sensitive electronics.',
      ));
    }

    // Rain soon (skip if a storm alert already covers it)
    if (!(stormNow || stormHour != null)) {
      HourlyForecast? rainy;
      for (final h in upcoming) {
        if (h.chanceOfRain >= 60 || h.rainMm >= 1.0) {
          rainy = h;
          break;
        }
      }
      final rainingNow = _has(c.conditionText, ['rain', 'drizzle', 'shower']);
      if (rainingNow || rainy != null) {
        final headline = rainingNow
            ? 'It is raining in $city right now.'
            : 'Rain likely around ${_clock(rainy!.time)} in $city (${rainy.chanceOfRain}% chance).';
        out.add(_mk(
          type: 'rain',
          city: city,
          dateKey: dateKey,
          event: 'Rain Expected',
          severity: 'Moderate',
          urgency: rainingNow ? 'Immediate' : 'Expected',
          headline: headline,
          desc: 'Rain is expected in the next few hours. Roads may be slippery and visibility reduced.',
          instruction: 'Carry an umbrella or raincoat and drive carefully.',
        ));
      }
    }

    // Heat
    final peakHeat = math.max(today?.maxTempC ?? c.tempC, c.feelsLikeC);
    if (peakHeat >= 35) {
      final severity = peakHeat >= 42 ? 'Extreme' : (peakHeat >= 38 ? 'Severe' : 'Moderate');
      out.add(_mk(
        type: 'heat',
        city: city,
        dateKey: dateKey,
        event: peakHeat >= 42 ? 'Extreme Heat Warning' : 'Heat Advisory',
        severity: severity,
        headline: 'Very hot weather in $city, up to ${peakHeat.round()}°C today.',
        desc: 'High temperatures can cause heat exhaustion and heat stroke.',
        instruction: 'Drink plenty of water, avoid direct sun from noon to 4 PM, and check on children and the elderly.',
      ));
    }

    // Cold
    final lowest = math.min(today?.minTempC ?? c.tempC, c.tempC);
    if (lowest <= 0) {
      out.add(_mk(
        type: 'cold',
        city: city,
        dateKey: dateKey,
        event: lowest <= -10 ? 'Severe Cold Warning' : 'Freezing Temperature Alert',
        severity: lowest <= -10 ? 'Severe' : 'Moderate',
        headline: 'Freezing temperatures in $city, as low as ${lowest.round()}°C.',
        desc: 'Very low temperatures can cause frostbite and icy roads.',
        instruction: 'Dress in warm layers, protect pipes and pets, and drive carefully on ice.',
      ));
    }

    // Wind
    final wind = math.max(c.windKph, today?.maxWindKph ?? 0);
    if (wind >= 50) {
      out.add(_mk(
        type: 'wind',
        city: city,
        dateKey: dateKey,
        event: 'High Wind Alert',
        severity: wind >= 80 ? 'Severe' : 'Moderate',
        headline: 'Strong winds up to ${wind.round()} km/h expected in $city.',
        desc: 'Strong winds can bring down branches and make driving difficult.',
        instruction: 'Secure loose outdoor objects and avoid standing under trees or signboards.',
      ));
    }

    // UV
    final uv = math.max(c.uvIndex, today?.uvIndex ?? 0);
    if (uv >= 8) {
      out.add(_mk(
        type: 'uv',
        city: city,
        dateKey: dateKey,
        event: uv >= 11 ? 'Extreme UV Warning' : 'Very High UV Index',
        severity: uv >= 11 ? 'Severe' : 'Moderate',
        headline: 'UV index is ${uv.toStringAsFixed(0)} in $city today.',
        desc: 'Unprotected skin can burn in minutes.',
        instruction: 'Use SPF 30+ sunscreen, wear sunglasses and a hat, and seek shade at midday.',
      ));
    }

    // Air quality (US EPA index: 4 = Unhealthy, 5 = Very Unhealthy, 6 = Hazardous)
    if (c.aqiEpaIndex >= 4) {
      out.add(_mk(
        type: 'aqi',
        city: city,
        dateKey: dateKey,
        event: c.aqiEpaIndex >= 5 ? 'Hazardous Air Quality' : 'Poor Air Quality',
        severity: c.aqiEpaIndex >= 5 ? 'Severe' : 'Moderate',
        headline: 'Air quality is unhealthy in $city.',
        desc: 'Fine particles in the air can irritate the lungs and heart.',
        instruction: 'Limit outdoor exercise, wear a mask outside, and keep windows closed.',
      ));
    }

    // Fog / low visibility
    if (c.visibilityKm <= 1.0) {
      out.add(_mk(
        type: 'fog',
        city: city,
        dateKey: dateKey,
        event: 'Low Visibility Alert',
        severity: 'Moderate',
        headline: 'Visibility is only ${c.visibilityKm.toStringAsFixed(1)} km in $city.',
        desc: 'Fog, mist or haze is greatly reducing visibility.',
        instruction: 'Use low-beam headlights, slow down and keep a safe distance.',
      ));
    }

    return out;
  }

  static WeatherAlert _mk({
    required String type,
    required String city,
    required String dateKey,
    required String event,
    required String severity,
    required String headline,
    required String desc,
    required String instruction,
    String urgency = 'Expected',
  }) {
    return WeatherAlert(
      id: 'smart_${type}_${city}_$dateKey',
      headline: headline,
      msgType: 'Alert',
      severity: severity,
      urgency: urgency,
      areas: city,
      category: 'Smart',
      event: event,
      note: '',
      effective: '',
      expires: '',
      desc: desc,
      instruction: instruction,
    );
  }

  static bool _has(String text, List<String> words) {
    final lower = text.toLowerCase();
    for (final w in words) {
      if (lower.contains(w)) return true;
    }
    return false;
  }

  /// Parses "2026-10-11 14:05" and also WeatherAPI's un-padded "2026-10-1 5:05".
  static DateTime? _parse(String s) {
    try {
      final parts = s.trim().split(RegExp(r'\s+'));
      if (parts.isEmpty || parts[0].isEmpty) return null;
      final d = parts[0].split('-').map(int.parse).toList();
      if (d.length < 3) return null;
      int h = 0;
      int m = 0;
      if (parts.length > 1) {
        final tm = parts[1].split(':');
        h = int.parse(tm[0]);
        m = tm.length > 1 ? int.parse(tm[1]) : 0;
      }
      return DateTime(d[0], d[1], d[2], h, m);
    } catch (_) {
      return null;
    }
  }

  static String _clock(String time) {
    final t = _parse(time);
    if (t == null) return 'soon';
    final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final suffix = t.hour >= 12 ? 'PM' : 'AM';
    return '$h12 $suffix';
  }
}
