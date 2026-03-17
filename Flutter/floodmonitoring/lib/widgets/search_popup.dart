import 'dart:convert';
import 'package:floodmonitoring/services/global.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:floodmonitoring/utils/style.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlaceSearchPopup extends StatefulWidget {
  const PlaceSearchPopup({super.key});

  @override
  State<PlaceSearchPopup> createState() => _PlaceSearchPopupState();
}

class _PlaceSearchPopupState extends State<PlaceSearchPopup> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _results = [];
  bool _loading = false;
  List<Map<String, dynamic>> _recentPlaces = [];

  final List<Map<String, dynamic>> _famousPlaces = [
    {'name': 'Rizal Park, Manila', 'latLng': LatLng(14.5826, 120.9794)},
    {'name': 'SM Mall of Asia, Pasay', 'latLng': LatLng(14.5345, 120.9816)},
    {'name': 'Intramuros, Manila', 'latLng': LatLng(14.5897, 120.9744)},
    {'name': 'Fort Santiago, Manila', 'latLng': LatLng(14.5939, 120.9740)},
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentPlaces();
  }

  // --- PERSISTENCE LOGIC ---

  Future<void> _loadRecentPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    String? encoded = prefs.getString('recent_search_history');
    if (encoded != null) {
      List<dynamic> decoded = jsonDecode(encoded);
      setState(() {
        _recentPlaces = decoded.map((item) => {
          'name': item['name'],
          'latLng': LatLng(item['lat'], item['lng']),
        }).toList();
      });
    }
  }

  Future<void> _saveToRecent(String name, LatLng latLng) async {
    final prefs = await SharedPreferences.getInstance();

    // Remove if already exists (to move it to top)
    _recentPlaces.removeWhere((element) => element['name'] == name);

    // Insert at start
    _recentPlaces.insert(0, {'name': name, 'latLng': latLng});

    // Limit to 4
    if (_recentPlaces.length > 4) _recentPlaces.removeLast();

    List<Map<String, dynamic>> toSave = _recentPlaces.map((e) => {
      'name': e['name'],
      'lat': (e['latLng'] as LatLng).latitude,
      'lng': (e['latLng'] as LatLng).longitude,
    }).toList();

    await prefs.setString('recent_search_history', jsonEncode(toSave));
  }

  // --- SEARCH LOGIC ---

  Future<void> _searchPlace(String input) async {
    if (input.isEmpty) {
      setState(() => _results.clear());
      return;
    }
    setState(() => _loading = true);
    final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&components=country:PH&key=$googleMapAPIKey';
    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);
    setState(() {
      _results = data['predictions'] ?? [];
      _loading = false;
    });
  }

  Future<void> _selectPlace(String placeId, String name) async {
    final url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$googleMapAPIKey';
    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);
    final loc = data['result']['geometry']['location'];
    final LatLng selectedLatLng = LatLng(loc['lat'], loc['lng']);

    // Only save to recent if it's from a search result
    await _saveToRecent(name, selectedLatLng);

    if (!mounted) return;
    Navigator.pop(context, {'name': name, 'latLng': selectedLatLng});
  }

  PreferredSizeWidget _modernAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(color: colorPrimaryMid, height: 2),
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
                  decoration: BoxDecoration(color: colorPrimaryMid.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.arrow_back_ios_new, color: colorPrimaryMid),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  (searchStartLocation) ? "Select starting point" : (searchEndLocation) ? "Select destination" : "Select location",
                  style: const TextStyle(fontFamily: 'AvenirNext', fontSize: 18, fontWeight: FontWeight.w600, color: colorPrimaryMid),
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
    bool showCurrentLocation = _controller.text.isEmpty && searchStartLocation;
    int currentLocCount = showCurrentLocation ? 1 : 0;
    int recentCount = _controller.text.isEmpty ? _recentPlaces.length : 0;
    int famousCount = _controller.text.isEmpty ? _famousPlaces.length : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _modernAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: TextField(
              controller: _controller,
              onChanged: _searchPlace,
              style: const TextStyle(fontFamily: 'AvenirNext', fontSize: 15),
              decoration: InputDecoration(
                hintText: "Search places in the Philippines",
                hintStyle: TextStyle(fontFamily: 'AvenirNext', color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search, color: colorPrimaryMid),
                filled: true,
                fillColor: colorBackground,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: colorPrimaryMid))
                : ListView.separated(
              itemCount: _controller.text.isEmpty
                  ? (currentLocCount + recentCount + famousCount)
                  : _results.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                if (_controller.text.isEmpty) {
                  // 1. Current Location Section
                  if (showCurrentLocation && index == 0) {
                    return ListTile(
                      leading: const Icon(Icons.my_location, color: colorPrimaryMid),
                      title: const Text("Current Location", style: TextStyle(fontFamily: 'AvenirNext', fontWeight: FontWeight.w600)),
                      subtitle: const Text("Use your device's GPS", style: TextStyle(fontFamily: 'AvenirNext', fontSize: 12)),
                      onTap: () => Navigator.pop(context, {'name': 'Current Location', 'latLng': null}),
                    );
                  }

                  // 2. Recent Places Section
                  int recentStartIndex = currentLocCount;
                  if (index >= recentStartIndex && index < recentStartIndex + recentCount) {
                    final place = _recentPlaces[index - recentStartIndex];
                    return ListTile(
                      leading: const Icon(Icons.history_rounded, color: Colors.grey),
                      title: Text(place['name'], style: const TextStyle(fontFamily: 'AvenirNext', fontWeight: FontWeight.w500)),
                      subtitle: const Text("Recent search", style: TextStyle(fontFamily: 'AvenirNext', fontSize: 12)),
                      onTap: () => Navigator.pop(context, {'name': place['name'], 'latLng': place['latLng']}),
                    );
                  }

                  // 3. Famous Places Section
                  int famousStartIndex = currentLocCount + recentCount;
                  final place = _famousPlaces[index - famousStartIndex];
                  return ListTile(
                    leading: const Icon(Icons.star_rounded, color: colorWarning),
                    title: Text(place['name'], style: const TextStyle(fontFamily: 'AvenirNext', fontWeight: FontWeight.w600)),
                    subtitle: const Text("Popular destination", style: TextStyle(fontFamily: 'AvenirNext', fontSize: 12)),
                    onTap: () => Navigator.pop(context, {'name': place['name'], 'latLng': place['latLng']}),
                  );
                } else {
                  // 4. Search Results Section
                  final place = _results[index];
                  return ListTile(
                    leading: const Icon(Icons.place_rounded, color: colorPrimaryMid),
                    title: Text(place['description'], style: const TextStyle(fontFamily: 'AvenirNext', fontWeight: FontWeight.w500)),
                    subtitle: const Text("Tap to select location", style: TextStyle(fontFamily: 'AvenirNext', fontSize: 12)),
                    onTap: () => _selectPlace(place['place_id'], place['description']),
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