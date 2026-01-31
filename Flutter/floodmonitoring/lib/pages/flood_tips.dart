import 'package:floodmonitoring/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FloodTips extends StatefulWidget {
  const FloodTips({super.key});

  @override
  State<FloodTips> createState() => _FloodTipsState();
}

class _FloodTipsState extends State<FloodTips> {
  String selectedVehicle = 'Motorcycle';

  final Color themeBlue = Colors.blueAccent;

  final Map<String, String> vehicleTips = {
    'Bicycle': """
Bicycles lack stability in water. Even 10cm of moving water can wash a cyclist away, and submerged hazards are invisible.

• **Check Depth:** If you can't see the bottom, don't ride through. Potholes or missing manhole covers can cause a total wipeout.
• **Walk It:** If you must cross, dismount and walk your bike on the highest ground (usually the center of the road).
• **Braking Power:** Rim brakes lose nearly all effectiveness when wet. Pump your brakes frequently after exiting water to dry them.
• **Avoid Currents:** Never attempt to cross moving water; the lateral pressure on your wheels can easily sweep the bike from under you.
""",
    'Motorcycle': """
Motorcycles are at high risk of engine "hydro-lock" and loss of traction. Water in the intake will kill the engine instantly.

• **Steady Revs:** Maintain a steady, slightly high RPM in a low gear. Do not let go of the throttle; back-pressure helps prevent water from entering the exhaust.
• **The Bow Wave:** Drive slowly to avoid creating a splash that enters your air intake (usually located under the seat or tank).
• **Center of the Road:** Aim for the crown (middle) of the road where water is shallowest.
• **Post-Flood Check:** After crossing, "drag" your brakes lightly for a few meters to generate heat and dry the pads/discs.
• **Electrical Risk:** If the water reaches the spark plugs, the bike will stall. If it stalls in water, do NOT try to restart it.
""",
    'Car': """
Modern cars are vulnerable to electronics failure and engine damage in floods. 30cm of water is enough to float many passenger vehicles.

• **The 15cm Rule:** Avoid driving through water deeper than the center of your wheels.
• **One-at-a-Time:** Wait for oncoming traffic to pass. Their "bow wave" can push water over your hood and into your engine intake.
• **Low Gear, High Revs:** In manuals, slip the clutch; in automatics, stay in the lowest gear (L or 1) to keep exhaust pressure up.
• **Don't Stop:** Maintain a slow, constant speed (3-5 mph). Stopping mid-flood allows water to seep into the cabin and exhaust.
• **Brake Test:** Once clear, tap your brakes repeatedly to dry them. Wet brakes have significantly longer stopping distances.
""",
    'Truck': """
While trucks have higher clearance, their large surface area makes them more susceptible to being pushed by strong currents.

• **Check Air Intakes:** Know where your intake is. Many modern trucks have low-mounted intakes that can suck in water even if the body looks high.
• **Cargo Stability:** Water can make a truck buoyant. If your trailer is empty, it is much more likely to float or be swept away.
• **Watch the Wake:** Large tires create significant wakes that can flood smaller vehicles nearby. Be a responsible driver and keep speed at a crawl.
• **Differential Care:** After deep water crossing, have your differentials and transmission fluids checked; water can seep in through breathers and contaminate the oil.
""",
  };

  final List<String> vehicleList = ['Bicycle', 'Motorcycle', 'Car', 'Truck'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: "Flood Safety Tips",
        backgroundColor: themeBlue,
        onBack: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          // ----- Vehicle Selection (Small buttons, scrollable) -----
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: vehicleList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                String vehicle = vehicleList[index];
                bool isSelected = selectedVehicle == vehicle;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedVehicle = vehicle;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? themeBlue : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? themeBlue : Colors.grey.shade300,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/icons/${vehicle.toLowerCase()}.png',
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          vehicle,
                          style: TextStyle(
                            fontFamily: 'AvenirNext',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // ----- Tips Scrollable Section -----
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _card(selectedVehicle, vehicleTips[selectedVehicle]!),
            ),
          ),
        ],
      ),
    );
  }

  // ----- Card UI -----
  Widget _card(String title, String tip) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title Tips & Safety",
            style: const TextStyle(
              fontFamily: 'AvenirNext',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          // Parse **bold**
          _parseBoldText(tip),
          const SizedBox(height: 20),
          // Illustration
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
              image: const DecorationImage(
                image: AssetImage('assets/images/flood-cars.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Always prioritize safety. If water levels are high, wait or take alternate routes. Flooded roads can hide deep potholes, debris, or strong currents that can easily endanger lives.",
            style: TextStyle(
              fontFamily: 'AvenirNext',
              fontSize: 16,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // ----- Useful Resources -----
          Text(
            "Useful Resources:",
            style: const TextStyle(
              fontFamily: 'AvenirNext',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bulletLink(
                "Check if your car can handle floods (MMDA Flood Gauge)",
                "https://www.autodeal.com.ph/articles/car-features/can-your-car-handle-flood-check-mmdas-flood-gauge-first",
              ),
              _bulletLink(
                "MMDA Flood Guide for motorists",
                "https://philkotse.com/market-news/mmda-flood-guide-11003",
              ),
              _bulletLink(
                "MMDA Flood Gauge System explained",
                "https://interaksyon.philstar.com/trends-spotlights/2024/09/04/282826/mmda-flood-gauge-system-travelers-motorists/",
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----- PARSE **bold** -----
  Widget _parseBoldText(String text) {
    List<TextSpan> spans = [];
    RegExp exp = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;

    for (final match in exp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: const TextStyle(
            fontFamily: 'AvenirNext',
            fontSize: 16,
            height: 1.6,
            color: Colors.black87,
          ),
        ));
      }

      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(
          fontFamily: 'AvenirNext',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          height: 1.6,
          color: Colors.black87,
        ),
      ));

      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: const TextStyle(
          fontFamily: 'AvenirNext',
          fontSize: 16,
          height: 1.6,
          color: Colors.black87,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  // ----- BULLET LINK WIDGET -----
  Widget _bulletLink(String text, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () async {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url));
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "• ",
              style: TextStyle(
                fontFamily: 'AvenirNext',
                fontSize: 16,
                height: 1.6,
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'AvenirNext',
                  fontSize: 16,
                  height: 1.6,
                  color: Colors.blueAccent,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
