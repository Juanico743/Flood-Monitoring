import 'package:floodmonitoring/services/global.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:floodmonitoring/widgets/custom_app_bar.dart'; // <-- use our reusable AppBar

class RecentAlert extends StatefulWidget {
  const RecentAlert({super.key});

  @override
  State<RecentAlert> createState() => _RecentAlertState();
}

class _RecentAlertState extends State<RecentAlert> {
  final Color themeBlue = Colors.blueAccent;

  @override
  Widget build(BuildContext context) {
    // Convert SENSOR map → alert list
    final List<Map<String, dynamic>> alerts = sensors.entries.map((e) {
      final name = e.key;
      final data = e.value;
      final sensor = data["sensorData"];

      return {
        "location": name,
        "status": sensor["status"],
        "level": "Flood Level: ${sensor['distance']} cm",
      };
    }).toList();

    // Filter only Warning & Danger alerts
    final activeAlerts = alerts
        .where((a) => a['status'] == 'Warning' || a['status'] == 'Danger')
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: "Recent Alerts",
        backgroundColor: themeBlue,
        onBack: () => Navigator.pop(context),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: activeAlerts.isEmpty
            ? Center(
          child: Text(
            "No active alerts",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontFamily: 'AvenirNext',
            ),
          ),
        )
            : ListView.builder(
          itemCount: activeAlerts.length,
          itemBuilder: (context, index) {
            final alert = activeAlerts[index];
            return _alertCard(alert);
          },
        ),
      ),
    );
  }

  Widget _alertCard(Map<String, dynamic> alert) {
    Color statusColor;
    IconData statusIcon;

    switch (alert['status']) {
      case 'Warning':
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.warning_amber_rounded;
        break;
      case 'Danger':
        statusColor = Colors.redAccent;
        statusIcon = Icons.dangerous_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Left info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['location'] ?? "-",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'AvenirNext',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  alert['level'] ?? "-",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontFamily: 'AvenirNext',
                  ),
                ),
              ],
            ),
          ),

          // Right status icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 28),
          ),
        ],
      ),
    );
  }
}
