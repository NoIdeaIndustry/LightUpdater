import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

import 'package:light_updater/models/model/entry.dart';

class Installer {
  // unpack any archive file with os specific commands
  static Future<void> unpackArchive(final File file, final String path) async {
    if (Platform.isMacOS) {
      await Process.run('unzip', ['-q', file.path, '-d', path]);
    } else if (Platform.isLinux) {
      await Process.run('tar', ['-xzf', file.path, '-C', path]);
    } else {
      final bytes = File(file.path).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        final filename = '$path/${file.name}';

        if (file.isFile) {
          final data = file.content as List<int>;
          final archive = File(filename);
          await archive.create(recursive: true);
          await archive.writeAsBytes(data);
        } else {
          await Directory(filename).create(recursive: true);
        }
      }
    }
  }

  // returns true if the 'file' hash is corresponding
  static Future<bool> _checkHashMatching(File file, String expected) async {
    final bytes = file.readAsBytesSync();
    final hash = sha256.convert(bytes).toString();
    return hash != expected;
  }

  static Future<bool> checkFilesIntegrity(
      final Entry entry, final String path) async {
    return await needDownload(File('$path/${entry.file}'), entry.hash);
  }

  // return a json object containing all the data to download as a list of Entry
  static Future<List<Entry>> getFilesFromNetwork(final String url) async {
    final response = await http.get(Uri.parse(url));
    final decodedJson = jsonDecode(response.body);

    final List<Entry> entries = [];
    for (final decoded in decodedJson) {
      entries.add(Entry.fromJson(decoded));
    }

    return entries;
  }

  // check wether the file needs to be downloaded or not
  static Future<bool> needDownload(final File file, final String hash) async {
    if (file.existsSync()) {
      return _checkHashMatching(file, hash);
    }
    return true;
  }

  // writes content inside file
  static Future<File> downloadFile(String url, String localPath) async {
    final uri = Uri.parse(url);
    final request = await HttpClient().getUrl(uri);
    final response = await request.close();
    final file = File(localPath);

    final directoryPath = file.parent.path;
    final directory = Directory(directoryPath);
    directory.createSync(recursive: true);

    file.writeAsBytesSync(await response.expand((data) => data).toList());
    return file;
  }
}
