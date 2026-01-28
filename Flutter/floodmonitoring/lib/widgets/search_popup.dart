import 'dart:convert';
import 'package:floodmonitoring/services/global.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlaceSearchPopup extends StatefulWidget {
  const PlaceSearchPopup({super.key});

  @override
  State<PlaceSearchPopup> createState() => _PlaceSearchPopupState();
}

class _PlaceSearchPopupState extends State<PlaceSearchPopup> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _results = [];
  bool _loading = false;

  final List<Map<String, dynamic>> _famousPlaces = [
    {'name': 'Rizal Park, Manila', 'latLng': LatLng(14.5826, 120.9794)},
    {'name': 'SM Mall of Asia, Pasay', 'latLng': LatLng(14.5345, 120.9816)},
    {'name': 'Intramuros, Manila', 'latLng': LatLng(14.5897, 120.9744)},
    {'name': 'Fort Santiago, Manila', 'latLng': LatLng(14.5939, 120.9740)},
  ];

  /// 🔍 Google Places Autocomplete (Philippines only)
  Future<void> _searchPlace(String input) async {
    if (input.isEmpty) {
      setState(() => _results.clear());
      return;
    }

    setState(() => _loading = true);

    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=$input'
        '&components=country:PH'
        '&key=$googleMapAPI';

    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);

    setState(() {
      _results = data['predictions'] ?? [];
      _loading = false;
    });
  }

  /// 📍 Get place LatLng
  Future<void> _selectPlace(String placeId, String name) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=geometry'
        '&key=$googleMapAPI';

    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);

    final loc = data['result']['geometry']['location'];

    Navigator.pop(
      context,
      {
        'name': name,
        'latLng': LatLng(loc['lat'], loc['lng']),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Select Location",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              onChanged: _searchPlace,
              decoration: InputDecoration(
                hintText: "Search places in Philippines",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Results
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
              itemCount: _controller.text.isEmpty
                  ? _famousPlaces.length
                  : _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (_controller.text.isEmpty) {
                  final place = _famousPlaces[index];
                  return ListTile(
                    leading: const Icon(Icons.star, color: Colors.orange),
                    title: Text(place['name']),
                    subtitle: const Text("Popular place"),
                    onTap: () {
                      Navigator.pop(context, {
                        'name': place['name'],
                        'latLng': place['latLng'],
                      });
                    },
                  );
                } else {
                  final place = _results[index];
                  return ListTile(
                    leading: const Icon(Icons.place, color: Colors.blue),
                    title: Text(place['description']),
                    subtitle: const Text("Tap to select"),
                    onTap: () => _selectPlace(
                      place['place_id'],
                      place['description'],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
