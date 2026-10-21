import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather_model.dart';
import '../providers/weather_provider.dart';
import '../widgets/permission_dialogs.dart';

Color alertColor(String severity) {
  switch (severity.toLowerCase()) {
    case 'extreme':
      return const Color(0xFFB71C1C);
    case 'severe':
      return const Color(0xFFD32F2F);
    case 'moderate':
      return const Color(0xFFEF6C00);
    default:
      return const Color(0xFFF9A825);
  }
}

IconData alertIcon(String event) {
  final e = event.toLowerCase();
  if (e.contains('thunder') || e.contains('storm') || e.contains('lightning')) {
    return Icons.thunderstorm_rounded;
  }
  if (e.contains('rain') || e.contains('flood')) return Icons.umbrella_rounded;
  if (e.contains('heat') || e.contains('hot')) return Icons.wb_sunny_rounded;
  if (e.contains('cold') || e.contains('freez') || e.contains('snow') || e.contains('frost')) {
    return Icons.ac_unit_rounded;
  }
  if (e.contains('wind')) return Icons.air_rounded;
  if (e.contains('uv')) return Icons.light_mode_rounded;
  if (e.contains('air')) return Icons.masks_rounded;
  if (e.contains('visib') || e.contains('fog')) return Icons.foggy;
  return Icons.warning_amber_rounded;
}

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  Future<void> _sendTest(BuildContext context, WeatherProvider provider) async {
    final ok = await provider.sendTestNotification();
    if (!context.mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test alert sent! Check your notification shade.')),
      );
      return;
    }

    final permanent = await provider.isNotificationPermanentlyDenied();
    if (!context.mounted) return;
    if (permanent) {
      final open = await PermissionDialogs.showNotificationSettings(context);
      if (open == true) await provider.openAppSettings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification permission was not granted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WeatherProvider>(context);
    final alerts = provider.currentAlerts;
    final city = provider.currentWeather?.location.name ?? 'your area';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notification_add_rounded),
            tooltip: 'Send test alert',
            onPressed: () => _sendTest(context, provider),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SwitchListTile(
              secondary: const Icon(Icons.auto_awesome_rounded),
              title: const Text('Smart alerts & notifications'),
              subtitle: const Text('Rain, storms, heat, cold, wind, UV and air quality alerts'),
              value: provider.alertsEnabled,
              onChanged: (v) => provider.setAlertsEnabled(v),
            ),
          ),
          const SizedBox(height: 16),
          if (alerts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  const PulsingIcon(icon: Icons.verified_rounded, color: Colors.green, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'All clear!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'No active weather alerts for $city.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            for (var i = 0; i < alerts.length; i++) _AlertCard(alert: alerts[i], index: i),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final WeatherAlert alert;
  final int index;

  const _AlertCard({required this.alert, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = alertColor(alert.severity);
    final isSmart = alert.category == 'Smart';

    return TweenAnimationBuilder<double>(
      key: ValueKey(alert.id),
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + index * 120),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, (1 - value) * 24), child: child),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withValues(alpha: 0.6), width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          initiallyExpanded: index == 0,
          shape: const Border(),
          collapsedShape: const Border(),
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(alertIcon(alert.event), color: color),
          ),
          title: Text(
            alert.event,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              alert.headline,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _Tag(text: alert.severity, color: color),
                _Tag(text: alert.urgency, color: Colors.blueGrey),
                if (isSmart) const _Tag(text: 'Smart alert', color: Colors.deepPurple),
              ],
            ),
            const SizedBox(height: 12),
            Text('Area: ${alert.areas}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (alert.effective.isNotEmpty || alert.expires.isNotEmpty)
              Text(
                'Period: ${alert.effective} - ${alert.expires}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 12),
            const Text('Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(alert.desc, style: const TextStyle(fontSize: 13, height: 1.4)),
            if (alert.instruction.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('What to do',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                alert.instruction,
                style: TextStyle(fontSize: 13, height: 1.4, color: Colors.amber.shade800),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;

  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
