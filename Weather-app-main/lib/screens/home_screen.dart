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
import '../widgets/permission_dialogs.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import 'radar_screen.dart';
import 'alerts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  ChartType _selectedChartType = ChartType.temperature;
  late final WeatherProvider _provider;
  bool _dialogBusy = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _provider = context.read<WeatherProvider>();
    _provider.addListener(_onProviderChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startup());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _provider.removeListener(_onProviderChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Every time the app is opened / returns from Settings, refresh GPS location + weather.
    if (state == AppLifecycleState.resumed) {
      _provider.onAppResumed();
    }
  }

  void _onProviderChanged() {
    final msg = _provider.consumeToast();
    if (msg != null && mounted) _snack(msg);
  }

  void _snack(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: action,
      ));
  }

  // ---------------------------------------------------------------------------
  // Startup: GPS permission -> GPS on -> notification permission
  // ---------------------------------------------------------------------------
  Future<void> _startup() async {
    if (_started) return;
    _started = true;

    try {
      await _provider.ready;
      if (!mounted) return;
      await _handleLocationIssue();
      if (!mounted) return;
      await _handleNotificationPermission();
    } catch (e) {
      debugPrint('Startup permission flow error: $e');
    }
  }

  Future<void> _handleLocationIssue({int depth = 0}) async {
    if (_dialogBusy || !mounted || depth > 2) return;

    final issue = _provider.locationIssue;
    if (issue == LocationIssue.none) return;

    _dialogBusy = true;
    try {
      switch (issue) {
        case LocationIssue.serviceDisabled:
          final go = await PermissionDialogs.showGpsOff(context);
          if (go == true) {
            // Opens the system location settings. When the user switches GPS on and
            // comes back, the weather refreshes automatically.
            await _provider.openLocationSettings();
          }
          break;
        case LocationIssue.permissionDenied:
          final go = await PermissionDialogs.showLocationPermission(context);
          if (go == true) {
            await _provider.requestLocationPermission();
          }
          break;
        case LocationIssue.permissionDeniedForever:
          final go = await PermissionDialogs.showLocationSettings(context);
          if (go == true) {
            await _provider.openAppSettings();
          }
          break;
        case LocationIssue.unavailable:
          _snack('Could not get a GPS fix yet. Please try again in a moment.');
          break;
        case LocationIssue.none:
          break;
      }
    } finally {
      _dialogBusy = false;
    }

    // Permission just granted but GPS is still off -> ask to turn GPS on too.
    if (mounted &&
        issue == LocationIssue.permissionDenied &&
        _provider.locationIssue == LocationIssue.serviceDisabled) {
      await _handleLocationIssue(depth: depth + 1);
    }
  }

  Future<void> _handleNotificationPermission() async {
    if (_dialogBusy || !mounted) return;
    if (_provider.notificationsGranted || _provider.notifPromptDismissed) return;

    _dialogBusy = true;
    try {
      final go = await PermissionDialogs.showNotificationPermission(context);
      if (go == true) {
        final granted = await _provider.requestNotificationPermission();
        if (!granted && mounted) {
          final permanent = await _provider.isNotificationPermanentlyDenied();
          if (permanent && mounted) {
            final open = await PermissionDialogs.showNotificationSettings(context);
            if (open == true) await _provider.openAppSettings();
          }
        }
      } else {
        await _provider.dismissNotifPrompt();
      }
    } finally {
      _dialogBusy = false;
    }
  }

  Future<void> _onGpsPressed() async {
    final ok = await _provider.refreshLocation();
    if (!mounted) return;
    if (ok) {
      final name = _provider.currentWeather?.location.name ?? '';
      _snack('Location updated: $name');
    } else if (_provider.locationIssue != LocationIssue.none) {
      await _handleLocationIssue();
    }
  }

  Future<void> _onRefresh() async {
    await _provider.refreshCurrent();
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WeatherProvider>(context);
    final alertCount = provider.currentAlerts.length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 8,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/app_icon.png',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.wb_sunny_rounded, color: Colors.amberAccent),
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Atmosphere',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            padding: EdgeInsets.zero,
            iconSize: 48,
            tooltip: 'Update my location',
            onPressed: _onGpsPressed,
            icon: PulsingIcon(
              icon: provider.locationIssue == LocationIssue.none
                  ? Icons.my_location_rounded
                  : Icons.location_disabled_rounded,
              color: provider.locationIssue == LocationIssue.none
                  ? Colors.white
                  : Colors.orangeAccent,
              size: 22,
              active: provider.isLocating,
            ),
          ),
          IconButton(
            tooltip: 'Weather Alerts',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlertsScreen()),
              );
            },
            icon: Badge(
              isLabelVisible: alertCount > 0,
              label: Text('$alertCount'),
              child: const Icon(Icons.notifications_rounded, color: Colors.white),
            ),
          ),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onSelected: (value) {
              if (value == 'favorites') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                );
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'favorites',
                child: ListTile(
                  leading: Icon(Icons.bookmarks_rounded),
                  title: Text('Saved Locations'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings_rounded),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: WeatherBackground(
        conditionText: provider.currentWeather?.current.conditionText ?? 'Clear',
        isDay: provider.currentWeather?.current.isDay ?? true,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: _buildBody(provider),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(WeatherProvider provider) {
    if (provider.isLoading && provider.currentWeather == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const Center(
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
            ),
          ),
        ],
      );
    }

    if (provider.errorMessage != null && provider.currentWeather == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
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
        ],
      );
    }

    final weather = provider.currentWeather;
    if (weather == null) return ListView(physics: const AlwaysScrollableScrollPhysics());

    final alerts = provider.currentAlerts;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildStatusStrip(provider),
          if (alerts.isNotEmpty) _buildAlertsBanner(context, alerts),
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

  String _ago(DateTime? time) {
    if (time == null) return 'just now';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    return '${diff.inHours} h ago';
  }

  /// Small animated line under the app bar: locating / GPS off / last updated.
  Widget _buildStatusStrip(WeatherProvider provider) {
    final issue = provider.locationIssue;
    Widget content;
    String key;

    if (provider.isLocating) {
      key = 'locating';
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          PulsingIcon(icon: Icons.my_location_rounded, color: Colors.lightBlueAccent, size: 14),
          SizedBox(width: 6),
          Text('Updating your location...',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      );
    } else if (issue != LocationIssue.none) {
      key = 'issue_${issue.name}';
      String text;
      switch (issue) {
        case LocationIssue.serviceDisabled:
          text = 'GPS is off - tap to turn it on';
          break;
        case LocationIssue.permissionDenied:
          text = 'Location permission needed - tap to allow';
          break;
        case LocationIssue.permissionDeniedForever:
          text = 'Location blocked - tap to open settings';
          break;
        default:
          text = 'GPS not available - tap to retry';
      }
      content = InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (issue == LocationIssue.unavailable) {
            _onGpsPressed();
          } else {
            _handleLocationIssue();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade800.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_disabled_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(text,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    } else {
      key = 'updated_${provider.usingGps}_${provider.lastUpdated?.minute}';
      content = Text(
        provider.usingGps
            ? '📍 My location • Updated ${_ago(provider.lastUpdated)}'
            : 'Updated ${_ago(provider.lastUpdated)}',
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SizeTransition(sizeFactor: animation, child: child),
        ),
        child: KeyedSubtree(key: ValueKey(key), child: Center(child: content)),
      ),
    );
  }

  Widget _buildAlertsBanner(BuildContext context, List<WeatherAlert> alerts) {
    final alert = alerts.first;
    final color = alertColor(alert.severity);

    return TweenAnimationBuilder<double>(
      key: ValueKey(alert.id),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, (1 - value) * -18), child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color,
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlertsScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(alertIcon(alert.event), color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alerts.length > 1
                              ? '${alert.event}  (+${alerts.length - 1} more)'
                              : alert.event,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          alert.headline,
                          maxLines: 2,
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
      ),
    );
  }

  Widget _buildTrendChartsCard(BuildContext context, WeatherData weather, bool isMetric) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
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
