import 'dart:async';
import 'dart:math';

import 'package:floodmonitoring/services/flood_level.dart';
import 'package:floodmonitoring/services/global.dart';
import 'package:floodmonitoring/services/location.dart';
import 'package:floodmonitoring/services/polyline.dart';
import 'package:floodmonitoring/services/sensor_service.dart';
import 'package:floodmonitoring/services/threshold_service.dart';
import 'package:floodmonitoring/services/url_tile_provider.dart';
import 'package:floodmonitoring/services/weather.dart';
import 'package:floodmonitoring/utils/converters.dart';
import 'package:floodmonitoring/utils/style.dart';
import 'package:floodmonitoring/widgets/map_settings_popup.dart';
import 'package:floodmonitoring/widgets/search_popup.dart';
import 'package:floodmonitoring/widgets/toast.dart';
import 'package:floodmonitoring/widgets/vehicle_info_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
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

  // ========================================
  // STATE / VARIABLES
  // ========================================

  late GoogleMapController mapController;

  final ThresholdService _thresholdService = ThresholdService();
  final SensorService _sensorService = SensorService();

  final LatLng _center = const LatLng(14.600775714641369, 121.00852660400322);

  final Set<Marker> _markers = {};
  final blynk = BlynkService();

  Set<Circle> _circles = {};
  Set<Polyline> _polylines = {};

  CameraPosition? _lastPosition;

  /// Direction Sheet
  bool showDirectionSheet = false;
  double directionSheetHeight = 0;
  double directionDragOffset = 0;
  final GlobalKey directionKey = GlobalKey();

  /// Sensor Sheet
  bool showSensorSheet = false;
  double sensorSheetHeight = 0;
  double sensorDragOffset = 0;
  final GlobalKey sensorKey = GlobalKey();

  /// Sensor Settings Sheet
  bool showSensorSettingsSheet = false;
  double sensorSettingsSheetHeight = 0;
  double sensorSettingsDragOffset = 0;
  final GlobalKey sensorSettingsKey = GlobalKey();

  /// Pin Confirmation Sheet
  bool showPinConfirmationSheet = false;
  double pinConfirmationSheetHeight = 0;
  double pinConfirmationDragOffset = 0;
  final GlobalKey pinConfirmKey = GlobalKey();

  /// Reroute Confirmation Sheet
  bool showRerouteConfirmationSheet = false;
  double rerouteConfirmationSheetHeight = 0;
  double rerouteConfirmationDragOffset = 0;
  final GlobalKey rerouteConfirmKey = GlobalKey();

  /// Main Sheet
  bool showMainSheet = true;
  double mainSheetHeight = 0;
  double mainDragOffset = 0;
  final GlobalKey mainKey = GlobalKey();

  /// Map Settings Sheet
  bool showAllSensors = true;
  bool showSensorCoverage = true;
  bool showCriticalSensors = false;
  bool showSensorLabels = false;

  /// Alert and Routing
  bool insideAlertZone = false;
  bool nearAlertZone = false;
  bool normalRouting = true;

  /// Weather variables
  String temperature = '';
  String weatherDescription = '';
  String iconCode = '';

  /// Time
  String currentTime = '';
  Timer? _timer;
  int fetchIntervalMinutes = 1;
  int _secondsCounter = 0;

  String tempSelectedVehicle = "";

  LatLng? savedPinPosition;
  Marker? savedPinMarker;

  LatLng? tappedPosition;
  Marker? tappedMarker;
  Map<String, dynamic> currentPlace = {
    "name": "",
    "location": LatLng(0.0, 0.0),
  };

  /// Map Location Variables
  LatLng? savedStartPosition;
  Marker? savedStartMarker;

  LatLng? startPosition;
  Marker? startMarker;
  Map<String, dynamic> startPlace = {
    "name": "",
    "location": LatLng(0.0, 0.0),
  };

  Map<String, dynamic> savedPlace = {
    "name": "",
    "location": LatLng(0.0, 0.0),
  };

  Map<String, dynamic> savedStartPlace = {
    "name": "",
    "location": LatLng(0.0, 0.0),
  };

  // ========================================
  // INITIALIZATION (initState)
  // ========================================

  @override
  void initState() {
    super.initState();

    _permissionLocation();

    selectedVehicle = "";
    _updateTime();

    _initializeEverything();

    _startTimer();
    startLocationUpdates();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  // ========================================
  // STATE / VARIABLES
  // ========================================

  /// ----- Initialize Everything -----
  Future<void> _initializeEverything() async {
    loadSensors();
    _loadThresholds();
    fetchDataForAllSensors();

    await _loadMarkerIcon();

    await _loadCurrentLocation();

    if (mounted) {
      _addUserMarker();

      // Delayed init
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _initCompass();
      });
    }
  }

  /// ----- START TIMER -----
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      _updateTime();
      _secondsCounter++;

      if (_secondsCounter >= fetchIntervalMinutes * 60) {
        fetchDataForAllSensors();
        _secondsCounter = 0;
      }
    });
  }

  /// ----- LOAD SENSORS-----
  Future<void> loadSensors() async {
    var tempSensors = await _sensorService.loadSensorsList();

    setState(() {
      sensors = tempSensors;
      _buildSensorMarkers();
    });
  }

  /// ----- LOAD THRESHOLD -----
  Future<void> _loadThresholds() async {
    List<Map<String, dynamic>> data = await _thresholdService.loadThresholdsList();

    setState(() {
      vehicleFloodThresholds = data;
    });
  }


  /// ----- BUILD SENSOR MAKERS -----
  Future<void> _buildSensorMarkers() async {
    final BitmapDescriptor sensorIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/sensor_location.png',
    );

    setState(() {
      _markers.clear();
      sensors.forEach((id, sensor) {
        _markers.add(
          Marker(
            markerId: MarkerId(id),
            position: sensor['position'],
            icon: sensorIcon,
            onTap: () => _onSensorTap(id, sensor),
            zIndex: 2,
          ),
        );
      });
    });
  }


  Position? _lastUpdatedPosition;
  StreamSubscription<Position>? _positionStream;


  /// ----- PERMISSION LOCATION -----
  Future<void> _permissionLocation() async {
    await LocationService.getCurrentLocation(context);
  }

  /// ----- LOAD CURRENT LOCATION -----
  Future<void> _loadCurrentLocation() async {

    Position? lastKnown = await Geolocator.getLastKnownPosition();

    if (lastKnown != null && mounted) {
      setState(() => currentPosition = lastKnown);
      _addUserMarker();
      getWeather();
    }

    try {
      Position freshPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );

      if (mounted) {
        setState(() => currentPosition = freshPosition);
        _addUserMarker();
        getWeather();
        print("currentPosition: $currentPosition");
      }
    } catch (e) {
      print('Fresh location timeout or error: $e');
    }
  }

  /// ----- UPDATE TIME -----
  void _updateTime() {
    final now = DateTime.now();
    final formattedTime = DateFormat('hh:mm a').format(now);

    setState(() {
      currentTime = formattedTime;
    });
  }

  /// ----- GET WEATHER -----
  void getWeather() async {
    final weather = await loadWeather(currentPosition!.latitude, currentPosition!.longitude);

    if (weather != null) {
      setState(() {
        temperature = weather['temperature'].toString();
        weatherDescription = weather['description'];
        iconCode = weather['iconCode'];
      });
    }
    print('My Weather: $weather');
  }

  /// ----- START LOCATION UPDATES -----
  void startLocationUpdates() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _updatePosition(position);
    });
  }

  /// ----- UPDATE POSITION -----
  void _updatePosition(Position position) {

    LatLng rawLatLng = LatLng(
      position.latitude,
      position.longitude,
    );

    // ⭐ smooth GPS instead of animating
    LatLng userLatLng = smoothPosition(rawLatLng);

    setState(() {
      currentPosition = Position(
        latitude: userLatLng.latitude,
        longitude: userLatLng.longitude,
        timestamp: position.timestamp,
        accuracy: position.accuracy,
        altitude: position.altitude,
        heading: position.heading,
        speed: position.speed,
        speedAccuracy: position.speedAccuracy,
        altitudeAccuracy: position.altitudeAccuracy,
        headingAccuracy: position.headingAccuracy,
      );
    });

    _addUserMarker();

    if (savedStartPosition == null
        && savedPinPosition != null
        && tappedPosition == null
        && startPosition == null ) {
      _drawRoute(userLatLng, savedPinPosition!);
    }

    final avoidZones = buildAvoidZonesFromSensors();
    bool inside = isInsideAvoidZone(userLatLng, avoidZones);
    bool near = isNearAvoidZone(userLatLng, avoidZones);

    if (near) {
      startAlert();
    } else {
      stopAlert();
    }
  }

  LatLng? _smoothedLatLng;

  /// ----- SMOOTH POSITION -----
  LatLng smoothPosition(LatLng newPosition) {
    const double smoothFactor = 0.2;

    if (_smoothedLatLng == null) {
      _smoothedLatLng = newPosition;
      return newPosition;
    }

    final lat = _smoothedLatLng!.latitude +
        (newPosition.latitude - _smoothedLatLng!.latitude) * smoothFactor;

    final lng = _smoothedLatLng!.longitude +
        (newPosition.longitude - _smoothedLatLng!.longitude) * smoothFactor;

    _smoothedLatLng = LatLng(lat, lng);

    return _smoothedLatLng!;
  }

  bool displayAlert = false;
  Timer? _alertTimer;

  /// ----- START ALERT -----
  void startAlert() {
    if (!nearAlertZone) {

      nearAlertZone = true;
      showNearFloodAlertToast(context);
      Vibration.vibrate(duration: 100, amplitude: 255);

      _alertTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (!nearAlertZone) {
          timer.cancel();
        } else {
          setState(() {
            displayAlert = !displayAlert;
          });
        }
      });

      Future.delayed(const Duration(minutes: 5), () {
        stopAlert();
      });
    }
  }

  /// ----- STOP ALERT -----
  void stopAlert() {
    nearAlertZone = false;
    _alertTimer?.cancel();
    setState(() {
      nearAlertZone = false;
      displayAlert = false;
    });
  }

  String? selectedSensorId;

  /// ----- FETCH DATA FOR SENSOR -----
  Future<void> fetchDataForSensor(String sensorId) async {
    final sensor = sensors[sensorId];
    if (sensor == null) return;

    final String token = sensor['token'];
    final String pin = sensor['pin'];
    final double height = sensor['height'];

    final data = await BlynkService().fetchDistance(token, pin, height);

    setState(() {
      sensors[sensorId]!['sensorData'] = data;
    });

    print("Updated sensor $sensorId → $data");
  }

  /// ----- FETCH DATA FOR ALL SENSORS -----
  Future<void> fetchDataForAllSensors() async {

    List<Future<void>> futures = [];

    sensors.forEach((sensorId, sensor) {
      final String token = sensor['token'];
      final String pin = sensor['pin'];
      final double height = sensor['height'];

      futures.add(
        BlynkService().fetchDistance(token, pin, height).then((data) {
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

  /// ----- ON MAP CREATED -----
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
            zIndex: 2,
          ),
        );
      });
    });
  }

  /// ----- OFFSET POSITION -----
  LatLng _offsetPosition(LatLng original, double offsetInDegrees) {
    return LatLng(original.latitude - offsetInDegrees, original.longitude);
  }

  /// ----- ON SENSOR TAP -----
  Future<void> _onSensorTap(String id, Map<String, dynamic> sensor) async {

    if (selectedVehicle.isEmpty) {
      showSelectVehicleToast(context);
      return;
    } else {
      setState(() {
        showMainSheet = false;
      });
    }

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

  /// ----- GET STATUS COLOR -----
  Color _getStatusColor(String status) {
    switch (status) {
      case "Safe":
        return colorSafe;
      case "Warning":
        return colorWarning;
      case "Danger":
        return colorDanger;
      default:
        return Colors.black;
    }
  }

  double _userHeading = 0;
  double _lastUpdateHeading = 0;
  double _mapBearing = 0.0;

  BitmapDescriptor? userIcon;

  /// ----- LOAD MARKER ICON -----
  Future<void> _loadMarkerIcon() async {
    userIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/user_location.png',
    );
  }

  /// ----- INIT COMPASS -----
  void _initCompass() {
    FlutterCompass.events?.listen((CompassEvent event) {
      double? currentHeading = event.heading;
      if (currentHeading == null) return;

      // Use the raw heading. Do NOT subtract _mapBearing.
      if ((currentHeading - _lastUpdateHeading).abs() > 2) {
        if (mounted) {
          _userHeading = currentHeading; // Raw compass value
          _lastUpdateHeading = currentHeading;
          _addUserMarker();
        }
      }
    });
  }

  /// ----- ADD USER MARKER -----
  void _addUserMarker() {
    if (currentPosition == null || userIcon == null) return;

    final userLatLng = LatLng(
      currentPosition!.latitude,
      currentPosition!.longitude,
    );

    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: userLatLng,
          icon: userIcon!,
          anchor: const Offset(0.5, 0.5),
          rotation: _userHeading,
          flat: true,
          zIndex: 2,
        ),
      );
    });
  }

  /// ----- REFRESH SENSOR MARKERS -----
  void _refreshSensorMarkers() async {
    final BitmapDescriptor sensorIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/sensor_location.png',
    );

    setState(() {
      _markers.removeWhere((m) => sensors.containsKey(m.markerId.value.replaceAll('_labeled', '')));

      if (!showAllSensors) return;

      sensors.forEach((id, sensor) {
        final String status = sensor['sensorData']['status'];

        if (showCriticalSensors) {
          if (status != 'Warning' && status != 'Danger') {
            return;
          }
        }

        final String uniqueId = showSensorLabels ? "${id}_labeled" : id;

        _markers.add(
          Marker(
            markerId: MarkerId(uniqueId),
            position: sensor['position'],
            icon: sensorIcon,
            anchor: const Offset(0.5, 0.5),
            infoWindow: showSensorLabels
                ? InfoWindow(title: id)
                : InfoWindow.noText,
            onTap: () => _onSensorTap(id, sensor),
            zIndex: 2,
          ),
        );
      });
    });
  }

  /// ----- GO TO USER -----
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

  /// ----- ON CAMERA MOVE -----
  void _onCameraMove(CameraPosition position) {
    _lastPosition = position;
    _mapBearing = position.bearing;
  }

  /// ----- RESET ORIENTATION -----
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

  /// ----- SHOW SELECT VEHICLE TOAST -----
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

  /// ----- ON MAP TAP -----
  void _onMapTap(LatLng position) async {

    if (selectedVehicle.isEmpty) {
      showSelectVehicleToast(context);
      return;
    } else {
      setState(() {
        showMainSheet = false;
      });
    }

    print("Saved Pin: ${savedPinPosition?.latitude}, ${savedPinPosition?.longitude}");
    print("User: ${currentPosition!.latitude}, ${currentPosition!.longitude}");

    final BitmapDescriptor pinIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/selected_location.png',
    );

    if (settingPin) {
      setState(() {
        searchEndLocation = true;
        // Remove previous tapped marker
        if (tappedMarker != null) _markers.remove(tappedMarker);

        // Add new tapped marker
        tappedMarker = Marker(
          markerId: const MarkerId('tapped_pin'),
          position: position,
          icon: pinIcon,
          anchor: const Offset(0.5, 1.0),
          zIndex: 2,
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

      if (savedStartPosition != null) {
        _drawRoute(savedStartPosition!, position);
      } else {
        // Draw polyline from user to tapped pin
        if (currentPosition != null) {
          _drawRoute(
            LatLng(currentPosition!.latitude, currentPosition!.longitude),
            position, // use the tapped location
          );
        }
      }

    }




    if (testingMode) {
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
  }

  /// ----- CANCEL PIN SELECTION -----
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

      // Remove temporary start pin
      if (startMarker != null) {
        _markers.remove(startMarker);
      }
      startMarker = null;
      startPosition = null;

      // Clear temporary start place
      startPlace = {
        "name": "",
        "location": LatLng(0.0, 0.0),
      };


    });

    if (savedStartPosition != null && savedPinPosition == null) {
      setState(() {
        _polylines.clear();
      });
    } else if (savedStartPosition != null && savedPinPosition != null) {
      _drawRoute(savedStartPosition!, savedPinPosition!);
    }else if (savedPinMarker != null && currentPosition != null) {
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

  /// ----- IS INSIDE AVOID ZONE -----
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

  /// ----- IS NEAR AVOID ZONE -----
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

  /// ----- GENERATE CIRCLE POLYGON -----
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

  /// ----- BUILD AVOID ZONES FROM SENSORS -----
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

  /// ----- DRAW ROUTE -----
  void _drawRoute(LatLng start, LatLng end) async {
    final avoidZones = buildAvoidZonesFromSensors();

    final route = await PolylineService.getRoute(
      start,
      end,
      normalRouting: normalRouting,
      avoidZones: avoidZones,
    );

    setState(() {
      _polylines.clear();

      _polylines.addAll([
        Polyline(
          polylineId: const PolylineId("route_border"),
          points: route,
          color: colorPolylineMain,
          width: 6,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
          zIndex: 2,
        ),

        Polyline(
          polylineId: const PolylineId("route_main"),
          points: route,
          color: colorPolylineBack,
          width: 4,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
          zIndex: 2,
        ),
      ]);
    });
  }

  /// ----- OPEN PLACE SEARCH -----
  Future<void> openPlaceSearch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const PlaceSearchPopup(),
      ),
    );

    if (result != null) {
      final LatLng? position = result['latLng']; // Might be null for Current Location
      final String name = result['name'];

      // Create pin icon
      final BitmapDescriptor pinIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/selected_location.png',
      );

      // --- CASE 1: SEARCH END LOCATION (Destination) ---
      if (searchEndLocation) {
        if (position == null) return; // Usually, destination requires a specific pin

        setState(() {
          if (tappedMarker != null) _markers.remove(tappedMarker);

          tappedMarker = Marker(
            markerId: const MarkerId('tapped_pin'),
            position: position,
            icon: pinIcon,
            anchor: const Offset(0.5, 1.0),
            zIndex: 2,
          );
          _markers.add(tappedMarker!);
          tappedPosition = position;

          currentPlace = {"name": name, "location": position};

          showPinConfirmationSheet = true;
          showDirectionSheet = false;
          showSensorSheet = false;
          showSensorSettingsSheet = false;
          showRerouteConfirmationSheet = false;
        });

        // Drawing logic for destination...
        _handleDestinationCamera(position);
      }

      // --- CASE 2: SEARCH START LOCATION (Starting Point) ---
      else if (searchStartLocation) {

        // IF "CURRENT LOCATION" WAS SELECTED
        if (position == null) {
          setState(() {
            // Reset everything related to custom start
            savedStartPosition = null;
            startPosition = null;

            if (startMarker != null) {
              _markers.remove(startMarker);
              startMarker = null;
            }
            if (savedStartMarker != null) {
              _markers.remove(savedStartMarker);
              savedStartMarker = null;
            }

            startPlace = {
              "name": "Current Location",
              "location": LatLng(currentPosition!.latitude, currentPosition!.longitude),
            };

            savedStartPlace = {
              "name": "",
              "location": LatLng(0.0, 0.0),
            };

            // Redraw from live GPS to destination
            if (savedPinPosition != null) {
              _drawRoute(
                LatLng(currentPosition!.latitude, currentPosition!.longitude),
                savedPinPosition!,
              );
            }
          });

          if (savedPinPosition != null){
            _handleDestinationCamera(savedPinPosition!);
          } else {
            _goToUser();
          }


        }
        // IF A SPECIFIC PLACE WAS SELECTED
        else {
          setState(() {
            if (startMarker != null) _markers.remove(startMarker);

            startMarker = Marker(
              markerId: const MarkerId('start_pin'),
              position: position,
              icon: pinIcon,
              anchor: const Offset(0.5, 1.0),
              zIndex: 2,
            );
            _markers.add(startMarker!);

            // CRITICAL: Update the temp variable that the Confirm button uses
            startPosition = position;

            startPlace = {
              "name": name,
              "location": position,
            };

            showPinConfirmationSheet = true;
            showDirectionSheet = false;
            showSensorSheet = false;
            showSensorSettingsSheet = false;
            showRerouteConfirmationSheet = false;
          });

          // Use 'position' directly here to ensure the line connects to the NEW pin
          if (savedPinPosition != null) {
            _drawRoute(position, savedPinPosition!);

            LatLngBounds bounds = LatLngBounds(
              southwest: LatLng(
                min(position.latitude, savedPinPosition!.latitude),
                min(position.longitude, savedPinPosition!.longitude),
              ),
              northeast: LatLng(
                max(position.latitude, savedPinPosition!.latitude),
                max(position.longitude, savedPinPosition!.longitude),
              ),
            );
            mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 120));
          } else {
            mapController.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: position, zoom: 15),
              ),
            );
          }
        }
      }
    }
  }

  /// ----- HANDLE DESTINATION CAMERA -----
  void _handleDestinationCamera(LatLng destination) {
    LatLng? start;
    if (savedStartPosition != null) {
      start = savedStartPosition!;
    } else if (currentPosition != null) {
      start = LatLng(currentPosition!.latitude, currentPosition!.longitude);
    }

    if (start != null) {
      _drawRoute(start, destination);
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(min(start.latitude, destination.latitude), min(start.longitude, destination.longitude)),
        northeast: LatLng(max(start.latitude, destination.latitude), max(start.longitude, destination.longitude)),
      );
      mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 120));
    }
  }

  /// ----- SHOW SELECT VEHICLE TOAST -----
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

  /// ----- GET FLOOD TILE OVERLAYS -----
  Set<TileOverlay> getFloodTileOverlays() {
    return {
      TileOverlay(
        tileOverlayId: TileOverlayId('xyz_tiles'),
        tileProvider: UrlTileProvider(
          urlTemplate: '$serverUri/media/tiles/{z}/{x}/{y}.png',
        ),
        transparency: 0.3,
        zIndex: 1,
      ),

    };
  }

  MapType _currentMapType = MapType.normal;

  /// ----- MAP TYPE TO STRING -----
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


  // ========================================
  // BUILD / CORE UI
  // ========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // 🚫 Prevents map/buttons from shifting up
      body: Stack(
        children: [
          /// Map Background
          GoogleMap(
            onMapCreated: (controller) {
              _onMapCreated(controller);

              // Animate zoom after map is ready
              if (currentPosition != null) {
                controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(currentPosition!.latitude, currentPosition!.longitude),
                      zoom: 17.0,
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
              zoom: 15.0,
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

            //minMaxZoomPreference: const MinMaxZoomPreference(13.0, 18.0),
          ),

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
                    backgroundColor: colorPrimaryMid,
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
                                  onTap: () {
                                    setState(() {
                                      searchStartLocation = true;
                                      searchEndLocation = false;
                                    });
                                    openPlaceSearch();
                                  },
                                  child: SizedBox(
                                    height: 50,
                                    child: Row(
                                      children: [
                                        Icon(
                                          (savedStartPosition == null) ? Icons.my_location : Icons.location_on,
                                          size: 20,
                                          color: (savedStartPosition == null) ? colorPrimary : colorDanger
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            savedStartPlace["name"] != ""
                                              ? savedStartPlace["name"]
                                              : (savedStartPosition != null
                                              ? "${savedStartPosition!.latitude.toStringAsFixed(5)}, ${savedStartPosition!.longitude.toStringAsFixed(5)}"
                                              : "Current Location"),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
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
                                  onTap: () {
                                    setState(() {
                                      searchStartLocation = false;
                                      searchEndLocation = true;
                                    });
                                    openPlaceSearch();
                                  },
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
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
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
                              setState(() {
                                showAllSensors = val;
                                showCriticalSensors = false;
                              });
                              _refreshSensorMarkers();
                            },
                          ),

                          _sensorToggleCard(
                            title: 'Show Sensor Range / Coverage',
                            description: 'Display sensor coverage area',
                            value: showSensorCoverage,
                            onChanged: (val) {
                              setState(() {
                                showSensorCoverage = val;
                              });
                            }
                          ),

                          _sensorToggleCard(
                            title: 'Alerted / Critical Sensors Only',
                            description: 'Show only sensors with alerts',
                            value: showCriticalSensors,
                            onChanged: (val) {
                              setState(() {
                                showCriticalSensors = val;
                                showAllSensors = !val;
                              });
                              _refreshSensorMarkers();
                            },
                          ),

                          _sensorToggleCard(
                            title: 'Sensor Labels',
                            description: 'Show sensor names or IDs on the map',
                            value: showSensorLabels,
                            onChanged: (val) {
                              setState(() {
                                showSensorLabels = val;
                              });
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
                      final location = sensor?['location'];


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
                              Icon(Icons.sensors, size: 32, color: colorPrimaryMid), // primary theme
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
                                _infoRow("Location", "$location"),
                                _infoRow(
                                    "Flood Height",
                                    data?['floodHeight'] != null
                                        ? "${UnitConverter.cmToFeet(double.tryParse(data!['floodHeight'].toString()) ?? 0).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} ft"
                                        : "-"
                                ),
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
                              onTap: () {

                                setState(() {
                                  sensorViewInfo = selectedSensorId!;
                                });
                                Navigator.pushNamed(context, '/info');

                              },
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
                                        fontFamily: 'AvenirNext',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: colorTextPrimary,
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

                          Row(
                            children: [
                              Expanded(
                                child: secondaryButton(
                                  text: "CANCEL",
                                  onTap: () {
                                    cancelPinSelection();
                                    _goToUser();
                                    setState(() {
                                      showPinConfirmationSheet = false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: primaryButton(
                                  text: "CONFIRM",
                                  onTap: () {
                                    setState(() {
                                      if (searchEndLocation) {
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
                                      }
                                      else if (searchStartLocation) {
                                        if (savedStartMarker != null) {
                                          _markers.remove(savedStartMarker);
                                        }

                                        savedStartMarker = startMarker;
                                        savedStartPosition = startPosition;
                                        savedStartPlace = Map.from(startPlace);

                                        startMarker = null;
                                        startPosition = null;
                                        startPlace = {
                                          "name": "",
                                          "location": LatLng(0.0, 0.0),
                                        };
                                      }

                                      showPinConfirmationSheet = false;
                                      showDirectionSheet = true;
                                      _circles.removeWhere((c) => c.circleId.value.startsWith('sensor'));
                                      _goToUser();

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

          ///Reroute Confirmation
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            bottom: showRerouteConfirmationSheet
                ? rerouteConfirmationDragOffset
                : -rerouteConfirmationSheetHeight,

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

                          Row(
                            children: [
                              Icon(Icons.alt_route_rounded, size: 30, color: colorPrimaryMid),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (savedPinPosition != null && savedPinPosition != "null")
                                          ? "Route Adjustment"
                                          : "Create Reroute",
                                      style: const TextStyle(
                                        fontFamily: 'AvenirNext',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: colorTextPrimary,
                                      ),
                                    ),
                                    Text(
                                      (savedPinPosition != null && savedPinPosition != "null")
                                          ? "Confirm to generate a safer alternate path."
                                          : "Confirm to select destination to reroute",
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
                                    final hasValidPin = savedPinPosition != null && savedPinPosition != "null";
                                    print("hasValidPin: $hasValidPin");
                                    setState(() {
                                      normalRouting = false;
                                      showRerouteConfirmationSheet = false;
                                    });

                                    if (!hasValidPin) {
                                      openPlaceSearch();
                                    } else {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        _drawRoute(
                                          LatLng(currentPosition!.latitude, currentPosition!.longitude),
                                          savedPinMarker!.position,
                                        );
                                      });
                                    }
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
                  iconColor: (showDirectionSheet) ? colorPrimaryMid : colorPrimaryDeep,
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
                  iconColor: (showSensorSettingsSheet) ? colorPrimaryMid : colorPrimaryDeep,
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
                  iconColor: (showRerouteConfirmationSheet) ? colorPrimaryMid : (displayAlert) ? Colors.red : colorPrimaryDeep,
                  buttonColor: (showRerouteConfirmationSheet) ? Colors.white : (displayAlert) ? colorAlertBg : Colors.white,
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
                      cancelPinSelection();
                    });
                  },
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: colorPrimaryMid,
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

  // ========================================
  // UI WIDGETS
  // ========================================

  /// ----- SMALL CARD -----
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

  /// ----- VEHICLE SELECTION -----
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
              color: colorBackground,
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

  /// ----- BOTTOM BUTTON -----
  Widget bottomButton({
    required VoidCallback onTap,
    required String imagePath,
    required String label,
    Color iconColor = colorPrimaryDeep,
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

  /// ----- SELECT VEHICLE -----
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
          color: (selectedVehicle == name) ? colorPrimaryMid : Colors.white,
          borderRadius: BorderRadius.circular(40 / 2),
        ),
        child: Center(
          child: Image.asset(
            imagePath,
            width: 25,
            height: 25,
            fit: BoxFit.contain,
            color: (selectedVehicle == name) ? Colors.white : colorPrimaryDeep,
            colorBlendMode: BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  /// ----- SENSOR TOGGLE CARD -----
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
        color: Colors.white,
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
            activeColor: colorPrimary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  /// ----- INFO ROW -----
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

  /// ----- STATUS ROW -----
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

