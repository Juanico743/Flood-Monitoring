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


/// ----- SECTION TITLE -----
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

/// ----- MAP IMAGE OPTION -----
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
          width: 1.5,
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

void showInfoHeatMap(BuildContext context) {
  final List<String> cardImages = [
    'assets/images/cards/FHM1.png',
    'assets/images/cards/FHM2.png',
    'assets/images/cards/FHM3.png',
    'assets/images/cards/FHM4.png',
  ];

  // Border colors for the 4 distinct cards
  final List<Color> cardBorderColors = [
    Colors.blue,       // Card 1 Border
    Colors.red,        // Card 2 Border
    Colors.orange,     // Card 3 Border
    Colors.yellow,     // Card 4 Border
  ];

  // Bottom gradient solid colors (Card 1 is now White)
  final List<Color> cardGradientColors = [
    Colors.white,      // Card 1 Gradient Bottom
    Colors.red,        // Card 2 Gradient Bottom
    Colors.orange,     // Card 3 Gradient Bottom
    Colors.yellow,     // Card 4 Gradient Bottom
  ];

  final List<Map<String, String>> cardContent = [
    {"title": "Flood Risk Levels", "sub": ""},
    {"title": "High Hazard", "sub": "Over 1.5 meters"},
    {"title": "Medium Hazard", "sub": "0.5 to 1.5 meters"},
    {"title": "Low Hazard", "sub": "Less than 0.5 meters"},
  ];

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      int currentPage = 0;

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
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
          child: Stack(
            children: [
              /// Close ("X") Button
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 20,
                ),
              ),

              /// Main Dialog Body
              StatefulBuilder(
                builder: (context, setPopupState) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// 1. Swipeable Cards Carousel
                        SizedBox(
                          height: 220,
                          child: PageView.builder(
                            itemCount: cardImages.length,
                            onPageChanged: (index) {
                              setPopupState(() {
                                currentPage = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              final Color borderColor = cardBorderColors[index % cardBorderColors.length];
                              final Color gradientColor = cardGradientColors[index % cardGradientColors.length];
                              final Map<String, String> content = cardContent[index];

                              // Use dark text for White (index 0) and Yellow (index 3) cards
                              final bool useDarkText = index == 0 || index == 3;

                              final Color titleColor = useDarkText ? Colors.black : Colors.white;
                              final Color subTextColor = useDarkText ? Colors.black87 : Colors.white.withOpacity(0.85);

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Stack(
                                    children: [
                                      /// Layer 1: Background Image
                                      Positioned.fill(
                                        child: Image.asset(
                                          cardImages[index],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey.shade200,
                                              child: const Center(
                                                child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                      /// Layer 2: Overlay Container with Gradient
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: borderColor,
                                              width: 1.5,
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                gradientColor.withOpacity(0.5),
                                                gradientColor,
                                              ],
                                              stops: const [0.0, 0.5, 1.0],
                                            ),
                                          ),
                                        ),
                                      ),

                                      /// Layer 3: Text Content (Bottom Left)
                                      Positioned(
                                        left: 16,
                                        bottom: 16,
                                        right: 16,
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // 🔴 Circular Colored Dot (Only for Cards 2, 3, 4)
                                            if (index > 0) ...[
                                              Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                    color: borderColor,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 2,
                                                    ),
                                                    boxShadow: const [
                                                      BoxShadow(
                                                        color: Colors.black12,
                                                        blurRadius: 2,
                                                      )
                                                    ]
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                            ],

                                            // 📝 Title and Subtext grouped together
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    content["title"]!,
                                                    style: TextStyle(
                                                      fontFamily: 'AvenirNext',
                                                      fontSize: 19,
                                                      fontWeight: FontWeight.w700,
                                                      color: titleColor,
                                                      letterSpacing: -0.3,
                                                    ),
                                                  ),
                                                  if (content["sub"]!.isNotEmpty) ...[
                                                    const SizedBox(height: 1),
                                                    Text(
                                                      content["sub"]!,
                                                      style: TextStyle(
                                                        fontFamily: 'AvenirNext',
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w500,
                                                        color: subTextColor,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// 2. Centered Pagination Capsule (Outside Card Layout)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.50),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              cardImages.length,
                                  (dotIndex) => AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                height: 7,
                                width: currentPage == dotIndex ? 18 : 7,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(currentPage == dotIndex ? 1.0 : 0.4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}