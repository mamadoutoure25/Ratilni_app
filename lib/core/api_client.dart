import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/surah_model.dart';
import '../models/reciter_model.dart';
import '../models/language_model.dart';
import '../models/rewaya_model.dart';
import '../models/hadith_model.dart';

class ApiClient {
  static const String baseUrl = 'https://mp3quran.net/api/v3';

  Future<List<Language>> getLanguages() async {
    final response = await http.get(Uri.parse('$baseUrl/languages'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List languages = data['language'];
      return languages.map((e) => Language.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load languages');
    }
  }

  Future<List<Surah>> getSurahs(String language) async {
    final response = await http.get(Uri.parse('$baseUrl/suwar?language=$language'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List suwar = data['suwar'];
      return suwar.map((e) => Surah.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load surahs');
    }
  }

  Future<List<Rewaya>> getRiwayat(String language) async {
    final response = await http.get(Uri.parse('$baseUrl/riwayat?language=$language'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List riwayat = data['riwayat'];
      return riwayat.map((e) => Rewaya.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load riwayat');
    }
  }

  Future<List<Reciter>> getReciters(String language, {int? sura, int? rewaya}) async {
    String url = '$baseUrl/reciters?language=$language';
    if (sura != null) url += '&sura=$sura';
    if (rewaya != null) url += '&rewaya=$rewaya';
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List reciters = data['reciters'];
      return reciters.map((e) => Reciter.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load reciters');
    }
  }

  Future<List<Map<String, String>>> getSurahLyrics(int surahId) async {
    // Al Quran Cloud API pour récupérer arabe, phonétique et français
    final responses = await Future.wait([
      http.get(Uri.parse('https://api.alquran.cloud/v1/surah/$surahId/quran-uthmani')),
      http.get(Uri.parse('https://api.alquran.cloud/v1/surah/$surahId/en.transliteration')),
      http.get(Uri.parse('https://api.alquran.cloud/v1/surah/$surahId/fr.hamidullah')),
    ]);

    if (responses[0].statusCode == 200 && responses[1].statusCode == 200 && responses[2].statusCode == 200) {
      final arabicData = json.decode(responses[0].body)['data']['ayahs'] as List;
      final phoneticData = json.decode(responses[1].body)['data']['ayahs'] as List;
      final frenchData = json.decode(responses[2].body)['data']['ayahs'] as List;

      List<Map<String, String>> verses = [];
      for (int i = 0; i < arabicData.length; i++) {
        verses.add({
          'ar': arabicData[i]['text'],
          'ph': phoneticData[i]['text'],
          'fr': frenchData[i]['text'],
        });
      }
      return verses;
    } else {
      throw Exception('Erreur lors de la récupération des paroles');
    }
  }

  List<dynamic>? _timingReadsCache;

  Future<List<Map<String, dynamic>>?> getAyatTiming(String serverUrl, int surahId) async {
    try {
      if (_timingReadsCache == null) {
        final response = await http.get(Uri.parse('https://mp3quran.net/api/v3/ayat_timing/reads'));
        if (response.statusCode == 200) {
          _timingReadsCache = json.decode(response.body) as List<dynamic>;
        } else {
          return null;
        }
      }

      final normalizedServer = serverUrl.replaceAll(RegExp(r'/$'), '');
      
      var read = _timingReadsCache!.cast<Map<String, dynamic>>().firstWhere(
        (r) => (r['folder_url'] as String).replaceAll(RegExp(r'/$'), '') == normalizedServer,
        orElse: () => <String, dynamic>{}, // Return empty map if not found
      );

      if (read.isEmpty) return null; // Pas de timing pour ce récitateur

      final readId = read['id'];
      final timingResponse = await http.get(Uri.parse('https://mp3quran.net/api/v3/ayat_timing?read=$readId&surah=$surahId'));
      
      if (timingResponse.statusCode == 200) {
        final timingsData = json.decode(timingResponse.body) as List<dynamic>;
        return timingsData.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

// Méthode pour rechercher des Hadiths par mot-clé
// Méthode pour rechercher des Hadiths par mot-clé AVEC détails
  Future<List<Hadith>> searchHadiths(String phrase, {String languageCode = 'fr'}) async {
    // 1. On lance la recherche classique
    final searchUrl = Uri.parse(
        'https://hadeethenc.com/api/v1/hadeeths/search/?phrase=$phrase&language=$languageCode');

    final searchResponse = await http.get(searchUrl);

    if (searchResponse.statusCode == 200) {
      final List searchData = jsonDecode(searchResponse.body);

      // Si la recherche ne donne rien, on retourne une liste vide
      if (searchData.isEmpty) return [];

      // 2. On extrait les IDs des résultats (on limite aux 20 premiers pour ne pas bloquer l'API)
      final List<String> ids = searchData.take(20).map((e) => e['id'].toString()).toList();

      // 3. On utilise notre autre méthode pour récupérer les détails de ces IDs précis
      return await getDetailedHadiths(ids, languageCode: languageCode);
    } else {
      throw Exception('Impossible de charger les résultats de recherche');
    }
  }

  Future<List<Hadith>> getDetailedHadiths(List<String> ids, {String languageCode = 'fr'}) async {
    // Transforme la liste d'IDs en chaîne séparée par des virgules (ex: "2962,4560")
    final idsParam = ids.join(',');
    final url = Uri.parse(
        'https://hadeethenc.com/api/v1/hadeeths/multiple/?language=$languageCode&ids=$idsParam');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Hadith.fromJson(e)).toList();
    } else {
      throw Exception('Impossible de charger les détails des Hadiths');
    }
  }
}
