class Reciter {
  final int id;
  final String name;
  final String letter;
  final List<Moshaf> moshaf;

  Reciter({
    required this.id,
    required this.name,
    required this.letter,
    required this.moshaf,
  });

  factory Reciter.fromJson(Map<String, dynamic> json) {
    return Reciter(
      id: json['id'],
      name: json['name'],
      letter: json['letter'],
      moshaf: (json['moshaf'] as List).map((m) => Moshaf.fromJson(m)).toList(),
    );
  }
}

class Moshaf {
  final int id;
  final String name;
  final String server;
  final int surahTotal;
  final String surahList;

  Moshaf({
    required this.id,
    required this.name,
    required this.server,
    required this.surahTotal,
    required this.surahList,
  });

  factory Moshaf.fromJson(Map<String, dynamic> json) {
    return Moshaf(
      id: json['id'],
      name: json['name'],
      server: json['server'],
      surahTotal: json['surah_total'],
      surahList: json['surah_list'],
    );
  }
}
