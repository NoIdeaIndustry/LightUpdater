import 'dart:convert';
import 'dart:io';

import 'package:light_updater/utils/utils.dart';

enum Supported { windows, linux, macos, unknown }

extension SupportedExtension on Supported {
  String get name {
    switch (this) {
      case Supported.windows:
        return 'windows';
      case Supported.linux:
        return 'linux';
      case Supported.macos:
        return 'macos';
      default:
        throw Exception('Unsupported platform');
    }
  }
}

class Platforms {
  static final List<Supported> _available = [
    Supported.windows,
    Supported.macos,
    Supported.linux,
  ];

  static final _cache = <String, bool>{};
  static final _regexes = _available.map((p) => RegExp(p.name)).toList();

  static bool isSupported(final String path) {
    return _cache.putIfAbsent(path, () {
      for (final regex in _regexes) {
        if (regex.hasMatch(path)) return true;
      }

      return false;
    });
  }

  static Supported getCurrent() {
    if (Platform.isWindows) {
      return Supported.windows;
    } else if (Platform.isLinux) {
      return Supported.linux;
    } else if (Platform.isMacOS) {
      return Supported.macos;
    } else {
      return Supported.unknown;
    }
  }

  static Future<String> getArchitecture() async {
    if (Platform.isMacOS) {
      return 'macosx_x64';
    } else {
      ProcessResult result;
      if (Platform.isWindows) {
        result = await Process.run('wmic', ['cpu', 'get', 'Architecture']);
      } else {
        result = await Process.run('uname', ['-m']);
      }
      var output = result.stdout as String;
      var lines = LineSplitter.split(output).toList();
      if (Platform.isLinux) {
        final architecture = lines[0];
        switch (architecture) {
          case 'x86_64':
            return 'linux_x64';
          case ('x86_x32'):
            return 'linux_i686';
          default:
            return 'unknown';
        }
      }
      if (lines.length >= 3) {
        var architecture = lines[2].trim();
        switch (architecture) {
          case '0':
            return 'win_x86';
          case '5':
            return 'win_aarch64';
          case '9':
            return 'win_x64';
          default:
            return 'unknown';
        }
      }
      return 'unknown';
    }
  }

  static Directory getInstallDirectory() {
    switch (Platform.operatingSystem) {
      case 'windows':
        return Directory(
            '${Platform.environment['APPDATA']}\\${Config.appFolderName}');
      case 'macos':
        return Directory(
            '${Platform.environment['HOME']}/Library/Application Support/${Config.appFolderName}');
      case 'linux':
        return Directory(
            '${Platform.environment['HOME']}/.local/share/${Config.appFolderName}');
      default:
        return Directory(
            '${Platform.environment['HOME']}/${Config.appFolderName}');
    }
  }
}
