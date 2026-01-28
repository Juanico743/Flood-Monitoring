import 'package:intl/intl.dart';

/// Returns current time as a formatted string, e.g., "12:34 PM"
String getCurrentTime() {
  final now = DateTime.now();
  final formatter = DateFormat('hh:mm a'); // 12-hour format with AM/PM
  return formatter.format(now);
}

/// Returns current date as formatted string, e.g., "Nov 9, 2025"
String getCurrentDate() {
  final now = DateTime.now();
  final formatter = DateFormat('MMM d, yyyy');
  return formatter.format(now);
}