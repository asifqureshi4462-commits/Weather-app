import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Why the device location could not be obtained.
enum LocationIssue {
  none,
  serviceDisabled, // GPS / location switch is OFF
  permissionDenied, // app permission not granted yet
  permissionDeniedForever, // user blocked it, must be enabled in app settings
  unavailable, // GPS is on but no fix could be obtained in time
}

class LocationException implements Exception {
  final LocationIssue issue;
  final String message;
  const LocationException(this.issue, this.message);

  @override
  String toString() => message;
}

class LocationService {
  /// Emits true when the device GPS switch is turned ON, false when OFF.
  Stream<bool> get serviceEnabledStream => Geolocator.getServiceStatusStream()
      .map((status) => status == ServiceStatus.enabled);

  Future<LocationIssue> checkIssue() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return LocationIssue.serviceDisabled;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        return LocationIssue.permissionDeniedForever;
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        return LocationIssue.permissionDenied;
      }
      return LocationIssue.none;
    } catch (_) {
      return LocationIssue.unavailable;
    }
  }

  /// Shows the system permission prompt (if still allowed). Returns true if granted.
  Future<bool> requestPermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  Future<Position> getCurrentPosition({bool askPermission = false}) async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const LocationException(
        LocationIssue.serviceDisabled,
        'GPS is turned off. Please turn on location.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && askPermission) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        LocationIssue.permissionDeniedForever,
        'Location permission is blocked. Enable it in app settings.',
      );
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      throw const LocationException(
        LocationIssue.permissionDenied,
        'Location permission is required to show weather for your area.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );
    } on LocationServiceDisabledException {
      throw const LocationException(
        LocationIssue.serviceDisabled,
        'GPS is turned off. Please turn on location.',
      );
    } on PermissionDeniedException {
      throw const LocationException(
        LocationIssue.permissionDenied,
        'Location permission was denied.',
      );
    } on TimeoutException {
      return _lastKnownOrThrow();
    } catch (_) {
      return _lastKnownOrThrow();
    }
  }

  Future<Position> _lastKnownOrThrow() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
    } catch (_) {}
    throw const LocationException(
      LocationIssue.unavailable,
      'Could not get a GPS fix yet. Please try again in a moment.',
    );
  }

  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
