import 'package:floodmonitoring/services/global.dart';
import 'package:floodmonitoring/services/time.dart';
import 'package:http/http.dart' as http;

/// Service to handle data retrieval from the Blynk IoT platform and calculate flood levels.
class BlynkService {
  Future<Map<String, dynamic>> fetchDistance(
      String token,
      String pin,
      double height,
      ) async {
    try {
      // Construct the API URL for the specific Blynk device and virtual pin
      final url = Uri.parse(
        'https://blynk.cloud/external/api/get?token=$token&pin=$pin',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = response.body.trim();
        final measuredDistance = double.tryParse(body);

        if (measuredDistance != null) {
          // Calculate the actual flood height by subtracting sensor distance from total sensor height
          double floodHeight = (height * 100) - measuredDistance;

          // Prevent negative values if the water is below the expected ground level
          if (floodHeight < 0) floodHeight = 0;

          // Determine the safety status and get the current timestamp
          final status = getStatusText(floodHeight);
          final lastUpdate = getCurrentTime();

          return {
            "distance": measuredDistance,
            "floodHeight": floodHeight,
            "status": status,
            "lastUpdate": lastUpdate,
          };
        } else {
          throw Exception("Invalid data format: $body");
        }
      } else {
        throw Exception("Failed to fetch data: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching distance: $e");
      return {
        "distance": null,
        "floodHeight": null,
        "status": "Error",
        "lastUpdate": getCurrentTime(),
      };
    }
  }

  /// Determines if the current flood height is Safe, Warning, or Danger based on the selected vehicle.
  String getStatusText(double floodHeightCm) {
    // Retrieve the specific thresholds for the currently selected vehicle type
    final vehicleThreshold = vehicleFloodThresholds.firstWhere(
          (v) => v["vehicle"] == selectedVehicle,
      orElse: () => vehicleFloodThresholds[0],
    );

    // Compare flood height against vehicle-specific safety ranges
    if (floodHeightCm <= vehicleThreshold["safeRange_cm"][1]) {
      return 'Safe';
    } else if (floodHeightCm <= vehicleThreshold["warningRange_cm"][1]) {
      return 'Warning';
    } else {
      return 'Danger';
    }
  }
}