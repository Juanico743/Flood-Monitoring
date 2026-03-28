import 'package:floodmonitoring/services/global.dart';
import 'package:floodmonitoring/utils/converters.dart';
import 'package:floodmonitoring/utils/style.dart';
import 'package:flutter/material.dart';

class VehicleInfoPopup {

  static void show(
      BuildContext context,
      String vehicleName, {
        Function(String selectedVehicle)? onConfirm,
        Function(String selectedVehicle)? onCancel,
      }) {
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

                      // VEHICLE TYPE SELECTION FOR BICYCLE
                      if (vehicleName == "Bicycle") ...[
                        const Text(
                          "Select Type",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildSelectionCard(
                              label: "2 Wheels",
                              isSelected: selectedVehicleType == "2Wheels",
                              onTap: () {
                                setState(() {
                                  selectedVehicle = "Bicycle";
                                  selectedVehicleType = "2Wheels";
                                });
                              },
                            ),
                            const SizedBox(width: 12),
                            _buildSelectionCard(
                              label: "3 Wheels",
                              isSelected: selectedVehicleType == "3Wheels",
                              onTap: () {
                                setState(() {
                                  selectedVehicle = "Bicycle";
                                  selectedVehicleType = "3Wheels";
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // VEHICLE TYPE SELECTION FOR BICYCLE
                      if (vehicleName == "Motorcycle") ...[
                        const Text(
                          "Select Type",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildSelectionCard(
                              label: "Motorcycle",
                              isSelected: selectedVehicleType == "Motorcycle",
                              onTap: () {
                                setState(() {
                                  selectedVehicle = "Motorcycle";
                                  selectedVehicleType = "Motorcycle";
                                });
                              },
                            ),
                            const SizedBox(width: 12),
                            _buildSelectionCard(
                              label: "Tricycle",
                              isSelected: selectedVehicleType == "Tricycle",
                              onTap: () {
                                setState(() {
                                  selectedVehicle = "Motorcycle";
                                  selectedVehicleType = "Tricycle";
                                });
                              },
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

  static Widget _buildSelectionCard({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 46,
          decoration: BoxDecoration(
            color: colorBackground,
            // Using a slightly larger radius for the main card for a modern look
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colorPrimaryMid : Colors.transparent,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // THE OUTER CONTAINER (The Radio Border)
              Container(
                height: 20,
                width: 20,
                decoration: BoxDecoration(
                  // Using 100 instead of BoxShape.circle for smoother rendering
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isSelected ? colorPrimaryMid : Colors.grey[400]!,
                    width: 1.8,
                  ),
                  color: Colors.white,
                ),
                child: Center(
                  // THE INNER DOT
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: isSelected ? 10 : 0,
                    width: isSelected ? 10 : 0,
                    decoration: BoxDecoration(
                      color: colorPrimaryMid,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.black54,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
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
      double inches = UnitConverter.cmToFeet(cm);

      // 1. Format to 1 decimal place (e.g., 10.0 or 10.5)
      // 2. Remove .0 if it exists using RegExp
      return inches.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    }

    String low = formatValue(range[0].toDouble());

    if (range[1] == double.infinity) {
      return "$low+ ft";
    }

    String high = formatValue(range[1].toDouble());
    return "$low - $high ft";
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