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
    final support = await getApplicationSupportDirectory();
    final roamingDirectory = support.parent.parent;

    final directory = Directory(
        '${roamingDirectory.path}${Platform.pathSeparator}${Config.appFolderName}');
    directory.createSync(recursive: true);
    return directory;
  }

  // check wether the file needs to be downloaded or not
  static Future<bool> needDownload(final File file, final String hash) async {
    if (file.existsSync()) {
      final isHashMatching = await _checkHash(file, hash);
      return !isHashMatching;
    }

    return false;
  }

  // return a json object containing all the data to download as a list of Entry
  static Future<List<Entry>> getFilesFromNetwork(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List<dynamic>;
        return jsonList.map((json) => Entry.fromJson(json)).toList();
      }
    } catch (e) {
      print(e.toString());
    }
    return [];
  }

  // writes content inside file
  static Future<void> downloadFile(File file, String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      await file.writeAsBytes(response.bodyBytes);
    } catch (exception) {
      print('An error occurred while downloading the file.');
      rethrow;
    }
  }

  // returns true if the 'file' hash is corresponding
  static Future<bool> _checkHash(File file, final String expectedHash) async {
    try {
      final content = await file.readAsBytes();
      final hash = sha256.convert(content).toString();
      return hash == expectedHash;
    } catch (exception) {
      print('An error occurred while reading the file.');
      rethrow;
    }
  }
}
