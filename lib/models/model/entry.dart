class Entry {
  final String file;
  final int size;
  final String hash;

  Entry({
    required this.file,
    required this.size,
    required this.hash,
  });

  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      file: json['file'],
      size: json['size'],
      hash: json['hash'],
    );
  }
}
