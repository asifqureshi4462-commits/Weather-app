import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../services/weather_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final WeatherService _weatherService = WeatherService();

  List<Map<String, String>> _suggestions = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isSearching = true);
      final results = await _weatherService.searchCities(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isSearching = false;
        });
      }
    });
  }

  void _selectCity(String cityName) {
    final provider = Provider.of<WeatherProvider>(context, listen: false);
    provider.loadWeatherForCity(cityName);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WeatherProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Search city or region...',
            hintStyle: const TextStyle(color: Colors.white60),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Colors.white70),
                    onPressed: () {
                      _searchController.clear();
                      _onQueryChanged('');
                    },
                  )
                : null,
          ),
          onChanged: _onQueryChanged,
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              _selectCity(val.trim());
            }
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isSearching)
            const LinearProgressIndicator(minHeight: 2)
          else
            const SizedBox(height: 2),

          if (_suggestions.isNotEmpty)
            Expanded(
              child: ListView.separated(
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _suggestions[index];
                  return ListTile(
                    leading: const Icon(Icons.location_city_rounded),
                    title: Text(item['name'] ?? ''),
                    subtitle: Text(item['fullName'] ?? ''),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () => _selectCity(item['query'] ?? item['name'] ?? ''),
                  );
                },
              ),
            )
          else if (_searchController.text.trim().length >= 2 && !_isSearching)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'No matching cities found.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            )
          else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'POPULAR CITIES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        'London',
                        'New York',
                        'Tokyo',
                        'Paris',
                        'Dubai',
                        'Sydney',
                        'Mumbai',
                        'Singapore',
                        'Toronto',
                        'Berlin',
                      ].map((city) {
                        return ActionChip(
                          avatar: const Icon(Icons.location_on_outlined, size: 16),
                          label: Text(city),
                          onPressed: () => _selectCity(city),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    if (provider.favoriteCities.isNotEmpty) ...[
                      const Text(
                        'SAVED FAVORITES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: provider.favoriteCities.length,
                          itemBuilder: (context, index) {
                            final city = provider.favoriteCities[index];
                            final weather = provider.favoritesWeather[city];
                            final tempStr = weather != null
                                ? (provider.isMetric
                                    ? '${weather.current.tempC.round()}°C'
                                    : '${weather.current.tempF.round()}°F')
                                : '';

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.star_rounded, color: Colors.amber),
                              title: Text(city),
                              subtitle: Text(weather?.current.conditionText ?? 'Saved location'),
                              trailing: Text(
                                tempStr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              onTap: () => _selectCity(city),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
