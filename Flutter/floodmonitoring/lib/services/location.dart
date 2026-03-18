import 'package:geolocator/geolocator.dart';

/// A service to handle device location retrieval and permission management.
class LocationService {
  static Future<Position?> getCurrentLocation() async {
    // Check if the device has location services (GPS) turned on
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return null;
    }

    // Check for app-level location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request permission if it hasn't been granted yet
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied.');
        return null;
      }
    }

    // Handle cases where the user has permanently disabled permissions in settings
    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied.');
      return null;
    }

    // Retrieve the current GPS coordinates with high precision
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}