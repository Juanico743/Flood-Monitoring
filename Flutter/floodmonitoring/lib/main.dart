import 'package:floodmonitoring/pages/flood_tips.dart';
import 'package:floodmonitoring/pages/info.dart';
import 'package:floodmonitoring/pages/map.dart';
import 'package:floodmonitoring/pages/recent_alert.dart';
import 'package:floodmonitoring/pages/rescue_call.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart'; // Import Phoenix

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  runApp(
    Phoenix( // Wrap your MaterialApp here
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/map',
        routes: {
          '/map': (context) => MapScreen(),
          '/info': (context) => Info(),
          '/recent-alert': (context) => RecentAlert(),
          '/flood-tips': (context) => FloodTips(),
          '/rescue-call': (context) => RescueCall(),
        },
      ),
    ),
  );
}