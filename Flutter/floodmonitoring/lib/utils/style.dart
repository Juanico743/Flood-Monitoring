import 'package:flutter/material.dart';

///MAin Color
const Color color1 = Color(0xFF046EEC);
const Color color2 = Color(0xFF2A2A32);
const Color color3 = Color(0xFFCED1D6);
const Color color4 = Color(0xFF00D4C6);


///Sub Color
const Color color1_2 = Color(0xFF0011B9);
const Color color1_3 = Color(0xFF95C4FF);
const Color color1_4 = Color(0xFFDDECFF);
const Color color3_2 = Color(0xFFE4E8EE);

///Polyline Color
const Color color_polyline1 = Color(0xFF00d4C6);
const Color color_polyline2 = Color(0xffff7070);

///Alert Color
const Color color_alert = Color(0xFFFAD8D8);

///Status Color
const Color color_safe = Color(0xFF4CAF50);
const Color color_warning = Color(0xFFFFC107);
const Color color_danger = Color(0xFFF44336);



/// =======================
/// PRIMARY BUTTON
/// =======================
Widget primaryButton({
  required String text,
  required VoidCallback onTap,
}) {
  return SizedBox(
    height: 48,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: onTap,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  );
}

/// =======================
/// SECONDARY BUTTON
/// =======================
Widget secondaryButton({
  required String text,
  required VoidCallback onTap,
}) {
  return SizedBox(
    height: 48,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: color1, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: onTap,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color1,
        ),
      ),
    ),
  );
}