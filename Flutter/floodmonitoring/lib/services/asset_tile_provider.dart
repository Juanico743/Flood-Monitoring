import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AssetTileProvider implements TileProvider {
  final String pathTemplate;
  final int minZoom; // lowest zoom you exported
  final int maxZoom; // highest zoom you exported

  AssetTileProvider({
    required this.pathTemplate,
    this.minZoom = 13,
    this.maxZoom = 18,
  });

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    int z = zoom ?? minZoom;

    // Clamp zoom within available range
    if (z < minZoom) z = minZoom;
    if (z > maxZoom) z = maxZoom;

    // Try to load the requested tile
    final path = pathTemplate
        .replaceAll('{z}', z.toString())
        .replaceAll('{x}', x.toString())
        .replaceAll('{y}', y.toString());

    try {
      final ByteData data = await rootBundle.load(path);
      return Tile(256, 256, data.buffer.asUint8List());
    } catch (_) {
      // Tile not found → fallback to nearest lower zoom
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

      // If all else fails → return empty tile
      print('Tile missing at z=$z x=$x y=$y → returning empty tile');
      return Tile(256, 256, Uint8List(0));
    }
  }
}
