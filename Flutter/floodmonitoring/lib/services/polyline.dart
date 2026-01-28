import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flexible_polyline_dart/flutter_flexible_polyline.dart';
import 'package:flexible_polyline_dart/latlngz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'global.dart'; // googleMapAPI + hereAPIKey

class PolylineService {
  /// MAIN FUNCTION
  /// normalRouting = true → Google
  /// normalRouting = false → HERE (supports avoid zones)
  static Future<List<LatLng>> getRoute(
      LatLng origin,
      LatLng destination, {
        required bool normalRouting,
        List<Map<String, dynamic>> avoidZones = const [],
      }) async {
    if (normalRouting) {
      return _fetchGoogleRoute(origin, destination);
    } else {
      return _fetchHereRoute(origin, destination, avoidZones);
    }
  }

  // ---------------------------------------------------------------------------
  // GOOGLE ROUTING (normal)
  // ---------------------------------------------------------------------------
  static Future<List<LatLng>> _fetchGoogleRoute(
      LatLng origin, LatLng destination) async {
    final url = Uri.parse(
        "https://routes.googleapis.com/directions/v2:computeRoutes");

    final payload = {
      "origin": {
        "location": {
          "latLng": {
            "latitude": origin.latitude,
            "longitude": origin.longitude,
          }
        }
      },
      "destination": {
        "location": {
          "latLng": {
            "latitude": destination.latitude,
            "longitude": destination.longitude,
          }
        }
      },
      "travelMode": "DRIVE",
      "polylineQuality": "HIGH_QUALITY"
    };

    final res = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": googleMapAPI,
        "X-Goog-FieldMask": "routes.polyline.encodedPolyline",
      },
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200) {
      print("Google API Error: ${res.body}");
      return [];
    }

    final data = jsonDecode(res.body);
    final encoded = data["routes"]?[0]?["polyline"]?["encodedPolyline"];
    if (encoded == null) return [];

    return _decodeGooglePolyline(encoded);
  }

  static List<LatLng> _decodeGooglePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int b, shift = 0, result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }

  // ---------------------------------------------------------------------------
  // HERE ROUTING (with avoid zones)
  // ---------------------------------------------------------------------------
  static Future<List<LatLng>> _fetchHereRoute(
      LatLng origin,
      LatLng destination,
      List<Map<String, dynamic>> avoidZones,
      ) async {
    final avoidParam =
    avoidZones.isNotEmpty ? "&avoid[areas]=${_buildAvoidAreas(avoidZones)}" : "";

    final url =
        "https://router.hereapi.com/v8/routes"
        "?transportMode=car"
        "&origin=${origin.latitude},${origin.longitude}"
        "&destination=${destination.latitude},${destination.longitude}"
        "&return=polyline,summary"
        "$avoidParam"
        "&apikey=$hereAPIKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      print("HERE API Error: ${response.body}");
      return [];
    }

    final data = jsonDecode(response.body);
    final poly = data["routes"]?[0]?["sections"]?[0]?["polyline"];
    if (poly == null) return [];

    /// Decode HERE flexible polyline
    final List<LatLngZ> decoded = FlexiblePolyline.decode(poly);
    return decoded.map((p) => LatLng(p.lat, p.lng)).toList();
  }

  static String _buildAvoidAreas(List<Map<String, dynamic>> zones) {
    return zones.map((zone) {
      final bbox = _getBBox(zone["position"], zone["radius"]);
      return "bbox:${bbox["minLon"]},${bbox["minLat"]},${bbox["maxLon"]},${bbox["maxLat"]}";
    }).join("|");
  }

  static Map<String, double> _getBBox(LatLng center, double radius) {
    double deltaLat = radius / 111000;
    double deltaLon =
        radius / (111000 * cos(center.latitude * pi / 180));

    return {
      "minLat": center.latitude - deltaLat,
      "maxLat": center.latitude + deltaLat,
      "minLon": center.longitude - deltaLon,
      "maxLon": center.longitude + deltaLon,
    };
  }
}
