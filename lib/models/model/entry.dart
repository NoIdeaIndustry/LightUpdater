class Entry {
  final String name;
  final int size;
  final String hash;

  Entry({
    required this.name,
    required this.size,
    required this.hash,
  });

  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      name: json['name'],
      size: json['size'],
      hash: json['hash'],
    );
  }
}
