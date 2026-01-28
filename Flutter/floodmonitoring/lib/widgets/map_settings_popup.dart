import 'package:flutter/material.dart';
import 'package:floodmonitoring/utils/style.dart';

void showMapSettingsPopup(BuildContext context, {
  required String initialMapType,
  required String initialLayer,
  required Function(String mapType, String layer) onConfirm,
  bool initialFloodZone = false,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      String selectedMapType = initialMapType;
      String selectedLayer = initialLayer;
      bool showFloodZones = initialFloodZone;

      return WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                width: 360,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                      child: Row(
                        children: const [
                          Icon(Icons.layers, color: color1),
                          SizedBox(width: 10),
                          Text(
                            "Map Settings",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    const Divider(),

                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Map Type", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 10),

                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 1.1,
                              children: [
                                mapOptionCard("Normal", Icons.map, selectedMapType == "Normal",
                                        () => setState(() => selectedMapType = "Normal")),
                                mapOptionCard("Satellite", Icons.satellite, selectedMapType == "Satellite",
                                        () => setState(() => selectedMapType = "Satellite")),
                                mapOptionCard("Hybrid", Icons.public, selectedMapType == "Hybrid",
                                        () => setState(() => selectedMapType = "Hybrid")),
                                mapOptionCard("Terrain", Icons.terrain, selectedMapType == "Terrain",
                                        () => setState(() => selectedMapType = "Terrain")),
                              ],
                            ),

                            const SizedBox(height: 18),
                            const Text("Layers", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 10),

                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 1.1,
                              children: [
                                mapOptionCard("None", Icons.layers_clear, selectedLayer == "None", () {
                                  setState(() {
                                    selectedLayer = "None";
                                    showFloodZones = false;
                                  });
                                }),
                                mapOptionCard("Flood GIS", Icons.water, selectedLayer == "Flood GIS", () {
                                  setState(() {
                                    selectedLayer = "Flood GIS";
                                    showFloodZones = true;
                                  });
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: secondaryButton(
                              text: "CANCEL",
                              onTap: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: primaryButton(
                              text: "CONFIRM",
                              onTap: () {
                                onConfirm(selectedMapType, selectedLayer);
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
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

/// =======================
/// MODERN OPTION CARD
/// =======================
Widget mapOptionCard(String name, IconData icon, bool isSelected, VoidCallback onTap) {
  return InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? color1.withOpacity(0.12) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? color1 : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: isSelected ? color1 : Colors.black54),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? color1 : Colors.black87,
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle, size: 16, color: color1),
        ],
      ),
    ),
  );
}
