
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'global.dart';

class SensorService {
  Future<Map<String, Map<String, dynamic>>> loadSensorsList() async {
    try {
      String uri = '$serverUri/api/get-all-sensors/';
      var res = await http.get(
        Uri.parse(uri),
        headers: {"Content-Type": "application/json"},
      );

      var response = jsonDecode(res.body);
      Map<String, Map<String, dynamic>> tempSensors = {};


      print("response: $response");
      if (res.statusCode == 200 && response["success"] == true) {
        for (var item in response["sensors"]) {
          String sId = item["sensor_id"].toString();
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
            "sensorData": {
              "distance": 0.0,
              "floodHeight": 0.0,
              "status": "Loading...",
              "lastUpdate": "00:00 AM",
            },
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
      print("Error fetching sensors: $e");
      return {};
    }
  }
}