import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../services/storage_service.dart';
import '../widgets/permission_dialogs.dart';
import 'alerts_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomApiKey();
  }

  Future<void> _loadCustomApiKey() async {
    final key = await _storageService.getCustomApiKey();
    if (key != null && mounted) {
      _apiKeyController.text = key;
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Colors.grey,
      ),
    );
  }

  String _locationStatusText(WeatherProvider provider) {
    switch (provider.locationIssue) {
      case LocationIssue.none:
        final name = provider.gpsWeather?.location.name;
        return name != null ? 'Active • $name' : 'Active';
      case LocationIssue.serviceDisabled:
        return 'GPS is turned off';
      case LocationIssue.permissionDenied:
        return 'Location permission needed';
      case LocationIssue.permissionDeniedForever:
        return 'Blocked - enable in app settings';
      case LocationIssue.unavailable:
        return 'No GPS fix yet';
    }
  }

  String _locationActionLabel(WeatherProvider provider) {
    switch (provider.locationIssue) {
      case LocationIssue.none:
        return 'Refresh';
      case LocationIssue.serviceDisabled:
        return 'Turn on';
      case LocationIssue.permissionDenied:
        return 'Allow';
      case LocationIssue.permissionDeniedForever:
        return 'Settings';
      case LocationIssue.unavailable:
        return 'Retry';
    }
  }

  Future<void> _onLocationAction(WeatherProvider provider) async {
    switch (provider.locationIssue) {
      case LocationIssue.none:
      case LocationIssue.unavailable:
        final ok = await provider.refreshLocation();
        _snack(ok ? 'Location updated.' : 'Could not update location.');
        break;
      case LocationIssue.serviceDisabled:
        final go = await PermissionDialogs.showGpsOff(context);
        if (go == true) await provider.openLocationSettings();
        break;
      case LocationIssue.permissionDenied:
        final go = await PermissionDialogs.showLocationPermission(context);
        if (go == true) await provider.requestLocationPermission();
        break;
      case LocationIssue.permissionDeniedForever:
        final go = await PermissionDialogs.showLocationSettings(context);
        if (go == true) await provider.openAppSettings();
        break;
    }
  }

  Future<void> _onNotificationAllow(WeatherProvider provider) async {
    final granted = await provider.requestNotificationPermission();
    if (!mounted) return;
    if (granted) {
      _snack('Notifications enabled.');
      return;
    }
    final permanent = await provider.isNotificationPermanentlyDenied();
    if (!mounted) return;
    if (permanent) {
      final open = await PermissionDialogs.showNotificationSettings(context);
      if (open == true) await provider.openAppSettings();
    } else {
      _snack('Notification permission was not granted.');
    }
  }

  Future<void> _onTestNotification(WeatherProvider provider) async {
    final ok = await provider.sendTestNotification();
    if (!mounted) return;
    if (ok) {
      _snack('Test alert sent! Check your notification shade.');
    } else {
      final permanent = await provider.isNotificationPermanentlyDenied();
      if (!mounted) return;
      if (permanent) {
        final open = await PermissionDialogs.showNotificationSettings(context);
        if (open == true) await provider.openAppSettings();
      } else {
        _snack('Notification permission was not granted.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WeatherProvider>(context);
    final gpsOk = provider.locationIssue == LocationIssue.none;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('LOCATION'),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: PulsingIcon(
                icon: gpsOk ? Icons.my_location_rounded : Icons.location_disabled_rounded,
                color: gpsOk ? Colors.green : Colors.orange,
                size: 18,
                active: provider.isLocating,
              ),
              title: const Text('Location / GPS'),
              subtitle: Text(_locationStatusText(provider)),
              trailing: FilledButton.tonal(
                onPressed: provider.isLocating ? null : () => _onLocationAction(provider),
                child: Text(_locationActionLabel(provider)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('UNITS & MEASUREMENT'),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.thermostat_rounded),
                  title: const Text('Temperature Unit'),
                  subtitle: Text(provider.isMetric ? 'Celsius (°C) & km/h' : 'Fahrenheit (°F) & mph'),
                  value: provider.isMetric,
                  onChanged: (_) => provider.toggleUnitSystem(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('NOTIFICATIONS & ALERTS'),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    provider.notificationsGranted
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_rounded,
                    color: provider.notificationsGranted ? Colors.green : Colors.orange,
                  ),
                  title: const Text('Notification permission'),
                  subtitle: Text(provider.notificationsGranted ? 'Allowed' : 'Not allowed yet'),
                  trailing: provider.notificationsGranted
                      ? const Icon(Icons.check_circle_rounded, color: Colors.green)
                      : FilledButton.tonal(
                          onPressed: () => _onNotificationAllow(provider),
                          child: const Text('Allow'),
                        ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.warning_amber_rounded),
                  title: const Text('Weather Alerts'),
                  subtitle: const Text('Smart alerts: rain, storm, heat, wind, UV, air quality'),
                  value: provider.alertsEnabled,
                  onChanged: (val) => provider.setAlertsEnabled(val),
                ),
                ListTile(
                  leading: const Icon(Icons.list_alt_rounded),
                  title: const Text('View active alerts'),
                  subtitle: Text(provider.currentAlerts.isEmpty
                      ? 'No active alerts'
                      : '${provider.currentAlerts.length} active alert(s)'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AlertsScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.wb_twilight_rounded),
                  title: const Text('Daily Morning Weather Summary'),
                  subtitle: const Text('Scheduled daily forecast summary for active city'),
                  value: provider.dailyNotifEnabled,
                  onChanged: (val) => provider.setDailyNotifEnabled(val),
                ),
                if (provider.dailyNotifEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.access_time_rounded),
                    title: const Text('Summary Time'),
                    subtitle: Text(
                      TimeOfDay(
                        hour: provider.dailyNotifHour,
                        minute: provider.dailyNotifMinute,
                      ).format(context),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: provider.dailyNotifHour,
                          minute: provider.dailyNotifMinute,
                        ),
                      );
                      if (picked != null) {
                        await provider.setDailyNotifTime(picked.hour, picked.minute);
                      }
                    },
                  ),
                ],
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notification_add_rounded),
                  title: const Text('Send Test Alert'),
                  subtitle: const Text('Shows a real notification right now'),
                  trailing: const Icon(Icons.send_rounded),
                  onTap: () => _onTestNotification(provider),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('APPEARANCE & THEME'),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                RadioListTile<String>(
                  secondary: const Icon(Icons.brightness_auto_rounded),
                  title: const Text('System Default'),
                  value: 'system',
                  groupValue: provider.themeMode,
                  onChanged: (val) => provider.setThemeMode(val!),
                ),
                RadioListTile<String>(
                  secondary: const Icon(Icons.wb_sunny_rounded),
                  title: const Text('Light Theme'),
                  value: 'light',
                  groupValue: provider.themeMode,
                  onChanged: (val) => provider.setThemeMode(val!),
                ),
                RadioListTile<String>(
                  secondary: const Icon(Icons.nights_stay_rounded),
                  title: const Text('Dark Theme'),
                  value: 'dark',
                  groupValue: provider.themeMode,
                  onChanged: (val) => provider.setThemeMode(val!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('API KEY OVERRIDE (OPTIONAL)'),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Use your own WeatherAPI.com key instead of the built-in one. Leave empty to use the default key.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiKeyController,
                    decoration: const InputDecoration(
                      labelText: 'WeatherAPI.com Key',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.key_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () async {
                          _apiKeyController.clear();
                          await _storageService.setCustomApiKey('');
                          _snack('Custom API key removed. Using the default key.');
                          provider.init();
                        },
                        child: const Text('Clear'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Save Key'),
                        onPressed: () async {
                          final newKey = _apiKeyController.text.trim();
                          await _storageService.setCustomApiKey(newKey);
                          _snack('API key saved. Reloading weather...');
                          provider.init();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('ABOUT APP & DEVELOPER'),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/app_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF1565C0),
                          child: const Icon(Icons.wb_sunny_rounded, color: Colors.amberAccent),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Atmosphere Weather v1.1.0',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Developed by Asif Qureshi',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Live Weather, Severe Alerts & Radar',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
