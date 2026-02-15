

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';



String serverUri = "http://192.168.1.13:8000";

/// API KEYS
const String googleMapAPI = "AIzaSyAMamxCz-N-wiGSq4-DfVpD9zOpP_GZ_9o";
const hereAPIKey = "TiHkVyYjkDXokfAstiAx97Iqttb-eqUTd1vCq1aiqhE";
const String mapboxAPI = "pk.eyJ1IjoidmluY2VudGplcnJ5anVhbmljbyIsImEiOiJjbWlyanl6MDMwMmRuM2NzZnAzZWRtMGRzIn0.8zbipe-6rXc1C5u0fP15aQ";

/// Testing mode
bool testingMode = true;
bool settingPin = true;

/// Global Variable
Position? currentPosition;
String selectedVehicle = "";
int sensorHeight = 200;



final List<Map<String, dynamic>> floodStatuses = [
  {
    "text": "Safe",
    "color": const Color(0xFF4CAF50), // Green
    "icon": Icons.check_circle,
    "message": "No flooding detected."
  },
  {
    "text": "Warning",
    "color": const Color(0xFFFFC107), // Yellow
    "icon": Icons.warning_amber_rounded,
    "message": "Rising water level, stay alert."
  },
  {
    "text": "Danger",
    "color": const Color(0xFFF44336), // Red
    "icon": Icons.error,
    "message": "Flooding likely, move to higher ground."
  },
];


Map<String, Map<String, dynamic>> sensors = {
  "sensor_01": { //Near basketball Court
    "position": const LatLng(14.601570218473059, 121.00789117225852),
    "token": "rDsIi--IkEDcdOVLSBXh2DvfusmwPSFc",
    "pin": "V0",
    "radius": 100.0,
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
  },

  "sensor_02": { //Near Church 1
    "position": const LatLng(14.599904842697908, 121.00901626016662),
    "token": "rDsIi--IkEDcdOVLSBXh2DvfusmwPSFc",
    "pin": "V1",
    "radius": 100.0,
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
  },

  "sensor_03": { //Near Church 2
    "position": const LatLng(14.600046597692646, 121.00933305621841),
    "token": "rDsIi--IkEDcdOVLSBXh2DvfusmwPSFc",
    "pin": "V2",
    "radius": 100.0,
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
  },
};



/// Link: https://interaksyon.philstar.com/trends-spotlights/2024/09/04/282826/mmda-flood-gauge-system-travelers-motorists/amp/
/// Link: https://www.carmudi.com.ph/journal/5-tips-gauge-safe-drive-flood/
final List<Map<String, dynamic>> vehicleFloodThresholds = [
  {
    "vehicle": "",
    // 0" to 10" (Gutter/Half-knee)
    "safeRange_cm": [0.0, 25.4],
    // 10.1" to 19" (Knee level)
    "warningRange_cm": [25.5, 48.26],
    // 19.1" above (Tire level and higher)
    "dangerRange_cm": [48.27, double.infinity],
  },
  {
    "vehicle": "Bicycle",
    // 0" to 4" (Bicycles struggle earlier)
    "safeRange_cm": [0.0, 10.16],
    "warningRange_cm": [10.17, 25.4],
    "dangerRange_cm": [25.41, double.infinity],
  },
  {
    "vehicle": "Motorcycle",
    // 0" to 8" (Gutter level is okay)
    "safeRange_cm": [0.0, 20.32],
    // 8.1" to 13" (Half-tire is risky for engines)
    "warningRange_cm": [20.33, 33.02],
    "dangerRange_cm": [33.03, double.infinity],
  },
  {
    "vehicle": "Car",
    // 0" to 10" (Standard MMDA PASSABLE)
    "safeRange_cm": [0.0, 25.4],
    // 10.1" to 19" (Standard MMDA NPLV - Not Passable Light Vehicles)
    "warningRange_cm": [25.41, 48.26],
    "dangerRange_cm": [48.27, double.infinity],
  },
  {
    "vehicle": "Truck",
    // 0" to 19" (Trucks can usually handle up to knee level)
    "safeRange_cm": [0.0, 48.26],
    // 19.1" to 26" (Tire level is the limit)
    "warningRange_cm": [48.27, 66.04],
    "dangerRange_cm": [66.05, double.infinity],
  },
];



