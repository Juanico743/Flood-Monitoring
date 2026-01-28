import 'dart:async';
import 'package:floodmonitoring/services/weather.dart';
import 'package:flutter/material.dart';
import 'package:floodmonitoring/services/flood_level.dart';
import 'package:floodmonitoring/utils/style.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/global.dart';

class Info extends StatefulWidget {
  const Info({super.key});

  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends State<Info> {
  final blynk = BlynkService();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchDataForSensor("sensor_01");
    getWeather("sensor_01");

    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => fetchDataForSensor("sensor_01"));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchDataForSensor(String sensorId) async {
    final sensor = sensors[sensorId];
    if (sensor == null) return;

    final String token = sensor['token'];
    final String pin = sensor['pin'];

    final data = await BlynkService().fetchDistance(token, pin);

    setState(() {
      sensors[sensorId]!['sensorData'] = data;
    });
  }

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
            _alertSection(),
            const SizedBox(height: 12),
            _advancedSection(),
          ],
        ),
      ),
    );
  }

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

  Widget _header() {
    final sensor = sensors["sensor_01"]!;

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
                "Ortigas Ave Sensor #1",
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

  Color dataStatusColor() {
    switch (sensors["sensor_01"]!["sensorData"]['status']) {
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

  Widget _liveMeasurements() {
    final sensor = sensors["sensor_01"]!;
    return _card(
      title: "Live Measurements",
      child: Column(
        children: [
          _item("Flood Height", "${sensor['sensorData']['floodHeight']} cm"),
          _item("Distance to Water", "${sensor['sensorData']['distance']} cm"),
          _item("Flood Status", sensor['sensorData']['status'],
              color: dataStatusColor()), // icon removed
          _item("Last Update", sensor['sensorData']['lastUpdate']),
        ],
      ),
    );
  }

  Widget _sensorDetails() {
    return _card(
      title: "Sensor Details",
      child: Column(
        children: [
          _item("Location", "Ortigas Ave Sensor"),
          _item("Monitoring Radius", "20 meters"),
          _item("Battery Level", "85%"),
          _item("Connection", "Online"),
        ],
      ),
    );
  }

  Widget _weatherSection() {
    final weather = sensors["sensor_01"]!['weatherData'];
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

  Widget _alertSection() {
    return _card(
      title: "Alerts",
      child: const Text(
        "No active alerts",
        style: TextStyle(fontSize: 16, color: Colors.black54),
      ),
    );
  }

  Widget _advancedSection() {
    return _card(
      title: "Advanced Info",
      child: Column(
        children: [
          _item("Sensor ID", "SN-1028391"),
          _item("Blynk Token", "••••••••••••••••••••"),
        ],
      ),
    );
  }

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

  Widget _item(String name, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4), // smaller gap
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
