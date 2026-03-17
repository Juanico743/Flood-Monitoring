
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'global.dart';

class ThresholdService {
  Future<List<Map<String, dynamic>>> loadThresholdsList() async {
    try {
      String uri = '$serverUri/api/get-all-thresholds/';
      var res = await http.get(
        Uri.parse(uri),
        headers: {"Content-Type": "application/json"},
      );

      var response = jsonDecode(res.body);
      List<Map<String, dynamic>> tempThresholds = [];

      if (res.statusCode == 200 && response["success"] == true) {
        for (var item in response["thresholds"]) {
          tempThresholds.add({
            "vehicle": item["vehicle_type"] ?? item["vehicle"],
            "safeRange_cm": [
              double.parse(item["safe_min"].toString()),
              double.parse(item["safe_max"].toString())
            ],
            "warningRange_cm": [
              double.parse(item["warning_min"].toString()),
              double.parse(item["warning_max"].toString())
            ],
            "dangerRange_cm": [
              double.parse(item["danger_min"].toString()),
              item["danger_max"] != null ? double.parse(item["danger_max"].toString()) : double.infinity
            ],
          });
        }
      }
      return tempThresholds;
    } catch (e) {
      print("Error fetching thresholds: $e");
      return [];
    }
  }
}