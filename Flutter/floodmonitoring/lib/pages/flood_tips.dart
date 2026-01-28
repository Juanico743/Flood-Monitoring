import 'package:floodmonitoring/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';

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
Bicycles are extremely vulnerable in flooded areas. Even shallow water can cause loss of balance or slipping.  

• Avoid riding through water whenever possible.  
• Walk your bike through water if necessary.  
• Watch out for potholes, debris, and slippery surfaces.  
• Wear waterproof and reflective gear for visibility.  
• If unsure of water depth, wait for it to subside or take an alternate route.  
""",
    'Motorcycle': """
Motorcycles are extremely vulnerable in flooded areas. Avoid riding through water whenever possible. Even shallow water can cause loss of balance or stall the engine.  

• Always keep your engine revs high to prevent water from entering the exhaust.  
• Avoid sudden acceleration or braking to prevent skidding.  
• Look out for debris or potholes hidden under water.  
• Wear waterproof and reflective gear to stay visible.  
• If water depth is uncertain, wait for it to subside or take alternate routes.  
""",
    'Car': """
Cars can handle shallow water but still require caution. Driving through deeper water can lead to engine damage or loss of control.  

• Do not drive through water deeper than 15–20 cm.  
• Drive slowly and steadily; avoid sudden movements.  
• Keep an emergency kit including flashlight, food, and first-aid in your car.  
• Avoid flooded underpasses and low-lying areas.  
• After crossing water, check brakes immediately to ensure they are functioning properly.  
""",
    'Truck': """
Trucks have higher clearance but are not immune to flood risks. Strong currents can easily sweep even large trucks off the road.  

• Avoid crossing fast-flowing water or flooded bridges.  
• Drive in low gear and at low speed to prevent water from entering the engine.  
• Ensure cargo is secured to avoid shifting loads.  
• Take alternate elevated routes and avoid congested flooded areas.  
• Check tire grip and brakes after passing through water.  
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
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tip,
            style: const TextStyle(
              fontFamily: 'AvenirNext',
              fontSize: 16,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
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
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
