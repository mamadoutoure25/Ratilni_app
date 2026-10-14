import 'package:flutter/services.dart';

class CoverHelper {
  static final Map<int, String> _coverPaths = {};
  
  static Future<void> loadCovers() async {
    try {
      final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final List<String> assets = manifest.listAssets();
      
      final coverPaths = assets
          .where((String key) => key.startsWith('assets/images/cover_sourate/'))
          .toList();
          
      for (String path in coverPaths) {
        final filename = path.split('/').last;
        final match = RegExp(r'^(\d+)_').firstMatch(filename);
        if (match != null) {
          final id = int.parse(match.group(1)!);
          _coverPaths[id] = path;
        }
      }
    } catch (e) {
      print("Erreur lors du chargement des covers: $e");
    }
  }

  static String? getCoverForSurah(int surahId) {
    return _coverPaths[surahId];
  }
}
