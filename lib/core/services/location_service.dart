import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Wraps [Geolocator] permission handling and a single "where am I now" read,
/// so callers get either a [Position] or null without touching the plugin API.
class LocationService {
  const LocationService();

  /// Returns the device's current position, or null when location services are
  /// off or permission is denied. Never throws for the common denial paths —
  /// callers can treat null as "no location available".
  Future<Position?> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }
}

final locationServiceProvider =
    Provider<LocationService>((ref) => const LocationService());
