

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


String serverUri = "http://192.168.1.13:8000";


const String googleMapAPI = "AIzaSyAMamxCz-N-wiGSq4-DfVpD9zOpP_GZ_9o";

const hereAPIKey = "TiHkVyYjkDXokfAstiAx97Iqttb-eqUTd1vCq1aiqhE";
const String mapboxAPI = "pk.eyJ1IjoidmluY2VudGplcnJ5anVhbmljbyIsImEiOiJjbWlyanl6MDMwMmRuM2NzZnAzZWRtMGRzIn0.8zbipe-6rXc1C5u0fP15aQ";


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



