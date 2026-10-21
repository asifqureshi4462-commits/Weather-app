import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import 'search_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WeatherProvider>(context);
    final gps = provider.gpsWeather;
    final hasFavorites = provider.favoriteCities.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Locations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_rounded),
            tooltip: 'Add location',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: (!hasFavorites && gps == null)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bookmark_border_rounded, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No Favorite Cities',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Search and save locations for quick access.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text('Add Location'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      );
                    },
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: provider.refreshAllFavorites,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (gps != null) ...[
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Icon(
                          Icons.my_location_rounded,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        title: Text(
                          gps.location.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('My Location • ${gps.current.conditionText}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              provider.isMetric
                                  ? '${gps.current.tempC.round()}°C'
                                  : '${gps.current.tempF.round()}°F',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                        onTap: () {
                          provider.useGpsLocation();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                  for (final city in provider.favoriteCities)
                    _buildFavoriteTile(context, provider, city),
                ],
              ),
            ),
    );
  }

  Widget _buildFavoriteTile(BuildContext context, WeatherProvider provider, String city) {
    final weather = provider.favoritesWeather[city];
    final cur = weather?.current;

    final tempStr = cur != null
        ? (provider.isMetric ? '${cur.tempC.round()}°C' : '${cur.tempF.round()}°F')
        : '--';

    return Dismissible(
      key: ValueKey('fav_$city'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        provider.removeFavorite(city);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed $city from saved locations.')),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Text(
            city,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(cur?.conditionText ?? 'Tap to view forecast'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tempStr,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
          onTap: () {
            provider.loadWeatherForCity(city);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
