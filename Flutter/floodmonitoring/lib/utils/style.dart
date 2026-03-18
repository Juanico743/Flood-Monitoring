import 'package:flutter/material.dart';


/// PRIMARY THEME (Modern Blue)
const Color colorPrimary = Color(0xFF2979FF);
const Color colorPrimaryMid = Color(0xFF046EEC);
const Color colorPrimaryDark = Color(0xFF0D47A1);
const Color colorPrimaryLight = Color(0xFF82B1FF);
const Color colorPrimaryDeep = Color(0xFF2A2A32);


/// BACKGROUNDS
const Color colorBackground = Color(0xFFE9F3FF);
const Color colorCard = Colors.white;
const Color colorSheet = Colors.white;


/// TEXT
const Color colorTextPrimary = Color(0xFF1F2937);
const Color colorTextSecondary = Color(0xFF6B7280);
const Color colorTextOnBlue = Colors.white;

/// ACCENT (for highlights, CTA, buttons)
const Color colorAccent = Color(0xFF40C4FF);

/// GRADIENT (for your top banner & cards)
const Color gradientStart = Color(0xFF448AFF);
const Color gradientEnd = Color(0xFF81D4FA);

/// STATUS COLORS (keep readable & material-like)
const Color colorSafe = Color(0xFF4CAF50);
const Color colorWarning = Color(0xFFFFB300);
const Color colorDanger = Color(0xFFE53935);

/// ALERT BACKGROUND
const Color colorAlertBg = Color(0xFFFFEBEE);

/// POLYLINE
const Color colorPolylineMain = Color(0xFF2196F3);
const Color colorPolylineBack = Color(0xFF81D4FA);



/// ----- PRIMARY BUTTON -----
Widget primaryButton({
  required String text,
  required VoidCallback onTap,
}) {
  return SizedBox(
    height: 48,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorPrimaryMid,
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

/// ----- SECONDARY BUTTON -----
Widget secondaryButton({
  required String text,
  required VoidCallback onTap,
}) {
  return SizedBox(
    height: 48,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: colorPrimaryMid, width: 2),
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
          color: colorPrimaryMid,
        ),
      ),
    ),
  );
}