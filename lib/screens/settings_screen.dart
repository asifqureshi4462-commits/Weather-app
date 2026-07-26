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
            'ABOUT APP',
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
            child: const ListTile(
              leading: Icon(Icons.info_outline_rounded),
              title: Text('Atmosphere Weather v1.0.0'),
              subtitle: Text('Built with Flutter, Material 3 & GitHub Actions CI/CD'),
            ),
          ),
        ],
      ),
    );
  }
}
