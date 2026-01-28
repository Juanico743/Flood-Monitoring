import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UrlTileProvider implements TileProvider {
  final String urlTemplate;

  UrlTileProvider({required this.urlTemplate});

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    final z = zoom ?? 0;

    final url = urlTemplate
        .replaceAll('{x}', x.toString())
        .replaceAll('{y}', y.toString())
        .replaceAll('{z}', z.toString());

    final response = await NetworkAssetBundle(Uri.parse(url)).load(url);
    final bytes = response.buffer.asUint8List();

    return Tile(256, 256, bytes);
  }
}
