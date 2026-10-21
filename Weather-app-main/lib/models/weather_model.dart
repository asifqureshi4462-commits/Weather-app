import 'package:flutter/foundation.dart';

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
    if (json == null) {
      return LocationData(
        name: 'Unknown',
        region: '',
        country: '',
        lat: 0.0,
        lon: 0.0,
        localtime: '',
      );
    }
    return LocationData(
      name: json['name']?.toString() ?? 'Unknown City',
      region: json['region']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      localtime: json['localtime']?.toString() ?? '',
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
    if (json == null) {
      return CurrentWeather(
        tempC: 0.0,
        tempF: 32.0,
        feelsLikeC: 0.0,
        feelsLikeF: 32.0,
        conditionText: 'Clear',
        conditionIcon: '//cdn.weatherapi.com/weather/64x64/day/113.png',
        conditionCode: 1000,
        humidity: 50,
        windKph: 0.0,
        windMph: 0.0,
        windDegree: 0,
        windDir: 'N',
        uvIndex: 0.0,
        aqiPm25: 0.0,
        aqiPm10: 0.0,
        aqiEpaIndex: 1,
        pressureMb: 1013.0,
        pressureIn: 29.92,
        visibilityKm: 10.0,
        visibilityMiles: 6.0,
        isDay: true,
      );
    }

    final cond = json['condition'] as Map<String, dynamic>?;
    final aqi = json['air_quality'] as Map<String, dynamic>?;

    return CurrentWeather(
      tempC: (json['temp_c'] as num?)?.toDouble() ?? 0.0,
      tempF: (json['temp_f'] as num?)?.toDouble() ?? 32.0,
      feelsLikeC: (json['feelslike_c'] as num?)?.toDouble() ?? (json['temp_c'] as num?)?.toDouble() ?? 0.0,
      feelsLikeF: (json['feelslike_f'] as num?)?.toDouble() ?? (json['temp_f'] as num?)?.toDouble() ?? 32.0,
      conditionText: cond?['text']?.toString() ?? 'Clear',
      conditionIcon: cond?['icon']?.toString() ?? '//cdn.weatherapi.com/weather/64x64/day/113.png',
      conditionCode: (cond?['code'] as num?)?.toInt() ?? 1000,
      humidity: (json['humidity'] as num?)?.toInt() ?? 0,
      windKph: (json['wind_kph'] as num?)?.toDouble() ?? 0.0,
      windMph: (json['wind_mph'] as num?)?.toDouble() ?? 0.0,
      windDegree: (json['wind_degree'] as num?)?.toInt() ?? 0,
      windDir: json['wind_dir']?.toString() ?? 'N',
      uvIndex: (json['uv'] as num?)?.toDouble() ?? 0.0,
      aqiPm25: (aqi?['pm2_5'] as num?)?.toDouble() ?? 0.0,
      aqiPm10: (aqi?['pm10'] as num?)?.toDouble() ?? 0.0,
      aqiEpaIndex: (aqi?['us-epa-index'] as num?)?.toInt() ?? 1,
      pressureMb: (json['pressure_mb'] as num?)?.toDouble() ?? 1013.0,
      pressureIn: (json['pressure_in'] as num?)?.toDouble() ?? 29.92,
      visibilityKm: (json['vis_km'] as num?)?.toDouble() ?? 10.0,
      visibilityMiles: (json['vis_miles'] as num?)?.toDouble() ?? 6.2,
      isDay: ((json['is_day'] as num?)?.toInt() ?? 1) == 1,
    );
  }
}

class HourlyForecast {
  final String time;
  final double tempC;
  final double tempF;
  final String conditionText;
  final String conditionIcon;
  final int chanceOfRain;
  final double rainMm;
  final bool isDay;

  HourlyForecast({
    required this.time,
    required this.tempC,
    required this.tempF,
    required this.conditionText,
    required this.conditionIcon,
    required this.chanceOfRain,
    required this.rainMm,
    required this.isDay,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    final cond = json['condition'] as Map<String, dynamic>?;
    return HourlyForecast(
      time: json['time']?.toString() ?? '',
      tempC: (json['temp_c'] as num?)?.toDouble() ?? 0.0,
      tempF: (json['temp_f'] as num?)?.toDouble() ?? 32.0,
      conditionText: cond?['text']?.toString() ?? 'Clear',
      conditionIcon: cond?['icon']?.toString() ?? '',
      chanceOfRain: (json['chance_of_rain'] as num?)?.toInt() ?? 0,
      rainMm: (json['precip_mm'] as num?)?.toDouble() ?? 0.0,
      isDay: ((json['is_day'] as num?)?.toInt() ?? 1) == 1,
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
    );
  }
}

class WeatherAlert {
  final String id;
  final String headline;
  final String msgType;
  final String severity;
  final String urgency;
  final String areas;
  final String category;
  final String event;
  final String note;
  final String effective;
  final String expires;
  final String desc;
  final String instruction;

  WeatherAlert({
    required this.id,
    required this.headline,
    required this.msgType,
    required this.severity,
    required this.urgency,
    required this.areas,
    required this.category,
    required this.event,
    required this.note,
    required this.effective,
    required this.expires,
    required this.desc,
    required this.instruction,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    final eventStr = json['event']?.toString() ?? 'Weather Alert';
    final effStr = json['effective']?.toString() ?? '';
    final expStr = json['expires']?.toString() ?? '';
    final headlineStr = json['headline']?.toString() ?? 'Severe Weather Warning';

    return WeatherAlert(
      id: '${eventStr}_${effStr}_$expStr',
      headline: headlineStr,
      msgType: json['msgtype']?.toString() ?? 'Alert',
      severity: json['severity']?.toString() ?? 'Moderate',
      urgency: json['urgency']?.toString() ?? 'Expected',
      areas: json['areas']?.toString() ?? 'Local Region',
      category: json['category']?.toString() ?? 'Met',
      event: eventStr,
      note: json['note']?.toString() ?? '',
      effective: effStr,
      expires: expStr,
      desc: json['desc']?.toString() ?? 'No detailed description provided by weather authority.',
      instruction: json['instruction']?.toString() ?? 'Take precautions and follow local weather updates.',
    );
  }
}

class WeatherData {
  final LocationData location;
  final CurrentWeather current;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;
  final List<WeatherAlert> alerts;

  WeatherData({
    required this.location,
    required this.current,
    required this.hourly,
    required this.daily,
    required this.alerts,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final location = LocationData.fromJson(json['location'] as Map<String, dynamic>?);
    final current = CurrentWeather.fromJson(json['current'] as Map<String, dynamic>?);

    List<HourlyForecast> hourlyList = [];
    List<DailyForecast> dailyList = [];
    List<WeatherAlert> alertsList = [];

    final forecastObj = json['forecast'] as Map<String, dynamic>?;
    final forecastDays = forecastObj?['forecastday'] as List<dynamic>?;

    if (forecastDays != null && forecastDays.isNotEmpty) {
      for (var dayJson in forecastDays) {
        if (dayJson is Map<String, dynamic>) {
          dailyList.add(DailyForecast.fromJson(dayJson));

          final hourArray = dayJson['hour'] as List<dynamic>?;
          if (hourArray != null) {
            for (var hourJson in hourArray) {
              if (hourJson is Map<String, dynamic>) {
                hourlyList.add(HourlyForecast.fromJson(hourJson));
              }
            }
          }
        }
      }
    }

    final alertsObj = json['alerts'] as Map<String, dynamic>?;
    final alertArray = alertsObj?['alert'] as List<dynamic>?;
    if (alertArray != null) {
      for (var alertJson in alertArray) {
        if (alertJson is Map<String, dynamic>) {
          alertsList.add(WeatherAlert.fromJson(alertJson));
        }
      }
    }

    return WeatherData(
      location: location,
      current: current,
      hourly: hourlyList,
      daily: dailyList,
      alerts: alertsList,
    );
  }
}
