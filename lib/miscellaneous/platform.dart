import 'dart:io';

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
}
