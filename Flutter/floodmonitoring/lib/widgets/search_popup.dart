import 'dart:convert';
import 'package:floodmonitoring/services/global.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:floodmonitoring/utils/style.dart';

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

  /// ===============================
  /// MODERN CUSTOM APPBAR
  /// ===============================
  PreferredSizeWidget _modernAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(
          color: color1,
          height: 2,
        ),
      ),
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.arrow_back_ios_new, color: color1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Select Destination",
                  style: const TextStyle(
                    fontFamily: 'AvenirNext',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: color1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 34),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _modernAppBar(),

      body: Column(
        children: [
          // SEARCH FIELD
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: TextField(
              controller: _controller,
              onChanged: _searchPlace,
              style: const TextStyle(
                fontFamily: 'AvenirNext',
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: "Search places in the Philippines",
                hintStyle: TextStyle(
                  fontFamily: 'AvenirNext',
                  color: Colors.grey[500],
                ),
                prefixIcon: const Icon(Icons.search, color: color1),
                filled: true,
                fillColor: color1_4,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // RESULTS
          Expanded(
            child: _loading
                ? const Center(
              child: CircularProgressIndicator(color: color1),
            )
                : ListView.separated(
              itemCount: _controller.text.isEmpty
                  ? _famousPlaces.length
                  : _results.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: Colors.grey.shade200,
              ),
              itemBuilder: (context, index) {
                if (_controller.text.isEmpty) {
                  final place = _famousPlaces[index];
                  return ListTile(
                    leading:
                    const Icon(Icons.star_rounded, color: color_warning),
                    title: Text(
                      place['name'],
                      style: const TextStyle(
                        fontFamily: 'AvenirNext',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      "Popular destination",
                      style: TextStyle(
                        fontFamily: 'AvenirNext',
                        fontSize: 12,
                      ),
                    ),
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
                    leading: const Icon(Icons.place_rounded, color: color1),
                    title: Text(
                      place['description'],
                      style: const TextStyle(
                        fontFamily: 'AvenirNext',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: const Text(
                      "Tap to select location",
                      style: TextStyle(
                        fontFamily: 'AvenirNext',
                        fontSize: 12,
                      ),
                    ),
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
