class Surah {
  final int id;
  final String name;
  final int startPage;
  final int endPage;
  final int makkia;
  final int type;

  Surah({
    required this.id,
    required this.name,
    required this.startPage,
    required this.endPage,
    required this.makkia,
    required this.type,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      id: json['id'],
      name: json['name'],
      startPage: json['start_page'],
      endPage: json['end_page'],
      makkia: json['makkia'],
      type: json['type'],
    );
  }

  bool get isMakki => makkia == 1;
}
