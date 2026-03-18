import 'dart:async';
import 'package:floodmonitoring/services/weather.dart';
import 'package:floodmonitoring/utils/converters.dart';
import 'package:flutter/material.dart';
import 'package:floodmonitoring/services/flood_level.dart';
import '../services/global.dart';

class Info extends StatefulWidget {
  const Info({super.key});

  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends State<Info> {
  final blynk = BlynkService();
  Timer? _timer;

  // ========================================
  // INITIALIZATION (initState)
  // ========================================

  @override
  void initState() {
    super.initState();
    fetchDataForSensor(sensorViewInfo);
    getWeather(sensorViewInfo);

    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => fetchDataForSensor(sensorViewInfo));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ========================================
  // LOGIC / HELPER FUNCTIONS
  // ========================================


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
  }

  /// ----- GET WEATHER -----
  Future<void> getWeather(String sensorId) async {
    final sensor = sensors[sensorId];
    if (sensor == null) return;

    final weather =
    await loadWeather(sensor['position'].latitude, sensor['position'].longitude);

    if (weather != null) {
      setState(() {
        sensor['weatherData'] = {
          "temperature": weather['temperature'],
          "description": weather['description'],
          "pressure": weather['pressure'],
        };
      });
    }
  }



  // ========================================
  // BUILD / CORE UI
  // ========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: _customAppBar("Sensor Information"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 12),
            _liveMeasurements(),
            const SizedBox(height: 12),
            _sensorDetails(),
            const SizedBox(height: 12),
            _weatherSection(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ========================================
  // UI WIDGETS
  // ========================================

  /// ----- CUSTOM APP BAR -----
  Widget _customAppBar(String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                    fontFamily: 'AvenirNext',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ----- HEADER -----
  Widget _header() {
    final sensor = sensors[sensorViewInfo]!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.sensors, color: Colors.blueAccent, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sensorViewInfo,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Flood Monitoring Unit",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                decoration: BoxDecoration(
                  color: dataStatusColor(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sensor['sensorData']['status'],
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  /// ----- DATA STATUS COLOR -----
  Color dataStatusColor() {
    switch (sensors[sensorViewInfo]!["sensorData"]['status']) {
      case 'Safe':
        return Colors.green;
      case 'Warning':
        return Colors.orange;
      case 'Danger':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// ----- LIVE MEASUREMENTS -----
  Widget _liveMeasurements() {
    final sensor = sensors[sensorViewInfo]!;
    return _card(
      title: "Live Measurements",
      child: Column(
        children: [
          _item(
              "Flood Height",
              "${UnitConverter.cmToFeet((sensor['sensorData']['floodHeight'] as num).toDouble()).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} ft"
          ),
          _item("Distance to Water", "${sensor['sensorData']['distance']} cm"),
          _item("Flood Status", sensor['sensorData']['status'],
              color: dataStatusColor()),
          _item("Last Update", sensor['sensorData']['lastUpdate']),
        ],
      ),
    );
  }

  /// ----- SENSOR DETAILS -----
  Widget _sensorDetails() {
    final sensor = sensors[sensorViewInfo]!;

    return _card(
      title: "Sensor Details",
      child: Column(
        children: [
          _item("Location", "${sensor['location']}"),
          _item("Monitoring Radius", "${sensor['radius']} m"),
          _item("Monitoring Height", "${sensor['height']} m"),
          _item("Connection", "Online"),
        ],
      ),
    );
  }

  /// ----- WEATHER SECTION -----
  Widget _weatherSection() {
    final weather = sensors[sensorViewInfo]!['weatherData'];
    return _card(
      title: "Weather",
      child: Column(
        children: [
          _item("Temperature", "${weather['temperature']}°C"),
          _item("Condition", "${weather['description']}"),
          _item("Pressure", "${weather['pressure']} hPa"),
        ],
      ),
    );
  }

  /// ----- GENERAL CARD -----
  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  /// ----- ITEM WIDGET -----
  Widget _item(String name, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 15)),
          Text(
            value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color ?? Colors.black87),
          ),
        ],
      ),
    );
  }
}
