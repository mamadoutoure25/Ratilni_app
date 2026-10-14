class Hadith {
  final String id;
  final String title;
  final String text;
  final String attribution;
  final String grade;
  final String explanation;
  final List<String> hints;

  Hadith({
    required this.id,
    required this.title,
    required this.text,
    this.attribution = '',
    this.grade = '',
    this.explanation = '',
    this.hints = const [],
  });

  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      text: json['hadeeth'] ?? json['hadith_text'] ?? '',
      attribution: json['attribution'] ?? '',
      grade: json['grade'] ?? '',
      explanation: json['explanation'] ?? '',
      // Sécurisation de la liste des bénéfices (hints)
      hints: json['hints'] != null ? List<String>.from(json['hints']) : [],
    );
  }
}