import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

class LocationService {
  // Added BuildContext context as a parameter
  static Future<Position?> getCurrentLocation(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    // If permission is Denied Forever, we quit the app
    if (permission == LocationPermission.deniedForever) {
      print('Permanently denied. Quitting app...');
      await SystemNavigator.pop(); // This closes the app
      return null;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        print('User denied permission. Quitting app...');
        await SystemNavigator.pop(); // Close app if they hit deny
        return null;
      }

      // If they just accepted (WhileInUse or Always), we RESTART
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        print('Permission accepted! Restarting app...');
        Phoenix.rebirth(context); // This restarts the app
        return null;
      }
    }

    // If we already have permission, just get the position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static Future<String> getAddressFromPosition(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];


        if (place.street!.toLowerCase().contains(place.name!.toLowerCase())) {
          return "${place.street}, ${place.locality}";
        } else {
          return "${place.name}, ${place.street}, ${place.locality}";
        }
      }
      return "Address not found";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }
}