import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyFavorites = 'favorites';
  static const String _keyLastReciterId = 'last_reciter_id';

  Future<List<int>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? favorites = prefs.getStringList(_keyFavorites);
    if (favorites == null) return [];
    return favorites.map((e) => int.parse(e)).toList();
  }

  Future<void> toggleFavorite(int surahId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favorites = prefs.getStringList(_keyFavorites) ?? [];
    
    final idStr = surahId.toString();
    if (favorites.contains(idStr)) {
      favorites.remove(idStr);
    } else {
      favorites.add(idStr);
    }
    await prefs.setStringList(_keyFavorites, favorites);
  }

  Future<int?> getLastReciterId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLastReciterId);
  }

  Future<void> saveLastReciterId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastReciterId, id);
  }

  static const String _keyLanguage = 'language';

  Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage);
  }

  Future<void> saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, languageCode);
  }
}
