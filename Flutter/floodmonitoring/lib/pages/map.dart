import 'dart:async';
import 'dart:math';

import 'package:floodmonitoring/services/flood_level.dart';
import 'package:floodmonitoring/services/global.dart';
import 'package:floodmonitoring/services/location.dart';
import 'package:floodmonitoring/services/polyline.dart';
import 'package:floodmonitoring/services/url_tile_provider.dart';
import 'package:floodmonitoring/services/weather.dart';
import 'package:floodmonitoring/utils/style.dart';
import 'package:floodmonitoring/widgets/loadscreen_lottie_popup.dart';
import 'package:floodmonitoring/widgets/map_settings_popup.dart';
import 'package:floodmonitoring/widgets/search_popup.dart';
import 'package:floodmonitoring/widgets/toast.dart';
import 'package:floodmonitoring/widgets/vehicle_info_popup.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:vibration/vibration.dart';

import 'package:intl/intl.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;

  // Example location (Antipolo)
  final LatLng _center = const LatLng(14.6255, 121.1245);

  final Set<Marker> _markers = {};

  final blynk = BlynkService();

  Set<Circle> _circles = {};
  Set<Polyline> _polylines = {};

  CameraPosition? _lastPosition;

  bool showDirectionSheet = false;
  bool showSensorSheet = false;
  bool showSensorSettingsSheet = false;
  bool showPinConfirmationSheet = false;
  bool showRerouteConfirmationSheet = false;

  double directionSheetHeight = 0;
  double sensorSheetHeight = 0;
  double sensorSettingsSheetHeight = 0;
  double pinConfirmationSheetHeight = 0;
  double rerouteConfirmationSheetHeight = 0;

  double directionDragOffset = 0;
  double sensorDragOffset = 0;
  double sensorSettingsDragOffset = 0;
  double pinConfirmationDragOffset = 0;
  double rerouteConfirmationDragOffset = 0;

  final GlobalKey directionKey = GlobalKey();
  final GlobalKey sensorKey = GlobalKey();
  final GlobalKey sensorSettingsKey = GlobalKey();
  final GlobalKey pinConfirmKey = GlobalKey();
  final GlobalKey rerouteConfirmKey = GlobalKey();

///New Added
  bool showMainSheet = true;
  double mainSheetHeight = 0;
  double mainDragOffset = 0;
  final GlobalKey mainKey = GlobalKey();


  bool showAllSensors = true;
  bool showSensorCoverage = true;
  bool showCriticalSensors = false;
  bool showSensorLabels = false;


  bool insideAlertZone = false;
  bool nearAlertZone = false;
  bool normalRouting = true;


///New
  String temperature = '';
  String weatherDescription = '';
  String iconCode = '';

  String currentTime = '';
  Timer? _timer;

  int fetchIntervalMinutes = 1;
  int _secondsCounter = 0;

  String tempSelectedVehicle = "";

  @override
  void initState() {
    super.initState();

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   showFullScreenLottiePopup(context); // ✅ safe here
    // });

      setState(() {
        selectedVehicle = "";
      });

      ///Remove
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   showVehicleModal();
      // });

      fetchDataForAllSensors();
      _loadCurrentLocation();
      _updateTime();
      //_drawAvoidZones();
      //startLocationUpdates();

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        _updateTime();

        _secondsCounter++;

        if (_secondsCounter >= fetchIntervalMinutes * 60) {
          fetchDataForAllSensors();
          _secondsCounter = 0;
        }
      });
    }

  Position? _lastUpdatedPosition;
  StreamSubscription<Position>? _positionStream;

  Future<void> _loadCurrentLocation() async {
    Position? position = await LocationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        currentPosition = position;
      });
      getWeather();
      _addUserMarker();
    } else {
      print('Could not get location.');
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    final formattedTime = DateFormat('hh:mm a').format(now);

    setState(() {
      currentTime = formattedTime;
    });
  }


  void getWeather() async {
    final weather = await loadWeather(currentPosition!.latitude, currentPosition!.longitude);

    if (weather != null) {
      setState(() {
        temperature = weather['temperature'].toString();
        weatherDescription = weather['description'];
        iconCode = weather['iconCode'];
      });
    }
  }




  void startLocationUpdates() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1, // minimum distance in meters to trigger update
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      if (_lastUpdatedPosition == null) {
        _updatePosition(position);
      } else {
        double distance = Geolocator.distanceBetween(
          _lastUpdatedPosition!.latitude,
          _lastUpdatedPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        if (distance >= 1) { // update every 5 meters
          _updatePosition(position);
        }
      }
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _timer?.cancel();
    super.dispose();
  }


  void _updatePosition(Position position) {
    setState(() {
      currentPosition = position;
      _lastUpdatedPosition = position;
    });

    _addUserMarker();

    LatLng userLatLng = LatLng(
      position.latitude,
      position.longitude,
    );

    final avoidZones = buildAvoidZonesFromSensors();
    bool inside = isInsideAvoidZone(userLatLng, avoidZones);
    bool near = isNearAvoidZone(userLatLng, avoidZones);

    if (inside) {
      print("Position inside restricted area!");
    } else {
      print("Safe: Position outside avoid zones.");
    }


    if (near) {
      print("Position near restricted area!");
      setState(() {
        startAlert();
      });
    } else {
      print("Safe: Position far avoid zones.");
      stopAlert();
    }
  }

  bool displayAlert = false;
  Timer? _alertTimer;


  void startAlert() {
    if (!nearAlertZone) {
      nearAlertZone = true;
      showNearFloodAlertToast(context);
      Vibration.vibrate(duration: 100, amplitude: 255);

      // Blink alert
      _alertTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (!nearAlertZone) {
          timer.cancel();
        } else {
          setState(() {
            displayAlert = !displayAlert;
          });
        }
      });

      // Auto stop after 5 minutes
      Future.delayed(const Duration(minutes: 5), () {
        stopAlert();
      });
    }
  }

  void stopAlert() {
    nearAlertZone = false;
    _alertTimer?.cancel();
    setState(() {
      nearAlertZone = false;
      displayAlert = false;
    });
  }

  String? selectedSensorId;

  /// Get Update For Specific Sensor
  Future<void> fetchDataForSensor(String sensorId) async {
    final sensor = sensors[sensorId];
    if (sensor == null) return;

    final String token = sensor['token'];
    final String pin = sensor['pin']; // ✅ NEW

    final data = await BlynkService().fetchDistance(token, pin);

    setState(() {
      sensors[sensorId]!['sensorData'] = data;
    });

    print("Updated sensor $sensorId → $data");
  }

  /// Get Update For All Sensors
  Future<void> fetchDataForAllSensors() async {
    print("fetchDataForAllSensors");

    List<Future<void>> futures = [];

    sensors.forEach((sensorId, sensor) {
      final String token = sensor['token'];
      final String pin = sensor['pin']; // ✅ NEW

      futures.add(
        BlynkService().fetchDistance(token, pin).then((data) {
          setState(() {
            sensors[sensorId]!['sensorData'] = data;
          });

          print("Updated sensor $sensorId ($pin)");
        }),
      );
    });

    await Future.wait(futures);

    print("All sensors updated");
  }



  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;

    setState(() async {
      _markers.clear(); // Optional: clear previous markers

      // Load custom sensor marker image once
      final BitmapDescriptor sensorIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)), // size of your sensor image
        'assets/images/sensor_location.png',
      );

      sensors.forEach((id, sensor) {
        _markers.add(
          Marker(
            markerId: MarkerId(id),
            position: sensor['position'],
            icon: sensorIcon, // <-- use custom sensor image
            infoWindow: showSensorLabels ? InfoWindow(title: id) : InfoWindow.noText,
            anchor: const Offset(0.5, 0.5),
              onTap: () => _onSensorTap(id, sensor),
          ),
        );
      });
    });
  }



  LatLng _offsetPosition(LatLng original, double offsetInDegrees) {
    return LatLng(original.latitude - offsetInDegrees, original.longitude);
  }

  ///Sensor Gets Tapped
  Future<void> _onSensorTap(String id, Map<String, dynamic> sensor) async {
    final LatLng sensorPos = sensor['position'];
    final LatLng offsetTarget = _offsetPosition(sensorPos, 0.0090);

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: offsetTarget,
          zoom: 15,
        ),
      ),
    );

    await fetchDataForSensor(id);

    setState(() {
      selectedSensorId = id;
      showDirectionSheet = false;
      showSensorSettingsSheet = false;

      cancelPinSelection();

      showSensorSheet = true;
    });

    // Update circle for the selected sensor
    if (showSensorCoverage) {
      _circles.removeWhere((c) => c.circleId.value.startsWith(id));
      _circles.add(
        Circle(
          circleId: CircleId('${id}_circle'),
          center: sensor['position'],
          radius: 100,
          strokeWidth: 2,
          strokeColor: _getStatusColor(sensor['sensorData']['status']),
          fillColor: _getStatusColor(sensor['sensorData']['status']).withOpacity(0.3),
        ),
      );
    }

  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Safe":
        return color_safe;
      case "Warning":
        return color_warning;
      case "Danger":
        return color_danger;
      default:
        return Colors.black;
    }
  }

  /// Add Users Marker
  void _addUserMarker() async {
    if (currentPosition == null) return;

    final userLatLng = LatLng(
      currentPosition!.latitude,
      currentPosition!.longitude,
    );

    // Load custom image as marker
    final BitmapDescriptor userIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)), // size of your pin
      'assets/images/user_location.png',
    );

    setState(() {
      // Remove old user marker
      _markers.removeWhere((m) => m.markerId.value == 'user');

      // Remove old circles (optional)
      _circles.removeWhere((c) =>
      c.circleId.value == 'user_small' || c.circleId.value == 'user_medium');

      // Add user marker with custom image
      _markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: userLatLng,
          icon: userIcon, // <-- custom image
          anchor: const Offset(0.5, 0.5),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    });
  }



  void _refreshSensorMarkers() async {
    final BitmapDescriptor sensorIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/sensor_location.png',
    );

    setState(() {
      // Remove all sensors first
      _markers.removeWhere((m) => sensors.containsKey(m.markerId.value));

      // If showAllSensors == false → stop here (no markers added)
      if (!showAllSensors) return;

      // Otherwise add all sensors again
      sensors.forEach((id, sensor) {
        _markers.add(
          Marker(
            markerId: MarkerId(id),
            position: sensor['position'],
            icon: sensorIcon,
            anchor: const Offset(0.5, 0.5),
            infoWindow: showSensorLabels ? InfoWindow(title: id) : InfoWindow.noText,
            onTap: () => _onSensorTap(id, sensor),
          ),
        );
      });
    });
  }


  /// Locate user
  void _goToUser() async {
    if (currentPosition == null) return;

    final userLatLng = LatLng(
      currentPosition!.latitude,
      currentPosition!.longitude,
    );

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: userLatLng,
          zoom: 17, // set desired zoom level
          tilt: 0,
          bearing: 0,
        ),
      ),
    );
  }

  bool _isZoomedTilted = false;

  /// Reset map orientation (bearing & tilt)
  void _onCameraMove(CameraPosition position) {
    _lastPosition = position;
  }

  void _resetOrientation() async {
    if (_lastPosition == null) return;

    // Step 1: Reset bearing to 0
    await mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _lastPosition!.target,
          zoom: _lastPosition!.zoom, // keep current zoom
          tilt: 0, // reset tilt
          bearing: 0, // reset orientation
        ),
      ),
    );

    // Step 2: Apply zoom & tilt if toggled
    if (!_isZoomedTilted) {
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _lastPosition!.target,
            zoom: 18,
            tilt: 80,
            bearing: 0,
          ),
        ),
      );
    } else {
      // Optional: Reset zoom back to normal
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _lastPosition!.target,
            zoom: 17,
            tilt: 0,
            bearing: 0,
          ),
        ),
      );
    }

    _isZoomedTilted = !_isZoomedTilted;
  }


  void showAppToast(BuildContext context, {required String message, required String status, double? distance,}) {Color bgColor; IconData icon;

    switch (status.toLowerCase()) {
      case 'safe':
        bgColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'warning':
        bgColor = Colors.orange;
        icon = Icons.warning_amber_rounded;
        break;
      case 'danger':
        bgColor = Colors.red;
        icon = Icons.dangerous_rounded;
        break;
      default:
        bgColor = Colors.grey;
        icon = Icons.info_outline;
    }

    final displayMessage = distance != null
        ? "$message (Distance: ${distance.toStringAsFixed(1)} cm)"
        : message;

    DelightToastBar(
      builder: (context) => ToastCard(
        leading: Icon(icon, color: Colors.white, size: 28),
        title: Text(
          displayMessage,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        color: bgColor,
      ),
      autoDismiss: true,
      snackbarDuration: Durations.extralong4,
    ).show(context);
  }

  LatLng? savedPinPosition;        // the CURRENT official pin
  Marker? savedPinMarker;          // marker for the official pin
  Map<String, dynamic> savedPlace = {
    "name": "",
    "location": LatLng(0.0, 0.0),
  };

  LatLng? tappedPosition;          // temporary pin when user taps on map
  Marker? tappedMarker;
  Map<String, dynamic> currentPlace = {
    "name": "",
    "location": LatLng(0.0, 0.0),
  };

  void _onMapTap(LatLng position) async {

    if (selectedVehicle.isEmpty || showMainSheet) {
      showSelectVehicleToast(context);
      return;
    }

    print("Saved Pin: ${savedPinPosition?.latitude}, ${savedPinPosition?.longitude}");
    print("User: ${currentPosition!.latitude}, ${currentPosition!.longitude}");

    final BitmapDescriptor pinIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/selected_location.png',
    );

    setState(() {
      // Remove previous tapped marker
      if (tappedMarker != null) _markers.remove(tappedMarker);

      // Add new tapped marker
      tappedMarker = Marker(
        markerId: const MarkerId('tapped_pin'),
        position: position,
        icon: pinIcon,
        anchor: const Offset(0.5, 1.0),
      );
      _markers.add(tappedMarker!);

      // Update currentPlace
      currentPlace = {
        "name": "",        // leave empty since user just tapped
        "location": position,
      };
      tappedPosition = position;

      // Show confirmation sheet
      showPinConfirmationSheet = true;
      showDirectionSheet = false;
      showSensorSheet = false;
      showSensorSettingsSheet = false;
      showRerouteConfirmationSheet = false;
    });

    // Draw polyline from user to tapped pin
    if (currentPosition != null) {
      _drawRoute(
        LatLng(currentPosition!.latitude, currentPosition!.longitude),
        position, // use the tapped location
      );
    }

    // LatLng tap = tappedPosition!;
    // bool inside = isInsideAvoidZone(tap, avoidZones);
    //
    // if (inside) {
    //   print("Tapped inside restricted area!");
    //   setState(() {
    //     insideAlertZone = true;
    //   });
    // } else {
    //   print("Safe: tapped outside avoid zones.");
    //   setState(() {
    //     insideAlertZone = false;
    //   });
    // }


    Position fakePosition = Position(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 1,
      heading: 0,
      headingAccuracy: 1,
      speed: 0,
      speedAccuracy: 1,
    );

    _updatePosition(fakePosition);




  }

  void cancelPinSelection() {
    setState(() {
      // Remove temporary tapped pin
      if (tappedMarker != null) {
        _markers.remove(tappedMarker);
      }
      tappedMarker = null;
      tappedPosition = null;

      // Clear temporary/current place
      currentPlace = {
        "name": "",
        "location": LatLng(0.0, 0.0),
      };
    });

    // Restore saved pin → draw route again if exists
    if (savedPinMarker != null && currentPosition != null) {
      _drawRoute(
        LatLng(currentPosition!.latitude, currentPosition!.longitude),
        savedPinMarker!.position,
      );
    } else {
      setState(() {
        _polylines.clear();
      });
    }

    // Hide confirmation sheet and remove sensor circles
    setState(() {
      showPinConfirmationSheet = false;
      _circles.removeWhere((c) => c.circleId.value.startsWith('sensor'));
    });
  }


  // Set<Polygon> _polygons = {};
  // void _drawAvoidZones() {
  //   Set<Polygon> polygons = {};
  //
  //   for (int i = 0; i < avoidZones.length; i++) {
  //     final zone = avoidZones[i];
  //
  //     final center = zone["position"] as LatLng;
  //     final radius = zone["radius"] as double;
  //
  //     // Convert radius in meters to approximate degrees
  //     final delta = radius / 111000;
  //
  //     // Square corners (clockwise)
  //     final topLeft = LatLng(center.latitude + delta, center.longitude - delta); // A
  //     final topRight = LatLng(center.latitude + delta, center.longitude + delta); // B
  //     final bottomRight = LatLng(center.latitude - delta, center.longitude + delta); // C
  //     final bottomLeft = LatLng(center.latitude - delta, center.longitude - delta); // D
  //
  //     final points = [topLeft, topRight, bottomRight, bottomLeft, topLeft]; // close the polygon
  //
  //     polygons.add(Polygon(
  //       polygonId: PolygonId("avoid_zone_$i"),
  //       points: points,
  //       fillColor: Colors.red.withOpacity(0.3),
  //       strokeColor: Colors.red,
  //       strokeWidth: 2,
  //     ));
  //   }
  //
  //   setState(() {
  //     _polygons = polygons;
  //   });
  // }

  bool isInsideAvoidZone(LatLng usersPosition, List<Map<String, dynamic>> avoidZones) {
    for (var zone in avoidZones) {
      LatLng zoneCenter = zone["position"];
      double radius = zone["radius"]; // in meters

      double distance = Geolocator.distanceBetween(
        usersPosition.latitude,
        usersPosition.longitude,
        zoneCenter.latitude,
        zoneCenter.longitude,
      );

      if (distance <= radius) {
        return true; // inside this zone
      }
    }
    return false; // not inside any zone
  }

  bool isNearAvoidZone(LatLng usersPosition, List<Map<String, dynamic>> avoidZones) {
    for (var zone in avoidZones) {
      LatLng zoneCenter = zone["position"];
      double radius = zone["radius"]; // in meters

      double distance = Geolocator.distanceBetween(
        usersPosition.latitude,
        usersPosition.longitude,
        zoneCenter.latitude,
        zoneCenter.longitude,
      );

      if (distance <= radius + 500) {
        return true; // near this zone
      }
    }
    return false; // far any zone
  }

  List<LatLng> _generateCirclePolygon(LatLng center, double radius, int points) {
    List<LatLng> polygonPoints = [];
    final R = 6371000; // Earth radius in meters
    final dRad = radius / R;

    for (int i = 0; i < points; i++) {
      final theta = 2 * pi * i / points;
      final lat = asin(sin(center.latitude * pi / 180) * cos(dRad) +
          cos(center.latitude * pi / 180) * sin(dRad) * cos(theta)) *
          180 /
          pi;
      final lng = center.longitude +
          atan2(sin(theta) * sin(dRad) * cos(center.latitude * pi / 180),
              cos(dRad) - sin(center.latitude * pi / 180) * sin(lat * pi / 180)) *
              180 /
              pi;
      polygonPoints.add(LatLng(lat, lng));
    }

    return polygonPoints;
  }





  List<Map<String, dynamic>> buildAvoidZonesFromSensors() {
    List<Map<String, dynamic>> zones = [];

    sensors.forEach((sensorId, sensor) {
      final sensorData = sensor['sensorData'];
      final status = sensorData?['status'];

      if (status == 'Warning' || status == 'Danger') {
        zones.add({
          "position": sensor['position'],
          "radius": sensor['radius'], // from sensor config
        });

      }
    });

    return zones;
  }




  void _drawRoute(LatLng start, LatLng end) async {
    // ✅ Build avoid zones dynamically
    final avoidZones = buildAvoidZonesFromSensors();

    final route = await PolylineService.getRoute(
      start,
      end,
      normalRouting: normalRouting,
      avoidZones: avoidZones,
    );

    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId("route"),
          points: route,
          color: Colors.blue,
          width: 5,
        ),
      );
    });
  }







  Future<void> openPlaceSearch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const PlaceSearchPopup(),
      ),
    );

    if (result != null) {
      final LatLng position = result['latLng'];
      final String name = result['name'];

      print('Selected place: $name');
      print('Coordinates: ${position.latitude}, ${position.longitude}');

      // Create pin icon
      final BitmapDescriptor pinIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/selected_location.png',
      );

      setState(() {
        // Remove previous tapped marker
        if (tappedMarker != null) _markers.remove(tappedMarker);

        // Add new tapped marker
        tappedMarker = Marker(
          markerId: const MarkerId('tapped_pin'),
          position: position,
          icon: pinIcon,
          anchor: const Offset(0.5, 1.0),
        );
        _markers.add(tappedMarker!);
        tappedPosition = position;

        // Set currentPlace (temporary)
        currentPlace = {
          "name": name,
          "location": position,
        };

        // Show confirmation sheet
        showPinConfirmationSheet = true;
        showDirectionSheet = false;
        showSensorSheet = false;
        showSensorSettingsSheet = false;
        showRerouteConfirmationSheet = false;
      });

      if (currentPosition != null) {
        LatLng userPosition = LatLng(currentPosition!.latitude, currentPosition!.longitude);

        // Draw polyline to temporary/current place
        _drawRoute(userPosition, position);

        // Zoom to fit both locations
        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(
            min(userPosition.latitude, position.latitude),
            min(userPosition.longitude, position.longitude),
          ),
          northeast: LatLng(
            max(userPosition.latitude, position.latitude),
            max(userPosition.longitude, position.longitude),
          ),
        );

        mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
      }
    }
  }

//Rem/ove
// Vehicle tile widget with selection effect
  Widget vehicleTile(String name, String iconPath, void Function(void Function()) setState) {
    bool isSelected = selectedVehicle == name;

    // Static description and thresholds
    String description = "";
    String safe = "";
    String warning = "";
    String danger = "";
    Color safeColor = Colors.green;
    Color warningColor = Colors.orange;
    Color dangerColor = Colors.red;

    if (name == "Motorcycle") {
      description =
      "Motorcycles are very vulnerable to floods even at low levels. "
          "Unlike cars and trucks, they can easily lose balance or submerge. "
          "Extra caution is needed when riding in flood-prone areas.";
      safe = "0–20 cm";
      warning = "20.1–50 cm";
      danger = "50.1+ cm";
      safeColor = Colors.green;
      warningColor = Colors.orange;
      dangerColor = Colors.red;
    } else if (name == "Car") {
      description =
      "Cars can normally withstand floods that are below the door step. "
          "They are less vulnerable than motorcycles but may still be at risk if water rises higher than the engine level.";
      safe = "0–15 cm";
      warning = "15.1–30 cm";
      danger = "30.1+ cm";
      safeColor = Colors.green;
      warningColor = Colors.orange;
      dangerColor = Colors.red;
    } else if (name == "Truck") {
      description =
      "Trucks can handle large floods because of their size and higher chassis. "
          "They are the safest among common vehicles in deep water, but caution is still advised in extreme flood conditions.";
      safe = "0–40 cm";
      warning = "40.1–60 cm";
      danger = "60.1+ cm";
      safeColor = Colors.green;
      warningColor = Colors.orange;
      dangerColor = Colors.red;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedVehicle = name;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? color1 : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Image.asset(
                    iconPath,
                    width: 28,
                    height: 28,
                    color: isSelected ? Colors.white : color2,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // --- Animated Description Section ---
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isSelected
                  ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text("Safe: ", style: TextStyle(fontWeight: FontWeight.bold, color: safeColor)),
                        Text(safe, style: TextStyle(color: safeColor)),
                      ],
                    ),
                    Row(
                      children: [
                        Text("Warning: ", style: TextStyle(fontWeight: FontWeight.bold, color: warningColor)),
                        Text(warning, style: TextStyle(color: warningColor)),
                      ],
                    ),
                    Row(
                      children: [
                        Text("Danger: ", style: TextStyle(fontWeight: FontWeight.bold, color: dangerColor)),
                        Text(danger, style: TextStyle(color: dangerColor)),
                      ],
                    ),
                  ],
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }


  void showVehicleErrorToast(BuildContext context) {
    DelightToastBar(
      builder: (context) => ToastCard(
        leading: const Icon(Icons.error_outline, color: Colors.red, size: 28),
        title: const Text(
          "Please select a vehicle to continue",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        color: Colors.white, // background white
      ),
      autoDismiss: true,
      snackbarDuration: Durations.extralong4,
    ).show(context);
  }








  bool showFloodZones = false;

  Set<TileOverlay> getFloodTileOverlays() {
    return {
      TileOverlay(
        tileOverlayId: TileOverlayId('xyz_tiles'),
        tileProvider: UrlTileProvider(
          urlTemplate: '$serverUri/media/tiles/{z}/{x}/{y}.png',
        ),
        transparency: 0.3,
      ),
    };
  }



  String mapTypeToString(MapType mapType) {
    switch (mapType) {
      case MapType.normal:
        return "Normal";
      case MapType.satellite:
        return "Satellite";
      case MapType.hybrid:
        return "Hybrid";
      case MapType.terrain:
        return "Terrain";
      case MapType.none:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }



  MapType _currentMapType = MapType.normal;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // 🚫 Prevents map/buttons from shifting up
      body: Stack(
        children: [
          // 🗺️ MAP
          GoogleMap(
            onMapCreated: (controller) {
              _onMapCreated(controller);

              // Animate zoom after map is ready
              if (currentPosition != null) {
                controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(currentPosition!.latitude, currentPosition!.longitude),
                      zoom: 17.0, // zoom to 17
                    ),
                  ),
                );
              }
            },
            onTap: _onMapTap,
            onCameraMove: _onCameraMove,
            initialCameraPosition: CameraPosition(
              target: currentPosition != null
                  ? LatLng(currentPosition!.latitude, currentPosition!.longitude)
                  : _center,
              zoom: 15.0, // start at 15
            ),
            mapType: _currentMapType,
            markers: _markers,
            circles: _circles,
            polylines: _polylines,
            //polygons: _polygons,
            compassEnabled: false,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            tileOverlays: showFloodZones ? getFloodTileOverlays() : {},

            minMaxZoomPreference: const MinMaxZoomPreference(13.0, 18.0),
          ),

          // 🔍 Floating Search Bar (Top)
          // Positioned(
          //   top: 50,
          //   left: 20,
          //   right: 20,
          //   child: Container(
          //     decoration: BoxDecoration(
          //       color: Colors.white,
          //       borderRadius: BorderRadius.circular(30),
          //       boxShadow: [
          //         BoxShadow(
          //           color: Colors.black.withOpacity(0.1),
          //           blurRadius: 6,
          //           offset: const Offset(0, 2),
          //         ),
          //       ],
          //     ),
          //     child: TextField(
          //       decoration: InputDecoration(
          //         hintText: 'Search location...',
          //         hintStyle: const TextStyle(color: Colors.grey),
          //         prefixIcon: const Icon(Icons.search, color: Colors.grey),
          //         border: InputBorder.none,
          //         contentPadding: const EdgeInsets.symmetric(vertical: 15),
          //       ),
          //       onSubmitted: (value) {
          //         // TODO: Add search functionality
          //         print("Search: $value");
          //       },
          //     ),
          //   ),
          // ),

          // 📍 Bottom Button Bar

          ///Side Buttons
          Positioned(
            top: 0,
            bottom: 0,
            left: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _goToUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    elevation: 3,
                    shadowColor: Colors.black.withOpacity(0.15),
                    minimumSize: const Size(40, 40),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/icons/crosshair.png',
                      width: 25,
                      height: 25,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),


                ElevatedButton(
                  onPressed: _resetOrientation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    elevation: 3, // shadow
                    shadowColor: Colors.black.withOpacity(0.15),
                    minimumSize: const Size(40, 40), // button size
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/icons/compass.png',
                      width: 25,
                      height: 25,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),



                ElevatedButton(
                  onPressed: () {
                    if (showMainSheet && selectedVehicle.isEmpty) {
                      showSelectVehicleToast(context);
                      return;
                    }

                    showMapSettingsPopup(
                      context,
                      initialMapType: mapTypeToString(_currentMapType),
                      initialLayer: showFloodZones ? "Flood GIS" : "None",
                      onConfirm: (selectedMapType, selectedLayer) {
                        setState(() {
                          switch (selectedMapType) {
                            case "Normal":
                              _currentMapType = MapType.normal;
                              break;
                            case "Satellite":
                              _currentMapType = MapType.satellite;
                              break;
                            case "Hybrid":
                              _currentMapType = MapType.hybrid;
                              break;
                            case "Terrain":
                              _currentMapType = MapType.terrain;
                              break;
                          }

                          showFloodZones = (selectedLayer == "Flood GIS");
                        });
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color1,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                    shadowColor: Colors.black.withOpacity(0.15),
                    minimumSize: const Size(40, 40),
                  ),
                  child: Center(
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      child: Image.asset(
                        'assets/images/icons/layer.png',
                        width: 25,
                        height: 25,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          ///Direction Details
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            bottom: showDirectionSheet ? directionDragOffset : -directionSheetHeight,
            height: directionSheetHeight == 0 ? null : directionSheetHeight,

            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  directionDragOffset -= details.delta.dy;
                  if (directionDragOffset > 0) directionDragOffset = 0;
                  if (directionDragOffset < -directionSheetHeight) {
                    directionDragOffset = -directionSheetHeight;
                  }
                });
              },
              onVerticalDragEnd: (details) {
                if (directionDragOffset < -directionSheetHeight / 2) {
                  setState(() {
                    showDirectionSheet = false;
                    directionDragOffset = 0;
                  });
                } else {
                  setState(() {
                    directionDragOffset = 0;
                  });
                }
              },

              child: Container(
                key: directionKey,
                decoration: BoxDecoration(
                  color: colorSheet,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -3)),
                  ],
                ),

                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),

                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final renderBox = directionKey.currentContext?.findRenderObject() as RenderBox?;
                        if (renderBox != null) {
                          final newHeight = renderBox.size.height;
                          if (directionSheetHeight != newHeight) {
                            setState(() {
                              directionSheetHeight = newHeight;
                            });
                          }
                        }
                      });

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Drag Handle
                          Center(
                            child: Container(
                              width: 48,
                              height: 6,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                          // Header
                          Row(
                            children: [
                              Icon(Icons.alt_route_rounded, size: 28, color: colorPrimary),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "Directions",
                                    style: TextStyle(
                                      fontFamily: 'AvenirNext',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: colorTextPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "Choose your start and destination",
                                    style: TextStyle(
                                      fontFamily: 'AvenirNext',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: colorTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Location Card
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: colorPrimaryLight.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [

                                // Current Location
                                InkWell(
                                  onTap: () {},
                                  child: SizedBox(
                                    height: 50,
                                    child: Row(
                                      children: [
                                        Icon(Icons.my_location, size: 20, color: colorPrimary),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text(
                                            "Current Location",
                                            style: TextStyle(
                                              fontFamily: 'AvenirNext',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Icon(Icons.chevron_right, color: Colors.grey[500]),
                                      ],
                                    ),
                                  ),
                                ),

                                Divider(height: 1, color: Colors.grey.shade300),

                                // Destination
                                InkWell(
                                  onTap: openPlaceSearch,
                                  child: SizedBox(
                                    height: 50,
                                    child: Row(
                                      children: [
                                        Icon(Icons.location_on, size: 20, color: colorDanger),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            savedPlace["name"] != ""
                                                ? savedPlace["name"]
                                                : (savedPinPosition != null
                                                ? "${savedPinPosition!.latitude.toStringAsFixed(5)}, ${savedPinPosition!.longitude.toStringAsFixed(5)}"
                                                : "Select Destination"),
                                            style: const TextStyle(
                                              fontFamily: 'AvenirNext',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(Icons.chevron_right, color: Colors.grey[500]),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          ///Sensor Settings
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            bottom: showSensorSettingsSheet ? sensorSettingsDragOffset : -sensorSettingsSheetHeight,
            height: sensorSettingsSheetHeight == 0 ? null : sensorSettingsSheetHeight,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  sensorSettingsDragOffset -= details.delta.dy;

                  if (sensorSettingsDragOffset > 0) sensorSettingsDragOffset = 0;
                  if (sensorSettingsDragOffset < -sensorSettingsSheetHeight) {
                    sensorSettingsDragOffset = -sensorSettingsSheetHeight;
                  }
                });
              },
              onVerticalDragEnd: (details) {
                if (sensorSettingsDragOffset < -sensorSettingsSheetHeight / 2) {
                  setState(() {
                    showSensorSettingsSheet = false;
                    sensorSettingsDragOffset = 0;
                  });
                } else {
                  setState(() {
                    sensorSettingsDragOffset = 0;
                  });
                }
              },
              child: Container(
                key: sensorSettingsKey,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 12, offset: const Offset(0, -3)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final renderBox = sensorSettingsKey.currentContext?.findRenderObject() as RenderBox?;
                        if (renderBox != null) {
                          final newHeight = renderBox.size.height;
                          if (sensorSettingsSheetHeight != newHeight) {
                            setState(() {
                              sensorSettingsSheetHeight = newHeight;
                            });
                          }
                        }
                      });

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drag handle
                          Center(
                            child: Container(
                              width: 48,
                              height: 6,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                          // Header
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.settings_rounded, size: 32, color: colorPrimary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      "Sensor Settings",
                                      style: TextStyle(
                                        fontFamily: 'AvenirNext',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: colorTextPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "Control sensor display options",
                                      style: TextStyle(
                                        fontFamily: 'AvenirNext',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: colorTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Sensor Toggles
                          _sensorToggleCard(
                            title: 'Show All Sensors',
                            description: 'Display all sensors on the map',
                            value: showAllSensors,
                            onChanged: (val) {
                              setState(() => showAllSensors = val);
                              _refreshSensorMarkers();
                            },
                          ),

                          _sensorToggleCard(
                            title: 'Show Sensor Range / Coverage',
                            description: 'Display sensor coverage area',
                            value: showSensorCoverage,
                            onChanged: (val) => setState(() => showSensorCoverage = val),
                          ),

                          _sensorToggleCard(
                            title: 'Alerted / Critical Sensors Only',
                            description: 'Show only sensors with alerts',
                            value: showCriticalSensors,
                            onChanged: (val) => setState(() => showCriticalSensors = val),
                          ),

                          _sensorToggleCard(
                            title: 'Sensor Labels',
                            description: 'Show sensor names or IDs on the map',
                            value: showSensorLabels,
                            onChanged: (val) {
                              setState(() => showSensorLabels = val);
                              _refreshSensorMarkers();
                            },
                          ),

                          const SizedBox(height: 40),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          ///Sensor Details
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            bottom: showSensorSheet ? sensorDragOffset : -sensorSheetHeight,
            height: sensorSheetHeight == 0 ? null : sensorSheetHeight,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  sensorDragOffset -= details.delta.dy;
                  if (sensorDragOffset > 0) sensorDragOffset = 0;
                  if (sensorDragOffset < -sensorSheetHeight) {
                    sensorDragOffset = -sensorSheetHeight;
                  }
                });
              },
              onVerticalDragEnd: (details) {
                if (sensorDragOffset < -sensorSheetHeight / 2) {
                  setState(() {
                    showSensorSheet = false;
                    sensorDragOffset = 0;
                    // Remove sensor circles when closing
                    _circles.removeWhere((c) => c.circleId.value.startsWith('sensor'));
                  });
                } else {
                  setState(() {
                    sensorDragOffset = 0;
                  });
                }
              },
              child: Container(
                key: sensorKey,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final renderBox =
                        sensorKey.currentContext?.findRenderObject() as RenderBox?;
                        if (renderBox != null) {
                          final newHeight = renderBox.size.height;
                          if (sensorSheetHeight != newHeight) {
                            setState(() {
                              sensorSheetHeight = newHeight;
                            });
                          }
                        }
                      });

                      final sensor = selectedSensorId != null
                          ? sensors[selectedSensorId]!
                          : null;
                      final data = sensor?['sensorData'];

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // DRAG HANDLE
                          Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // HEADER
                          Row(
                            children: [
                              Icon(Icons.sensors, size: 32, color: color1), // primary theme
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Sensor Details",
                                      style: const TextStyle(
                                        fontFamily: 'AvenirNext',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      "Tap for more information",
                                      style: TextStyle(
                                        fontFamily: 'AvenirNext',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          // INFO CARD
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              children: [
                                _infoRow("Sensor ID", selectedSensorId ?? "-"),
                                _infoRow("Location", "Ortigas Ave"),
                                _infoRow(
                                    "Flood Height", "${data?['floodHeight'] ?? "-"} cm"),
                                _infoRow("Distance", "${data?['distance'] ?? "-"} cm"),
                                _statusRow(
                                  "Status",
                                  data?['status'] ?? "-",
                                  _getStatusColor(data?['status'] ?? ""),
                                ),
                                _infoRow("Last Update", data?['lastUpdate'] ?? "-"),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // PRIMARY BUTTON (modern, blue theme)
                          SizedBox(
                            width: double.infinity,
                            child: primaryButton(
                              text: "View Full Details",
                              onTap: () => Navigator.pushNamed(context, '/info'),
                            ),
                          ),

                          const SizedBox(height: 40), // padding for safe bottom
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          ///Pin Confirmation
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            bottom: showPinConfirmationSheet ? pinConfirmationDragOffset : -pinConfirmationSheetHeight,
            height: pinConfirmationSheetHeight == 0 ? null : pinConfirmationSheetHeight,

            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  pinConfirmationDragOffset -= details.delta.dy;
                  if (pinConfirmationDragOffset > 0) pinConfirmationDragOffset = 0;
                  if (pinConfirmationDragOffset < -pinConfirmationSheetHeight) {
                    pinConfirmationDragOffset = -pinConfirmationSheetHeight;
                  }
                });
              },
              onVerticalDragEnd: (details) {
                if (pinConfirmationDragOffset < -pinConfirmationSheetHeight / 2) {
                  setState(() {
                    cancelPinSelection();
                    pinConfirmationDragOffset = 0;
                    _circles.removeWhere((c) => c.circleId.value.startsWith('sensor'));
                  });
                } else {
                  setState(() {
                    pinConfirmationDragOffset = 0;
                  });
                }
              },

              child: Container(
                key: pinConfirmKey,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),

                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // AUTO-DETECT HEIGHT
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final renderBox = pinConfirmKey.currentContext?.findRenderObject() as RenderBox?;
                        if (renderBox != null) {
                          final newHeight = renderBox.size.height;
                          if (pinConfirmationSheetHeight != newHeight) {
                            setState(() {
                              pinConfirmationSheetHeight = newHeight;
                            });
                          }
                        }
                      });

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // DRAG HANDLE
                          Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // HEADER (style identical to Reroute sheet)
                          Row(
                            children: [
                              const Icon(Icons.location_pin, size: 30, color: Colors.blue),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      "Set Pin Location",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      "Tap Confirm to set new pin location.",
                                      style: TextStyle(
                                        fontFamily: 'AvenirNext',
                                        fontSize: 13,
                                        color: Colors.grey, // same as Reroute subtitle
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // ACTION BUTTONS (same as Reroute)
                          Row(
                            children: [
                              Expanded(
                                child: secondaryButton(
                                  text: "IGNORE",
                                  onTap: () {
                                    cancelPinSelection();
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: primaryButton(
                                  text: "CONFIRM",
                                  onTap: () {
                                    setState(() {
                                      if (savedPinMarker != null) {
                                        _markers.remove(savedPinMarker);
                                      }

                                      savedPinMarker = tappedMarker;
                                      savedPinPosition = tappedPosition;
                                      savedPlace = Map.from(currentPlace);

                                      tappedMarker = null;
                                      tappedPosition = null;
                                      currentPlace = {
                                        "name": "",
                                        "location": LatLng(0.0, 0.0),
                                      };

                                      showPinConfirmationSheet = false;
                                      _circles.removeWhere((c) => c.circleId.value.startsWith('sensor'));
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 40), // bottom padding
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),


          ///Reroute Confirmation
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            bottom: showRerouteConfirmationSheet
                ? rerouteConfirmationDragOffset
                : -rerouteConfirmationSheetHeight,

            // AUTO HEIGHT
            height: rerouteConfirmationSheetHeight == 0 ? null : rerouteConfirmationSheetHeight,

            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  rerouteConfirmationDragOffset -= details.delta.dy;

                  if (rerouteConfirmationDragOffset > 0) rerouteConfirmationDragOffset = 0;
                  if (rerouteConfirmationDragOffset < -rerouteConfirmationSheetHeight) {
                    rerouteConfirmationDragOffset = -rerouteConfirmationSheetHeight;
                  }
                });
              },

              onVerticalDragEnd: (details) {
                if (rerouteConfirmationDragOffset < -rerouteConfirmationSheetHeight / 2) {
                  setState(() {
                    showRerouteConfirmationSheet = false;
                    rerouteConfirmationDragOffset = 0;
                    _circles.removeWhere((c) => c.circleId.value.startsWith('sensor'));
                  });
                } else {
                  setState(() {
                    rerouteConfirmationDragOffset = 0;
                  });
                }
              },

              child: Container(
                key: rerouteConfirmKey,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),

                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // AUTO-DETECT HEIGHT
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final renderBox =
                        rerouteConfirmKey.currentContext?.findRenderObject() as RenderBox?;
                        if (renderBox != null) {
                          final newHeight = renderBox.size.height;
                          if (rerouteConfirmationSheetHeight != newHeight) {
                            setState(() {
                              rerouteConfirmationSheetHeight = newHeight;
                            });
                          }
                        }
                      });

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // DRAG HANDLE
                          Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // HEADER
                          Row(
                            children: [
                              Icon(Icons.alt_route_rounded, size: 30, color: color1),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Route Adjustment",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      "Confirm to generate a safer alternate path.",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // ACTION BUTTONS
                          Row(
                            children: [
                              Expanded(
                                child: secondaryButton(
                                  text: "IGNORE",
                                  onTap: () {
                                    setState(() {
                                      showRerouteConfirmationSheet = false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: primaryButton(
                                  text: "REROUTE",
                                  onTap: () {
                                    setState(() {
                                      normalRouting = false;
                                      showRerouteConfirmationSheet = false;
                                    });

                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      _drawRoute(
                                        LatLng(currentPosition!.latitude, currentPosition!.longitude),
                                        savedPinMarker!.position,
                                      );
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          ///Bottom Button
          Positioned(
            bottom: -5,
            left: 0,
            right: 0,
            child: Row(
              children: [
                bottomButton(
                  onTap: () {
                    setState(() {
                      showSensorSheet = false;
                      showSensorSettingsSheet = false;
                      showPinConfirmationSheet = false;
                      showRerouteConfirmationSheet = false;
                      cancelPinSelection();
                      showDirectionSheet = !showDirectionSheet;
                    });
                    _circles.removeWhere((c) => c.circleId.value.startsWith('sensor'));
                  },
                  label: 'Directions',
                  imagePath: 'assets/images/icons/pin.png',
                  iconColor: (showDirectionSheet) ? color1 : color2,
                ),
                bottomButton(
                  onTap: () {
                    setState(() {
                      showSensorSheet = false;
                      showDirectionSheet = false;
                      showPinConfirmationSheet = false;
                      showRerouteConfirmationSheet = false;
                      cancelPinSelection();
                      showSensorSettingsSheet = !showSensorSettingsSheet;
                    });
                    _circles.removeWhere((c) => c.circleId.value.startsWith('sensor'));
                  },
                  label: 'Sensor',
                  imagePath: 'assets/images/icons/sensor.png',
                  iconColor: (showSensorSettingsSheet) ? color1 : color2,
                ),
                bottomButton(
                  onTap: () {
                    if (nearAlertZone) {
                      setState(() {
                        showSensorSheet = false;
                        showDirectionSheet = false;
                        showSensorSettingsSheet = false;
                        showPinConfirmationSheet = false;
                        cancelPinSelection();
                        showRerouteConfirmationSheet = !showRerouteConfirmationSheet;
                      });
                      _circles.removeWhere((c) => c.circleId.value.startsWith('sensor'));
                    }
                  },
                  label: 'Alerts',
                  imagePath: 'assets/images/icons/exclamation.png',
                  iconColor: (showRerouteConfirmationSheet) ? color1 : (displayAlert) ? Colors.red : color2,
                  buttonColor: (showRerouteConfirmationSheet) ? Colors.white : (displayAlert) ? color_alert : Colors.white,
                ),
              ],
            ),
          ),

          ///Burger menu

          Positioned(
            top: 20,
            left: 10,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300), // fade duration
              opacity: showMainSheet ? 0.0 : 1.0,         // fade out when true
              curve: Curves.easeInOut,
              child: IgnorePointer(
                ignoring: showMainSheet,                  // disable tap when hidden
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      showDirectionSheet = false;
                      showSensorSheet = false;
                      showSensorSettingsSheet = false;
                      showPinConfirmationSheet = false;
                      showRerouteConfirmationSheet = false;

                      showMainSheet = true;
                      tempSelectedVehicle = selectedVehicle;
                    });
                  },
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: color1,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/icons/burger-bar.png',
                        width: 25,
                        height: 25,
                        fit: BoxFit.contain,
                        color: Colors.white,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),




          ///New Added
          ///Banner
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: showMainSheet ? 20 : -200,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: showMainSheet ? 1 : 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 15),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blueAccent.shade400,
                      Colors.lightBlue.shade300,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Text Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Flood Update\nin Your Zone',
                            style: TextStyle(
                              fontFamily: 'AvenirNext',
                              fontSize: 22,
                              fontWeight: FontWeight.w700, // Bold
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Stay alert, stay safe',
                            style: TextStyle(
                              fontFamily: 'AvenirNext',
                              fontSize: 15,
                              fontWeight: FontWeight.w500, // Medium
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Image
                    Image.asset(
                      'assets/images/Flood-amico.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ),
          ),



          ///New Added
          /// Main Sheet
          if (showMainSheet)
            DraggableScrollableSheet(
              initialChildSize: 0.45,
              minChildSize: 0.25,
              maxChildSize: 0.95,
              snap: true,
              snapSizes: const [0.45, 0.95],
              builder: (context, scrollController) {
                return GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (selectedVehicle.isNotEmpty) {
                      scrollController.jumpTo(scrollController.offset - details.delta.dy);
                    }
                  },
                  child: NotificationListener<DraggableScrollableNotification>(
                    onNotification: (notification) {
                      if (selectedVehicle.isNotEmpty && notification.extent <= 0.25) {
                        setState(() => showMainSheet = false);
                      }
                      return true;
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white, // clean white background
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 12,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Drag handle
                          const SizedBox(height: 12),
                          Center(
                            child: Container(
                              width: 50,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Scrollable content
                          Expanded(
                            child: SingleChildScrollView(
                              controller: scrollController,
                              physics: const ClampingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // HEADER
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.directions_car_filled, size: 34, color: Colors.blueAccent),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: const [
                                            Text(
                                              "Pick a Vehicle",
                                              style: TextStyle(
                                                fontFamily: 'AvenirNext',
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700, // Bold
                                                color: Colors.black87,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              "Choose from the options below",
                                              style: TextStyle(
                                                fontFamily: 'AvenirNext',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400, // Regular
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),

                                  // VEHICLE SELECTION
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: Row(
                                      children: [
                                        vehicleSelection(
                                          name: 'Bicycle',
                                          imagePath: 'assets/images/vehicle/bicycle.png',
                                          highlightColor: Colors.blueAccent,
                                          onTap: () {
                                            setState(() {
                                              tempSelectedVehicle = selectedVehicle;
                                              selectedVehicle = 'Bicycle';
                                            });
                                            VehicleInfoPopup.show(
                                              context,
                                              "Bicycle",
                                              onConfirm: (v) {
                                                setState(() {
                                                  selectedVehicle = 'Bicycle';
                                                  showMainSheet = false;
                                                  showDirectionSheet = true;
                                                  _goToUser();
                                                });
                                              },
                                              onCancel: (v) {
                                                setState(() {
                                                  selectedVehicle = tempSelectedVehicle;
                                                });
                                              },
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 16),
                                        vehicleSelection(
                                          name: 'Motorcycle',
                                          imagePath: 'assets/images/vehicle/motorcycle.png',
                                          highlightColor: Colors.blueAccent,
                                          onTap: () {
                                            setState(() {
                                              tempSelectedVehicle = selectedVehicle;
                                              selectedVehicle = 'Motorcycle';
                                            });
                                            VehicleInfoPopup.show(
                                              context,
                                              "Motorcycle",
                                              onConfirm: (v) {
                                                setState(() {
                                                  selectedVehicle = 'Motorcycle';
                                                  showMainSheet = false;
                                                  showDirectionSheet = true;
                                                  _goToUser();
                                                });
                                              },
                                              onCancel: (v) {
                                                setState(() {
                                                  selectedVehicle = tempSelectedVehicle;
                                                });
                                              },
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 16),
                                        vehicleSelection(
                                          name: 'Car',
                                          imagePath: 'assets/images/vehicle/car.png',
                                          highlightColor: Colors.blueAccent,
                                          onTap: () {
                                            setState(() {
                                              tempSelectedVehicle = selectedVehicle;
                                              selectedVehicle = 'Car';
                                            });
                                            VehicleInfoPopup.show(
                                              context,
                                              "Car",
                                              onConfirm: (v) {
                                                setState(() {
                                                  selectedVehicle = 'Car';
                                                  showMainSheet = false;
                                                  showDirectionSheet = true;
                                                  _goToUser();
                                                });
                                              },
                                              onCancel: (v) {
                                                setState(() {
                                                  selectedVehicle = tempSelectedVehicle;
                                                });
                                              },
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 16),
                                        vehicleSelection(
                                          name: 'Truck',
                                          imagePath: 'assets/images/vehicle/truck.png',
                                          highlightColor: Colors.blueAccent,
                                          onTap: () {
                                            setState(() {
                                              tempSelectedVehicle = selectedVehicle;
                                              selectedVehicle = 'Truck';
                                            });
                                            VehicleInfoPopup.show(
                                              context,
                                              "Truck",
                                              onConfirm: (v) {
                                                setState(() {
                                                  selectedVehicle = 'Truck';
                                                  showMainSheet = false;
                                                  showDirectionSheet = true;
                                                  _goToUser();
                                                });
                                              },
                                              onCancel: (v) {
                                                setState(() {
                                                  selectedVehicle = tempSelectedVehicle;
                                                });
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 22),

                                  // RELATED SECTION
                                  const Text(
                                    'Related',
                                    style: TextStyle(
                                      fontFamily: 'AvenirNext',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600, // Demi
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // WEATHER CARD
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        Column(
                                          children: [
                                            if (iconCode.isNotEmpty)
                                              Image.asset(
                                                'assets/images/weather/$iconCode.png',
                                                width: 90,
                                                height: 90,
                                                fit: BoxFit.contain,
                                              )
                                            else
                                              SizedBox(
                                                width: 90,
                                                height: 90,
                                                child: Center(
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                                                ),
                                              ),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              currentTime.isNotEmpty ? currentTime : '--:--',
                                              style: const TextStyle(
                                                fontFamily: 'AvenirNext',
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              temperature != null ? '${temperature}°C' : '--°C',
                                              style: const TextStyle(
                                                fontFamily: 'AvenirNext',
                                                color: Colors.blueAccent,
                                                fontSize: 30,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Text(
                                              weatherDescription.isNotEmpty ? weatherDescription : 'Loading...',
                                              style: const TextStyle(
                                                fontFamily: 'AvenirNext',
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // BOTTOM CARDS
                                  Row(
                                    children: [
                                      // LEFT BIG CARD
                                      Expanded(
                                        flex: 4,
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.pushNamed(context, '/recent-alert');
                                          },
                                          child: Container(
                                            height: 120,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.blueAccent,
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Image.asset(
                                                    'assets/images/3d-images/bell-3d.png',
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                                const Text(
                                                  "Recent Alerts",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontFamily: 'AvenirNext',
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // RIGHT COLUMN
                                      Expanded(
                                        flex: 5,
                                        child: Column(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.pushNamed(context, '/flood-tips');
                                              },
                                              child: _smallCard(
                                                color: Colors.lightBlueAccent.shade100,
                                                image: 'assets/images/3d-images/rescue-3d.png',
                                                text: "Flood Tips",
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.pushNamed(context, '/rescue-call');
                                              },
                                              child: _smallCard(
                                                color: Colors.blueAccent.shade100,
                                                image: 'assets/images/3d-images/help-3d.png',
                                                text: "Rescue Call",
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),


        ],
      ),
    );
  }

  Widget _smallCard({
    required Color color,
    required String image,
    required String text,
  }) {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: Image.asset(image, fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // VEHICLE SELECTION WIDGET
  Widget vehicleSelection({
    required String name,
    required String imagePath,
    required VoidCallback onTap,
    Color? highlightColor,
  }) {
    final isSelected = selectedVehicle == name;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            height: 90,
            width: 90,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? Colors.blue : Colors.transparent, width: 2),
              gradient: isSelected ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blueAccent.shade400,
                  Colors.lightBlue.shade300,
                ],
              ) : null,
            ),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: TextStyle(
              fontFamily: 'AvenirNext',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.blueAccent : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }



  Widget bottomButton({
    required VoidCallback onTap,
    required String imagePath,
    required String label,
    Color iconColor = color2,
    Color buttonColor = Colors.white,
  }) {
    bool isPressed = false;

    return Expanded(
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: () {
          if (isPressed) return;
          isPressed = true;
          onTap();
          Future.delayed(const Duration(milliseconds: 350), () {
            isPressed = false;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          color: buttonColor,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: ColorFiltered(
                  key: ValueKey(iconColor),
                  colorFilter: ColorFilter.mode(
                    iconColor,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    imagePath,
                    width: 25,
                    height: 25,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: iconColor,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }





  Widget selectVehicle({
    required String name,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: (selectedVehicle == name) ? color1 : Colors.white,
          borderRadius: BorderRadius.circular(40 / 2), // perfect circle
        ),
        child: Center(
          child: Image.asset(
            imagePath,
            width: 25, // image slightly smaller than container
            height: 25,
            fit: BoxFit.contain,
            color: (selectedVehicle == name) ? Colors.white : color2, // apply green tint
            colorBlendMode: BlendMode.srcIn, // ensures the color replaces the original
          ),
        ),
      ),
    );
  }




// Reusable widget
  Widget _sensorToggleCard({
    required String title,
    required String description,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white, // solid white background
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'AvenirNext',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: colorPrimary, // your theme color
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }



  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

