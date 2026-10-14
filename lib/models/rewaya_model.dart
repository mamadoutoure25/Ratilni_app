class Rewaya {
  final int id;
  final String name;

  Rewaya({
    required this.id,
    required this.name,
  });

  factory Rewaya.fromJson(Map<String, dynamic> json) {
    return Rewaya(
      id: json['id'],
      name: json['name'],
    );
  }
}
