import 'dart:convert';

import 'package:floodmonitoring/services/global.dart';
import 'package:floodmonitoring/utils/style.dart';
import 'package:flutter/material.dart';
import 'package:floodmonitoring/widgets/custom_app_bar.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class RescueCall extends StatefulWidget {
  const RescueCall({super.key});

  @override
  State<RescueCall> createState() => _RescueCallState();
}

class _RescueCallState extends State<RescueCall> {


  // ----------------------------------------
  // INITIALIZATION (initState)
  // ----------------------------------------

  @override
  void initState() {
    super.initState();
    loadEmergencyContacts();
  }

  // ----------------------------------------
  // STATE / VARIABLES
  // ----------------------------------------

  /// ----- EMERGENCY CONTACTS -----
  List<Map<String, String>> emergencyContacts = [
    {
      "name": "Manila DRRMO (Main)",
      "number": "09507003710",
      "description": "City-wide flood rescue & emergency response"
    },
    {
      "name": "Manila City Hall Action Center",
      "number": "89271335",
      "description": "General emergency & flood reports"
    },
    {
      "name": "Philippine Red Cross (Manila)",
      "number": "143",
      "description": "Direct emergency hotline (Shortcode)"
    },
    {
      "name": "MMDA Flood Control",
      "number": "136",
      "description": "Metro-wide flood monitoring & rescue"
    },
    {
      "name": "BFP Manila (Fire/Rescue)",
      "number": "85273627",
      "description": "Bureau of Fire Protection - Manila District"
    },
    {
      "name": "PNP Santa Mesa (Station 6)",
      "number": "87160601",
      "description": "Local police assistance in Santa Mesa"
    },
    {
      "name": "National Emergency Hotline",
      "number": "911",
      "description": "Centralized emergency hotline"
    },
  ];


  // ----------------------------------------
  // LOGIC / HELPER FUNCTIONS
  // ----------------------------------------

  /// ----- LOAD EMERGENCY CONTACTS -----
  Future<void> loadEmergencyContacts() async {
    try {
      String uri = '$serverUri/api/get-all-contacts/';

      var res = await http.get(
          Uri.parse(uri),
          headers: {"Content-Type": "application/json"}
      );

      var response = jsonDecode(res.body);

      if (res.statusCode == 200 && response.containsKey("emergencyContacts")) {
        setState(() {
          emergencyContacts = List<Map<String, String>>.from(
              response["emergencyContacts"].map((item) => {
                "name": item["name"].toString(),
                "number": item["phone_number"].toString(),
                "description": item["description"].toString(),
              })
          );
        });
        print("Contacts updated: ${emergencyContacts.length} items loaded.");
      }
    } catch (e) {
      print("Error fetching emergency contacts: $e");
    }
  }

  /// ----- MAKE CALL FUNCTION-----
  void _makeCall(String? number) async {
    if (number == null) return;
    final Uri callUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot make a call at the moment.")),
      );
    }
  }


  // ----------------------------------------
  // BUILD / CORE UI
  // ----------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: "Emergency Contacts",
        backgroundColor: colorPrimary,
        onBack: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _header(),
            const SizedBox(height: 20),
            ...emergencyContacts.map((contact) => _contactCard(contact)).toList(),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------
  // UI WIDGETS
  // ----------------------------------------


  /// ----- HEADER -----
  Widget _header() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorPrimary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.local_phone, color: colorPrimary, size: 36),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Stay Safe!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'AvenirNext',
                ),
              ),
              SizedBox(height: 2),
              Text(
                "Quick access to emergency contacts",
                style: TextStyle(
                  color: Colors.black54,
                  fontFamily: 'AvenirNext',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ----- CONTACT CARD -----
  Widget _contactCard(Map<String, String> contact) {
    return Container(
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
            contact['name'] ?? "",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'AvenirNext',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            contact['description'] ?? "",
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
              fontFamily: 'AvenirNext',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                contact['number'] ?? "",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'AvenirNext',
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _makeCall(contact['number']),
                icon: const Icon(Icons.call, size: 18),
                label: const Text("Call"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimary,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
