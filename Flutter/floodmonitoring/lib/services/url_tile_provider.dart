import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Custom TileProvider that fetches map tiles from a remote URL.
class UrlTileProvider implements TileProvider {
  final String urlTemplate;

  UrlTileProvider({required this.urlTemplate});

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    // Default to zoom level 0 if no value is provided
    final z = zoom ?? 0;

    // Build the specific tile URL by replacing template placeholders with coordinates
    final url = urlTemplate
        .replaceAll('{x}', x.toString())
        .replaceAll('{y}', y.toString())
        .replaceAll('{z}', z.toString());

    // Fetch the image data from the network and convert it to a byte list
    final response = await NetworkAssetBundle(Uri.parse(url)).load(url);
    final bytes = response.buffer.asUint8List();

    // Return the processed tile as a 256x256 image
    return Tile(256, 256, bytes);
  }
}