import 'package:flutter/material.dart';
import 'package:floodmonitoring/utils/style.dart';

void showMapSettingsPopup(
    BuildContext context, {
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
                width: 380,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// HEADER (modernized)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.layers_rounded, color: colorPrimary, size: 26),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Map Appearance",
                                style: TextStyle(
                                  fontFamily: 'AvenirNext',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: colorTextPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Select map style and overlays",
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
                    ),

                    // Divider removed

                    /// CONTENT
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle("Map Style"),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.1,
                              children: [
                                mapImageOption(
                                  label: "Normal",
                                  image: "assets/images/layers/normal.png",
                                  selected: selectedMapType == "Normal",
                                  onTap: () => setState(() => selectedMapType = "Normal"),
                                ),
                                mapImageOption(
                                  label: "Satellite",
                                  image: "assets/images/layers/satellite.png",
                                  selected: selectedMapType == "Satellite",
                                  onTap: () => setState(() => selectedMapType = "Satellite"),
                                ),
                                mapImageOption(
                                  label: "Hybrid",
                                  image: "assets/images/layers/hybrid.png",
                                  selected: selectedMapType == "Hybrid",
                                  onTap: () => setState(() => selectedMapType = "Hybrid"),
                                ),
                                mapImageOption(
                                  label: "Terrain",
                                  image: "assets/images/layers/terrain.png",
                                  selected: selectedMapType == "Terrain",
                                  onTap: () => setState(() => selectedMapType = "Terrain"),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _sectionTitle("Overlays"),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.1,
                              children: [
                                mapImageOption(
                                  label: "None",
                                  image: "assets/images/layers/none.png",
                                  selected: selectedLayer == "None",
                                  onTap: () {
                                    setState(() {
                                      selectedLayer = "None";
                                      showFloodZones = false;
                                    });
                                  },
                                ),
                                mapImageOption(
                                  label: "Flood Zones",
                                  image: "assets/images/layers/gis.png",
                                  selected: selectedLayer == "Flood GIS",
                                  onTap: () {
                                    setState(() {
                                      selectedLayer = "Flood GIS";
                                      showFloodZones = true;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    /// ACTION BUTTONS
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
                              text: "APPLY",
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
/// SECTION TITLE
/// =======================
Widget _sectionTitle(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: TextStyle(
        fontFamily: 'AvenirNext',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    ),
  );
}

/// =======================
/// IMAGE OPTION CARD
/// =======================
Widget mapImageOption({
  required String label,
  required String image,
  required bool selected,
  required VoidCallback onTap,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? Colors.blue : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: selected ? Colors.blue.withOpacity(0.25) : Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          /// IMAGE PREVIEW
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),

          /// LABEL
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'AvenirNext',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.blue : Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
