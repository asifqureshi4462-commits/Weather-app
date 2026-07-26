import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../services/storage_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WeatherProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'UNITS & MEASUREMENT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.grey,
            ),
          ),
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
          const Text(
            'NOTIFICATIONS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_rounded),
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
                  title: const Text('Test Immediate Alert'),
                  subtitle: const Text('Trigger a test notification now'),
                  trailing: const Icon(Icons.send_rounded),
                  onTap: () async {
                    await provider.syncDailyNotification();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Triggered test notification! Check your notification shade.'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'APPEARANCE & THEME',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.grey,
            ),
          ),
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
          const Text(
            'API KEY OVERRIDE (OPTIONAL)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Provide a custom WeatherAPI.com API Key if you want to bypass default or secret keys:',
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save Key'),
                      onPressed: () async {
                        final newKey = _apiKeyController.text.trim();
                        await _storageService.setCustomApiKey(newKey);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Custom API Key saved locally.')),
                          );
                          provider.init();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ABOUT APP & DEVELOPER',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.grey,
            ),
          ),
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
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/app_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset('assets/splash_icon.png'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Atmosphere Weather v1.0.0',
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
