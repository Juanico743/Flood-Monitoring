import 'package:flutter/material.dart';

Widget buildCardContent(int index) {
  const String baseImgPath = 'assets/images/';
  const String vehicleImgPath = 'assets/images/vehicle/';

  switch (index) {
    case 0:
    /// --- CARD 1: PASSABILITY ---
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCardHeader("PASSABILITY"),
          const SizedBox(height: 14),
          _buildRowItem(
            imagePath: '${baseImgPath}sensor_location_safe.png',
            title: "SAFE",
            subtitle: "Passable to all vehicles.",
          ),
          const SizedBox(height: 10),
          _buildRowItem(
            imagePath: '${baseImgPath}sensor_location_warning.png',
            title: "WARNING",
            subtitle: "Flooding detected.",
          ),
          const SizedBox(height: 10),
          _buildRowItem(
            imagePath: '${baseImgPath}sensor_location_danger.png',
            title: "DANGER",
            subtitle: "High water levels.",
          ),
        ],
      );

    case 1:
    /// --- CARD 2: MAP PINS ---
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCardHeader("MAP PINS"),
          const SizedBox(height: 22),
          _buildRowItem(
            imagePath: '${baseImgPath}user_location.png',
            title: "YOUR LOCATION",
            subtitle: "Current position.",
          ),
          const SizedBox(height: 18),
          _buildRowItem(
            imagePath: '${baseImgPath}selected_location.png',
            title: "ROUTE MARKER",
            subtitle: "Starting point or destination.",
          ),
        ],
      );

    case 2:
    /// --- CARD 3: TRAVEL MODE ---
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCardHeader("TRAVEL MODE"),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              "Choose how you want to travel - whether walking, cycling, motorcycle, car, or truck.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'AvenirNext',
                fontSize: 11,
                color: Colors.grey.shade600,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 12),

          /// First Row: 3 Modes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildVehicleItem('${vehicleImgPath}walk.png'),
              const SizedBox(width: 14),
              _buildVehicleItem('${vehicleImgPath}bicycle.png'),
              const SizedBox(width: 14),
              _buildVehicleItem('${vehicleImgPath}motorcycle.png'),
            ],
          ),
          const SizedBox(height: 10),

          /// Second Row: 2 Modes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildVehicleItem('${vehicleImgPath}car.png'),
              const SizedBox(width: 16),
              _buildVehicleItem('${vehicleImgPath}truck.png'),
            ],
          ),
        ],
      );

    default:
      return const SizedBox.shrink();
  }
}

/// Styled header layout helper
Widget _buildCardHeader(String text) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        text,
        style: const TextStyle(
          fontFamily: 'AvenirNext',
          fontWeight: FontWeight.w900,
          fontSize: 13,
          letterSpacing: 1.0,
          color: Color(0xff2c3e50),
        ),
      ),
      const SizedBox(height: 4),
      Container(
        width: 24,
        height: 2.5,
        decoration: BoxDecoration(
          color: const Color(0xff3fa9f5).withOpacity(0.6),
          borderRadius: BorderRadius.circular(2),
        ),
      )
    ],
  );
}

/// Helper for list element rows
Widget _buildRowItem({required String imagePath, required String title, required String subtitle}) {
  return Row(
    children: [
      const SizedBox(width: 4),
      Image.asset(
        imagePath,
        width: 34,
        height: 34,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
          child: const Icon(Icons.location_on, size: 16, color: Colors.black26),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'AvenirNext',
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                letterSpacing: 0.2,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'AvenirNext',
                fontWeight: FontWeight.w500,
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Custom vehicle item boxes contrasting nicely on top of the white background
Widget _buildVehicleItem(String imagePath) {
  return Container(
    width: 52,
    height: 38,
    decoration: BoxDecoration(
      color: const Color(0xfff2f9fe), // Soft background tint to ground vehicle images
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: const Color(0xff3fa9f5).withOpacity(0.15),
        width: 1,
      ),
    ),
    padding: const EdgeInsets.all(5.0),
    child: Image.asset(
      imagePath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.directions_car,
        size: 16,
        color: Colors.black26,
      ),
    ),
  );
}