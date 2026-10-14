import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const String baseUrl = 'https://mp3quran.net/api/v3';
  final response = await http.get(Uri.parse('$baseUrl/suwar?language=fr'));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final List suwar = data['suwar'];
    print('Found ${suwar.length} surahs');
    if (suwar.isNotEmpty) {
      print('First surah: ${suwar.first['id']} - ${suwar.first['name']}');
    }
  } else {
    print('Failed with ${response.statusCode}');
  }
}
