import 'dart:convert';
import 'dart:math';
import 'package:flexible_polyline_dart/flutter_flexible_polyline.dart';
import 'package:flexible_polyline_dart/latlngz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'global.dart'; // contains hereAPIKey

class PolylineService {
  /// Get a route from HERE API from [origin] to [destination].
  /// [avoidZones] is a list of maps: {"position": LatLng, "radius": double in meters}
  static Future<List<LatLng>> getRoute(
      LatLng origin, LatLng destination, List<Map<String, dynamic>> avoidZones) async {

    // Build avoid[areas] if avoidZones is not empty
    String avoidParam = avoidZones.isNotEmpty
        ? buildAvoidAreas(avoidZones)
        : "";

    final url =
        "https://router.hereapi.com/v8/routes"
        "?transportMode=car"
        "&origin=${origin.latitude},${origin.longitude}"
        "&destination=${destination.latitude},${destination.longitude}"
        "&return=polyline,summary"
        "${avoidParam.isNotEmpty ? "&avoid[areas]=$avoidParam" : ""}"
        "&apikey=$hereAPIKey";

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      print("HERE ERROR: ${res.body}");
      return [];
    }

    final body = jsonDecode(res.body);
    final poly = body['routes']?[0]?['sections']?[0]?['polyline'];
    if (poly == null) return [];

    // Decode HERE flexible polyline
    final List<LatLngZ> decodedPoints = FlexiblePolyline.decode(poly);
    return decodedPoints.map((p) => LatLng(p.lat, p.lng)).toList();
  }

  /// Build avoid[areas] string using bounding boxes (bbox:minLon,minLat,maxLon,maxLat)
  static String buildAvoidAreas(List<Map<String, dynamic>> zones) {
    return zones.map((zone) {
      final bounds = _getBBox(zone['position'], zone['radius']);
      return "bbox:${bounds['minLon']},${bounds['minLat']},${bounds['maxLon']},${bounds['maxLat']}";
    }).join("!");
  }

  /// Convert a center + radius (meters) into a bounding box
  static Map<String, double> _getBBox(LatLng center, double radiusMeters) {
    // Approx conversion: meters to degrees latitude
    double deltaLat = radiusMeters / 111000;
    // Approx conversion: meters to degrees longitude (corrected by latitude)
    double deltaLon = radiusMeters / (111000 * cos(center.latitude * pi / 180));

    double minLat = center.latitude - deltaLat;
    double maxLat = center.latitude + deltaLat;
    double minLon = center.longitude - deltaLon;
    double maxLon = center.longitude + deltaLon;

    return {
      "minLat": minLat,
      "maxLat": maxLat,
      "minLon": minLon,
      "maxLon": maxLon,
    };
  }
}
