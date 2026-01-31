import 'package:floodmonitoring/services/global.dart';
import 'package:floodmonitoring/utils/style.dart';
import 'package:flutter/material.dart';

class VehicleInfoPopup {
  /// Show vehicle info popup
  /// `onConfirm` returns the selected vehicle as String
  /// `onCancel` behaves exactly the same but fires on cancel
  static void show(
      BuildContext context,
      String vehicleName, {
        Function(String selectedVehicle)? onConfirm,
        Function(String selectedVehicle)? onCancel,
      }) {
    final data = _vehicleData[vehicleName];
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

                      // LEVELS
                      _levelRow("Safe", data.safe, Colors.green),
                      _levelRow("Warning", data.warning, Colors.orange),
                      _levelRow("Danger", data.danger, Colors.red),

                      const SizedBox(height: 20),

                      // VEHICLE TYPE SELECTION (Bicycle only)
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

  // LEVEL ROW WIDGET
  static Widget _levelRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // VEHICLE DATA
  static final Map<String, _VehicleFloodInfo> _vehicleData = {
    "Bicycle": const _VehicleFloodInfo(
      description:
      "Bicycles are extremely vulnerable to flooding. Even shallow water can affect balance, braking, and visibility. Riding through flooded areas is highly risky and should be avoided.",
      safe: "0–5 cm",
      warning: "5.1–15 cm",
      danger: "15.1+ cm",
    ),
    "Motorcycle": const _VehicleFloodInfo(
      description:
      "Motorcycles are very vulnerable to floods even at low levels. Unlike cars and trucks, they can easily lose balance or submerge. Extra caution is needed when riding in flood-prone areas.",
      safe: "0–20 cm",
      warning: "20.1–50 cm",
      danger: "50.1+ cm",
    ),
    "Car": const _VehicleFloodInfo(
      description:
      "Cars can normally withstand floods that are below the door step. They are less vulnerable than motorcycles but may still be at risk if water rises higher than the engine level.",
      safe: "0–15 cm",
      warning: "15.1–30 cm",
      danger: "30.1+ cm",
    ),
    "Truck": const _VehicleFloodInfo(
      description:
      "Trucks can handle large floods because of their size and higher chassis. They are the safest among common vehicles in deep water, but caution is still advised in extreme flood conditions.",
      safe: "0–40 cm",
      warning: "40.1–60 cm",
      danger: "60.1+ cm",
    ),
  };
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
