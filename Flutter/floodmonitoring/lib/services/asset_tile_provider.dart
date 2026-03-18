import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Provides map tiles directly from local assets with a fallback system.
class AssetTileProvider implements TileProvider {
  final String pathTemplate;
  final int minZoom;
  final int maxZoom;

  AssetTileProvider({
    required this.pathTemplate,
    this.minZoom = 13,
    this.maxZoom = 18,
  });

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    // Ensure the zoom level stays within the defined asset range
    int z = zoom ?? minZoom;
    if (z < minZoom) z = minZoom;
    if (z > maxZoom) z = maxZoom;

    // Construct the file path by replacing placeholders with coordinates
    final path = pathTemplate
        .replaceAll('{z}', z.toString())
        .replaceAll('{x}', x.toString())
        .replaceAll('{y}', y.toString());

    try {
      // Attempt to load the tile image from the app assets
      final ByteData data = await rootBundle.load(path);
      return Tile(256, 256, data.buffer.asUint8List());
    } catch (_) {
      // If the specific tile is missing, look for a lower-zoom "parent" tile as a fallback
      int fallbackZoom = z - 1;
      while (fallbackZoom >= minZoom) {
        int dz = z - fallbackZoom;
        int parentX = x >> dz;
        int parentY = y >> dz;

        final fallbackPath = pathTemplate
            .replaceAll('{z}', fallbackZoom.toString())
            .replaceAll('{x}', parentX.toString())
            .replaceAll('{y}', parentY.toString());

        try {
          final ByteData data = await rootBundle.load(fallbackPath);
          print(
              'Tile missing at z=$z x=$x y=$y → using fallback z=$fallbackZoom x=$parentX y=$parentY');
          return Tile(256, 256, data.buffer.asUint8List());
        } catch (_) {
          fallbackZoom--;
        }
      }

      // Return an empty tile if no assets or fallbacks are found
      print('Tile missing at z=$z x=$x y=$y → returning empty tile');
      return Tile(256, 256, Uint8List(0));
    }
  }
}