import 'package:floodmonitoring/services/global.dart';
import 'package:floodmonitoring/services/time.dart';
import 'package:http/http.dart' as http;



class BlynkService {
  /// Fetches the distance value from Blynk Cloud for a given sensor token & pin
  Future<Map<String, dynamic>> fetchDistance(
      String token,
      String pin,
      ) async {
    try {
      final url = Uri.parse(
        'https://blynk.cloud/external/api/get?token=$token&pin=$pin',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = response.body.trim();
        final measuredDistance = double.tryParse(body);

        if (measuredDistance != null) {
          // ✅ Compute flood height
          double floodHeight = sensorHeight - measuredDistance;

          // Prevent negative values
          if (floodHeight < 0) floodHeight = 0;

          final status = getStatusText(floodHeight);
          final lastUpdate = getCurrentTime();

          print("📟 Blynk Pin: $pin");
          print("📏 Sensor Distance: $measuredDistance cm");
          print("🌊 Flood Height: $floodHeight cm");
          print("⚠️ Status: $status");

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

  /// Determines the status based on flood height
  String getStatusText(double floodHeightCm) {
    final vehicleThreshold = vehicleFloodThresholds.firstWhere(
          (v) => v["vehicle"] == selectedVehicle,
      orElse: () => vehicleFloodThresholds[0],
    );

    if (floodHeightCm <= vehicleThreshold["safeRange_cm"][1]) {
      return 'Safe';
    } else if (floodHeightCm <= vehicleThreshold["warningRange_cm"][1]) {
      return 'Warning';
    } else {
      return 'Danger';
    }
  }
}
