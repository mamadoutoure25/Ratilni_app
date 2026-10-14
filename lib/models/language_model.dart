class Language {
  final String id;
  final String language;
  final String native;
  final String locale;

  Language({
    required this.id,
    required this.language,
    required this.native,
    required this.locale,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    // Extract locale from the surah url, e.g., "...suwar?language=ar"
    String surahUrl = json['surah'] ?? '';
    String extractedLocale = 'ar';
    if (surahUrl.contains('language=')) {
      extractedLocale = surahUrl.split('language=').last;
    } else {
      // Fallback
      extractedLocale = json['language'].toString().toLowerCase().substring(0, 2);
    }

    return Language(
      id: json['id'].toString(),
      language: json['language'] ?? '',
      native: json['native'] ?? '',
      locale: extractedLocale,
    );
  }
}
