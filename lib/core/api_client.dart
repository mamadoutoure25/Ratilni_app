import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/surah_model.dart';
import '../models/reciter_model.dart';
import '../models/language_model.dart';
import '../models/rewaya_model.dart';

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
}
