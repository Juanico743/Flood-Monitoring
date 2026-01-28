import 'dart:async';

import 'package:floodmonitoring/services/global.dart';
import 'package:floodmonitoring/services/location.dart';
import 'package:floodmonitoring/services/weather.dart';
import 'package:floodmonitoring/utils/style.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';


class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {

  String temperature = '';
  String description = '';
  String iconCode = '';

  String currentTime = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _loadCurrentLocation();

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  Future<void> _loadCurrentLocation() async {
    Position? position = await LocationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        currentPosition = position;
      });
      getWeather();
    } else {
      print('Could not get location.');
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    final formattedTime = DateFormat('hh:mm a').format(now);

    setState(() {
      currentTime = formattedTime;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }


  void getWeather() async {
    final weather = await loadWeather(currentPosition!.latitude, currentPosition!.longitude);

    if (weather != null) {
      setState(() {
        temperature = weather['temperature'].toString();
        description = weather['description'];
        iconCode = weather['iconCode'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFCDE6FF),
              Color(0xFFFFFFFF),
              Color(0xFFCDE6FF),
            ],
          ),
        ),
        child: Column(
          children: [

            SizedBox(height: 40),

            ///Header
            Container(
              margin: EdgeInsets.symmetric(horizontal: 15),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Let’s get moving!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  Text(
                    'Stay alert, stay safe',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),


            ///Main

            Container(
              margin: EdgeInsets.symmetric(horizontal: 15),
              padding: EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color1_3,
                    color1,
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    //padding: EdgeInsets.all(15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Flood update\nto your zone',
                          style: const TextStyle(
                            fontSize: 24,
                          ),
                        ),
                        SizedBox(height: 10),

                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/map');
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: color2,
                            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text(
                            'Open Map',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ), // This is a Button
                      ],
                    ),
                  ),

                  Image.asset(
                    'assets/images/Flood-amico.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ],
              ),

            ),


            SizedBox(height: 20),


            /// Related


            Container(
              margin: EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Related',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600
                    ),
                  ),

                ],
              )
            ),

            SizedBox(height: 15),

            ///Weather Card
            Container(
              padding: EdgeInsets.all(15),
              margin: EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.white70,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 0),
                  ),
                ],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Weather Icon
                  Column(
                    children: [
                      if (iconCode.isNotEmpty)
                        Image.asset(
                          'assets/images/weather/$iconCode.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        )
                      else
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),

                  // Weather Info
                  Column(
                    children: [
                      Text(
                        currentTime.isNotEmpty ? currentTime : '--:--',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      Text(
                        // ignore: unnecessary_null_comparison
                        temperature != null ? '${temperature}°C' : '--°C',
                        style: TextStyle(
                          color: color1,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      Text(
                        description.isNotEmpty ? description : 'Loading...',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 15),


            ///Sliding Cards

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    miniCard(
                      color: color2,
                      title: 'Recent\nAlert',
                      textColor: Colors.white,
                      image: 'assets/images/warning.png',
                      opacity: 0.1,
                      onTap: () {
                        Navigator.pushNamed(context, '/recent-alert');
                      },
                    ),
                    miniCard(
                      color: color1,
                      title: 'Flood\ntips',
                      textColor: Colors.black,
                      image: 'assets/images/water-damage.png',
                      opacity: 0.3,
                      onTap: () {
                        Navigator.pushNamed(context, '/flood-tips');
                      },
                    ),
                    miniCard(
                      color: color3,
                      title: 'Rescue\nCall',
                      textColor: Colors.black,
                      image: 'assets/images/siren-on.png',
                      opacity: 0.5,
                      onTap: () {
                        Navigator.pushNamed(context, '/rescue-call');
                      },
                    ),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget miniCard({
    required Color color,
    required String title,
    required Color textColor,

    required String image,
    required double opacity,

    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5),
        width: 120,
        height: 130,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 0),
            ),
          ],
        ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                top: 0,
                bottom: 0,
                child: Opacity(
                  opacity: opacity,
                  child: Image.asset(
                    image,
                    width: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),


              Positioned(
                left: 15,
                bottom: 15  ,
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    height: 1,
                    fontSize: 20,
                    fontWeight: FontWeight.w600
                  ),
                ),
              ),
            ],
          )
      ),
    );
  }
}
