import 'dart:convert';
import 'package:http/http.dart' as http;

import 'global.dart';

/// Service to fetch and structure vehicle-specific flood safety thresholds from the backend.
class ThresholdService {
  Future<List<Map<String, dynamic>>> loadThresholdsList() async {
    try {
      // API request to fetch safety ranges for different vehicle types
      String uri = '$serverUri/api/get-all-thresholds/';
      var res = await http.get(
        Uri.parse(uri),
        headers: {"Content-Type": "application/json"},
      );

      var response = jsonDecode(res.body);
      List<Map<String, dynamic>> tempThresholds = [];

      // Validate the response and begin parsing the data list
      if (res.statusCode == 200 && response["success"] == true) {
        for (var item in response["thresholds"]) {
          tempThresholds.add({
            // Identify the vehicle type (e.g., Sedan, SUV, Motorcycle)
            "vehicle": item["vehicle_type"] ?? item["vehicle"],

            // Map the minimum and maximum height ranges for Safe status
            "safeRange_cm": [
              double.parse(item["safe_min"].toString()),
              double.parse(item["safe_max"].toString())
            ],

            // Map the range where a Warning status should be triggered
            "warningRange_cm": [
              double.parse(item["warning_min"].toString()),
              double.parse(item["warning_max"].toString())
            ],

            // Map the Danger range, defaulting to infinity if no upper limit is set
            "dangerRange_cm": [
              double.parse(item["danger_min"].toString()),
              item["danger_max"] != null ? double.parse(item["danger_max"].toString()) : double.infinity
            ],
          });
        }
      }
      return tempThresholds;
    } catch (e) {
      // Catch exceptions and return an empty list to avoid breaking the UI
      print("Error fetching thresholds: $e");
      return [];
    }
  }
}