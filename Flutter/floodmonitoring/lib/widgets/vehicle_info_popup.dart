import 'package:floodmonitoring/services/global.dart';
import 'package:floodmonitoring/utils/converters.dart';
import 'package:floodmonitoring/utils/style.dart';
import 'package:flutter/material.dart';

class VehicleInfoPopup {
  /// Show vehicle info popup
  static void show(
      BuildContext context,
      String vehicleName, {
        Function(String selectedVehicle)? onConfirm,
        Function(String selectedVehicle)? onCancel,
      }) {
    // Pull the data dynamically from our getter
    final data = _getVehicleData[vehicleName];
    if (data == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String selectedVehicle = vehicleName;

        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Container(
                  width: 350,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TITLE
                      Text(
                        vehicleName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // DESCRIPTION
                      Text(
                        data.description,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // LEVELS (Connected to global.dart)
                      _levelRow("Safe", data.safe, Colors.green),
                      _levelRow("Warning", data.warning, Colors.orange),
                      _levelRow("Danger", data.danger, Colors.red),

                      const SizedBox(height: 20),

                      // VEHICLE TYPE SELECTION
                      if (vehicleName == "Bicycle") ...[
                        const Text(
                          "Select Type",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedVehicle = "Motorcycle";
                                  });
                                },
                                child: Container(
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: selectedVehicle == "Motorcycle"
                                        ? color1
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "2 Wheels",
                                      style: TextStyle(
                                        color: selectedVehicle == "Motorcycle"
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedVehicle = "Bicycle";
                                  });
                                },
                                child: Container(
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: selectedVehicle == "Bicycle"
                                        ? color1
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "3 Wheels",
                                      style: TextStyle(
                                        color: selectedVehicle == "Bicycle"
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // BUTTON ROW
                      Row(
                        children: [
                          Expanded(
                            child: secondaryButton(
                              text: "CANCEL",
                              onTap: () {
                                if (onCancel != null) {
                                  onCancel(selectedVehicle);
                                }
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: primaryButton(
                              text: "CONFIRM",
                              onTap: () {
                                if (onConfirm != null) {
                                  onConfirm(selectedVehicle);
                                }
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  static Widget _levelRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  /// HELPER: Formats the list range [min, max] into a readable string
  static String _formatRange(List<dynamic> range) {
    String formatValue(double cm) {
      double inches = UnitConverter.cmToInches(cm);

      // 1. Format to 1 decimal place (e.g., 10.0 or 10.5)
      // 2. Remove .0 if it exists using RegExp
      return inches.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    }

    String low = formatValue(range[0].toDouble());

    if (range[1] == double.infinity) {
      return "$low+ in";
    }

    String high = formatValue(range[1].toDouble());
    return "$low - $high in";
  }

  /// DYNAMIC DATA MAP: Connects to vehicleFloodThresholds from global.dart
  static Map<String, _VehicleFloodInfo> get _getVehicleData {
    // Helper to find threshold by vehicle name
    Map<String, dynamic> findThreshold(String name) {
      return vehicleFloodThresholds.firstWhere(
            (element) => element["vehicle"] == name,
        orElse: () => vehicleFloodThresholds.first,
      );
    }

    final bicycleT = findThreshold("Bicycle");
    final motorcycleT = findThreshold("Motorcycle");
    final carT = findThreshold("Car");
    final truckT = findThreshold("Truck");

    return {
      "Bicycle": _VehicleFloodInfo(
        description: "Bicycles are extremely vulnerable to flooding. Even shallow water can affect balance, braking, and visibility. Riding through flooded areas is highly risky and should be avoided.",
        safe: _formatRange(bicycleT["safeRange_cm"]),
        warning: _formatRange(bicycleT["warningRange_cm"]),
        danger: _formatRange(bicycleT["dangerRange_cm"]),
      ),
      "Motorcycle": _VehicleFloodInfo(
        description: "Motorcycles are very vulnerable to floods even at low levels. Unlike cars and trucks, they can easily lose balance or submerge. Extra caution is needed when riding in flood-prone areas.",
        safe: _formatRange(motorcycleT["safeRange_cm"]),
        warning: _formatRange(motorcycleT["warningRange_cm"]),
        danger: _formatRange(motorcycleT["dangerRange_cm"]),
      ),
      "Car": _VehicleFloodInfo(
        description: "Cars can normally withstand floods that are below the door step. They are less vulnerable than motorcycles but may still be at risk if water rises higher than the engine level.",
        safe: _formatRange(carT["safeRange_cm"]),
        warning: _formatRange(carT["warningRange_cm"]),
        danger: _formatRange(carT["dangerRange_cm"]),
      ),
      "Truck": _VehicleFloodInfo(
        description: "Trucks can handle large floods because of their size and higher chassis. They are the safest among common vehicles in deep water, but caution is still advised in extreme flood conditions.",
        safe: _formatRange(truckT["safeRange_cm"]),
        warning: _formatRange(truckT["warningRange_cm"]),
        danger: _formatRange(truckT["dangerRange_cm"]),
      ),
    };
  }
}

class _VehicleFloodInfo {
  final String description;
  final String safe;
  final String warning;
  final String danger;

  const _VehicleFloodInfo({
    required this.description,
    required this.safe,
    required this.warning,
    required this.danger,
  });
}