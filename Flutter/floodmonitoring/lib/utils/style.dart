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




///New Color
/// PRIMARY THEME (Modern Blue)
const Color colorPrimary = Color(0xFF2979FF); // similar to Colors.blueAccent
const Color colorPrimaryDark = Color(0xFF0D47A1);
const Color colorPrimaryLight = Color(0xFF82B1FF);

/// BACKGROUNDS
const Color colorBackground = Color(0xFFF5F9FF); // app background
const Color colorCard = Colors.white;
const Color colorSheet = Colors.white;

/// TEXT
const Color colorTextPrimary = Color(0xFF1F2937); // near black
const Color colorTextSecondary = Color(0xFF6B7280); // grey
const Color colorTextOnBlue = Colors.white;

/// ACCENT (for highlights, CTA, buttons)
const Color colorAccent = Color(0xFF40C4FF); // light blue glow

/// GRADIENT (for your top banner & cards)
const Color gradientStart = Color(0xFF448AFF); // BlueAccent.shade400
const Color gradientEnd = Color(0xFF81D4FA);   // LightBlue.shade300

/// STATUS COLORS (keep readable & material-like)
const Color colorSafe = Color(0xFF4CAF50);
const Color colorWarning = Color(0xFFFFB300);
const Color colorDanger = Color(0xFFE53935);

/// ALERT BACKGROUND
const Color colorAlertBg = Color(0xFFFFEBEE);

/// POLYLINE
const Color colorPolylineSafe = Color(0xFF00E5FF);
const Color colorPolylineDanger = Color(0xFFFF5252);



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