import 'dart:async';
import 'dart:convert';
import 'package:floodmonitoring/services/weather.dart';
import 'package:floodmonitoring/utils/converters.dart';
import 'package:floodmonitoring/utils/style.dart';
import 'package:flutter/material.dart';
import 'package:floodmonitoring/services/flood_level.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import '../services/global.dart';

class Info extends StatefulWidget {
  const Info({super.key});

  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends State<Info> {

  // ========================================
  // STATE / VARIABLES
  // ========================================

  final blynk = BlynkService();
  Timer? _timer;

  List<FlSpot> hourlyData = [];
  List<String> labels = ["", "", ""];

  // ========================================
  // INITIALIZATION (initState)
  // ========================================

  @override
  void initState() {
    super.initState();
    fetchDataForSensor(sensorViewInfo);
    getWeather(sensorViewInfo);
    loadSensorHistoryView(sensorViewInfo);

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

  /// ----- LOAD SENSOR HISTORY VIEW -----
  Future<void> loadSensorHistoryView(String sensorId) async {
    try {
      String uri = '$serverUri/api/get-sensor-history/';

      var res = await http.post(
        Uri.parse(uri),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"sensor_id": sensorId}),
      );

      var response = jsonDecode(res.body);

      if (res.statusCode == 200 && response['success'] == true) {
        // Map the dynamic list from JSON to FlSpot objects
        List<FlSpot> fetchedSpots = (response['hourlyData'] as List)
            .map((item) => FlSpot(item['x'].toDouble(), item['y'].toDouble()))
            .toList();

        setState(() {
          hourlyData = fetchedSpots;
          labels = List<String>.from(response['labels']);
        });

        print("History Loaded Successfully");
      }
    } catch (e) {
      print("Error fetching sensor history: $e");
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
            _historyGraph(),
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

  /// ----- HISTORY GRAPH -----
  Widget _historyGraph() {
    return _card(
      title: "24-Hour Flood Levels (Hourly)",
      child: SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: 23,
            lineTouchData: LineTouchData(
              getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                return spotIndexes.map((index) {
                  return TouchedSpotIndicatorData(
                    FlLine(
                      color: Colors.blueAccent.withOpacity(0.5),
                      strokeWidth: 2,
                    ),
                    FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeColor: Colors.blueAccent,
                            strokeWidth: 2,
                          ),
                    ),
                  );
                }).toList();
              },
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => Colors.white,
                tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                tooltipMargin: 10,
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((LineBarSpot touchedSpot) {
                    int index = touchedSpot.x.toInt();

                    String dateTimeLabel = (index >= 0 && index < labels.length)
                        ? labels[index]
                        : "Loading...";

                    return LineTooltipItem(
                      '',
                      const TextStyle(fontSize: 0),
                      children: [
                        TextSpan(
                          text: "$dateTimeLabel\n",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: "${touchedSpot.y.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(
                          text: " ft",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }).toList();
                },
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              checkToShowVerticalLine: (value) => value % 6 == 0,
              getDrawingVerticalLine: (value) => FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
            ),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 35,
                  getTitlesWidget: (value, meta) => Text(
                    "${value.toStringAsFixed(1)}ft",
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (labels.isEmpty || index < 0 || index >= labels.length) {
                      return const SizedBox.shrink();
                    }

                    if (index % 4 == 0 || index == 23) {
                      return _dateLabel(labels[index]);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: hourlyData,
                isCurved: true,
                curveSmoothness: 0.1,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                gradient: const LinearGradient(
                  colors: [gradientEnd, gradientStart],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      gradientEnd.withOpacity(0.0),
                      gradientStart.withOpacity(0.3),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ----- DATE LABEL WIDGET -----
  Widget _dateLabel(String text) {
    String militaryTime = text.contains(',') ? text.split(',')[1].trim() : text;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 1.5,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          militaryTime,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
