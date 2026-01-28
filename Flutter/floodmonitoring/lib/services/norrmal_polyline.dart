  import 'dart:convert';
  import 'package:http/http.dart' as http;
  import 'package:google_maps_flutter/google_maps_flutter.dart';
  import 'global.dart'; // contains mapboxAPI token

  class PolylineService {
    /// Get route normally (no rerouting)
    static Future<List<LatLng>> getRoute(
        LatLng origin,
        LatLng destination,
        ) async {
      return await _fetchMapboxRoute(origin, destination);
    }

    /// Fetch route from Mapbox Directions API
    static Future<List<LatLng>> _fetchMapboxRoute(
        LatLng origin,
        LatLng destination,
        ) async {

      final coords =
          "${origin.longitude},${origin.latitude};"
          "${destination.longitude},${destination.latitude}";

      final url = Uri.parse(
          "https://api.mapbox.com/directions/v5/mapbox/driving/$coords"
              "?geometries=polyline&overview=full&access_token=$mapboxAPI"
      );

      final res = await http.get(url);
      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body);
      final encoded = data['routes']?[0]?['geometry'];

      return encoded == null ? [] : decodePolyline(encoded);
    }

    /// Polyline decoder
    static List<LatLng> decodePolyline(String encoded) {
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
  }
