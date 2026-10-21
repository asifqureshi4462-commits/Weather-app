import 'package:flutter/material.dart';

/// Icon with expanding "radar" rings. Used for GPS, permission dialogs and map marker.
class PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool active;

  const PulsingIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 24,
    this.active = true,
  });

  @override
  State<PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<PulsingIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant PulsingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      if (widget.active) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _ring(double t) {
    final diameter = widget.size * (1.0 + t);
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.color.withValues(alpha: (1 - t) * 0.35),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.size * 2;
    return SizedBox(
      width: box,
      height: box,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t1 = _controller.value;
          final t2 = (_controller.value + 0.5) % 1.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (widget.active) _ring(t1),
              if (widget.active) _ring(t2),
              Container(
                padding: EdgeInsets.all(widget.size * 0.18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.18),
                ),
                child: Icon(widget.icon, color: widget.color, size: widget.size * 0.9),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Friendly, animated permission / GPS dialogs. Every method returns true when the
/// user taps the main button, false/null otherwise.
class PermissionDialogs {
  static Future<bool?> showGpsOff(BuildContext context) {
    return _show(
      context,
      icon: Icons.gps_off_rounded,
      color: Colors.orange,
      title: 'Turn on GPS',
      message:
          'Your GPS / location is switched off. Turn it on so Atmosphere can show the live weather and alerts for where you are.',
      confirmLabel: 'Turn On GPS',
      cancelLabel: 'Not now',
    );
  }

  static Future<bool?> showLocationPermission(BuildContext context) {
    return _show(
      context,
      icon: Icons.my_location_rounded,
      color: Colors.blue,
      title: 'Allow location access',
      message:
          'Allow location permission so the app can automatically detect your city and refresh the weather every time you open it.',
      confirmLabel: 'Allow Location',
      cancelLabel: 'Not now',
    );
  }

  static Future<bool?> showLocationSettings(BuildContext context) {
    return _show(
      context,
      icon: Icons.location_disabled_rounded,
      color: Colors.redAccent,
      title: 'Location is blocked',
      message:
          'Location permission was denied permanently. Open app settings, tap Permissions > Location and choose "Allow while using the app".',
      confirmLabel: 'Open Settings',
      cancelLabel: 'Cancel',
    );
  }

  static Future<bool?> showNotificationPermission(BuildContext context) {
    return _show(
      context,
      icon: Icons.notifications_active_rounded,
      color: Colors.deepPurple,
      title: 'Allow notifications',
      message:
          'Get severe weather alerts, rain warnings and your daily morning forecast right on your phone.',
      confirmLabel: 'Allow Notifications',
      cancelLabel: 'Maybe later',
    );
  }

  static Future<bool?> showNotificationSettings(BuildContext context) {
    return _show(
      context,
      icon: Icons.notifications_off_rounded,
      color: Colors.redAccent,
      title: 'Notifications are blocked',
      message:
          'Open app settings and turn on Notifications to receive weather alerts and the daily summary.',
      confirmLabel: 'Open Settings',
      cancelLabel: 'Cancel',
    );
  }

  static Future<bool?> _show(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return _PermissionDialog(
          icon: icon,
          color: color,
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
        );
      },
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );
  }
}

class _PermissionDialog extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  const _PermissionDialog({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Material(
          color: scheme.surface,
          elevation: 12,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PulsingIcon(icon: icon, color: color, size: 44),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: scheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(cancelLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
