import 'package:floodmonitoring/pages/dashboard.dart';
import 'package:floodmonitoring/pages/flood_tips.dart';
import 'package:floodmonitoring/pages/info.dart';
import 'package:floodmonitoring/pages/map.dart';
import 'package:floodmonitoring/pages/recent_alert.dart';
import 'package:floodmonitoring/pages/rescue_call.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  runApp(MaterialApp(
    initialRoute: '/map',
    routes: {
      '/' : (context) => Dashboard(),
      '/map' : (context) => MapScreen(),
      '/info' : (context) => Info(),
      '/recent-alert' : (context) => RecentAlert(),
      '/flood-tips' : (context) => FloodTips(),
      '/rescue-call' : (context) => RescueCall(),



    },
  ));
}
