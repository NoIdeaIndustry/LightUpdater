class Entry {
  final String file;
  final int size;
  final String hash;
  final String url;

  Entry({
    required this.file,
    required this.size,
    required this.hash,
    required this.url,
  });

  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      file: json['file'],
      size: json['size'],
      hash: json['hash'],
      url: json['url'],
    );
  }
}
