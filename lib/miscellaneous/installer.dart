import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:light_updater/models/model/entry.dart';
import 'package:light_updater/utils/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

class Installer {
  // get the right installation directory to download the files into
  static Future<Directory> getInstallationDirectory() async {
    late Directory directory;

    if (Platform.isWindows) {
      final support = await getApplicationSupportDirectory();
      final roamingDirectory = support.parent.parent;

      final f = Directory('${roamingDirectory.path}/${Config.appFolderName}');
      f.createSync(recursive: true);
      directory = f;
    } else if (Platform.isMacOS) {
      // broken on macos
    } else {
      /// idk yet it's linux
    }

    return directory;
  }

  // check wether the file needs to be downloaded or not
  static Future<bool> needDownload(final File file, final String hash) async {
    if (file.existsSync()) {
      return _checkHash(file, hash);
    }

    return false;
  }

  // return a json object containing all the data to download as a list of Entry
  static Future<List<Entry>> getFilesFromNetwork(final String url) async {
    final response = await http.get(Uri.parse(url));
    final json = jsonDecode(response.body);

    final List<Entry> entries = List.empty(growable: true);
    for (var element in json) {
      entries.add(Entry.fromJson(element));
    }

    return entries;
  }

  // writes content inside file
  static Future<void> downloadFile(final File file, final String url) async {
    final response = await http.get(Uri.parse(url));
    file.createSync(recursive: true);
    file.writeAsBytesSync(response.bodyBytes);
  }

  // returns true if the 'file' hash is corresponding
  static Future<bool> _checkHash(final File file, final expectedHash) async {
    final content = file.readAsBytesSync();
    final hash = sha256.convert(content).toString();
    return hash == expectedHash;
  }
}
