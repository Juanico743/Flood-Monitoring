import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'global.dart';

/// Service responsible for fetching sensor metadata and configurations from the backend.
class SensorService {
  Future<Map<String, Map<String, dynamic>>> loadSensorsList() async {
    try {
      // API endpoint to retrieve all registered sensor devices
      String uri = '$serverUri/api/get-all-sensors/';
      var res = await http.get(
        Uri.parse(uri),
        headers: {"Content-Type": "application/json"},
      );

      var response = jsonDecode(res.body);
      Map<String, Map<String, dynamic>> tempSensors = {};

      // Check if the request was successful and contains valid data
      if (res.statusCode == 200 && response["success"] == true) {
        for (var item in response["sensors"]) {
          String sId = item["sensor_id"].toString();

          // Map raw API data into a structured format for the application state
          tempSensors[sId] = {
            "position": LatLng(
              double.parse(item["latitude"].toString()),
              double.parse(item["longitude"].toString()),
            ),
            "token": item["token"].toString(),
            "pin": item["pin"].toString(),
            "radius": double.parse(item["radius"].toString()),
            "height": double.parse(item["height"].toString()),
            "location": item["location_name"],

            // Initialize sensor metrics with placeholder "Loading" values
            "sensorData": {
              "distance": 0.0,
              "floodHeight": 0.0,
              "status": "Loading...",
              "lastUpdate": "00:00 AM",
            },

            // Initialize environmental data placeholders
            "weatherData": {
              "temperature": 0.0,
              "description": "Loading...",
              "pressure": 0,
            }
          };
        }
      }
      return tempSensors;
    } catch (e) {
      // Log connection or parsing errors and return an empty map to prevent crashes
      print("Error fetching sensors: $e");
      return {};
    }
  }
}