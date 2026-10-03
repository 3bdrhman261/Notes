import 'dart:async';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

enum LocationStatus { ready, serviceDisabled, denied, deniedForever }

class NoteLocation {
  final double latitude;
  final double longitude;
  final String? placeName;

  const NoteLocation({
    required this.latitude,
    required this.longitude,
    this.placeName,
  });
}

class LocationService {
  final Geocoding _geocoding = Geocoding(); // جديد

  /// Checks that the GPS is on and the permission is granted.
  /// With [request] = true it shows the system permission prompt if needed.
  Future<LocationStatus> checkStatus({bool request = true}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationStatus.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && request) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationStatus.deniedForever;
    }
    if (permission == LocationPermission.denied) {
      return LocationStatus.denied;
    }
    return LocationStatus.ready;
  }

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  /// Current position + place name. Returns null on any failure.
  Future<NoteLocation?> getCurrentLocation() async {
    try {
      if (await checkStatus(request: false) != LocationStatus.ready)
        return null;

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } on TimeoutException {
        position = await Geolocator.getLastKnownPosition();
      }
      if (position == null) return null;

      final name = await _placeName(position.latitude, position.longitude);
      return NoteLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        placeName: name,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _placeName(double lat, double lng) async {
    try {
      final marks = await _geocoding
          .placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 5));
      if (marks.isEmpty) return null;
      final m = marks.first;

      final parts = <String>[];
      for (final s in [m.subLocality, m.locality, m.administrativeArea]) {
        final v = s?.trim() ?? '';
        if (v.isNotEmpty && !parts.contains(v)) parts.add(v);
      }
      if (parts.isEmpty) {
        for (final s in [m.street, m.name, m.country]) {
          final v = s?.trim() ?? '';
          if (v.isNotEmpty) {
            parts.add(v);
            break;
          }
        }
      }
      return parts.isEmpty ? null : parts.take(2).join(', ');
    } catch (_) {
      return null; // no internet etc. -> coordinates will be shown instead
    }
  }
}

