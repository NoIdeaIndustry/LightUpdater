import 'dart:io';

enum Supported { windows, linux, macos, unknown }

class Platforms {
  static final Set<Supported> _available = {
    Supported.windows,
  };

  static bool isSupported(final String path) {
    final regex = RegExp(_pattern);
    return regex.hasMatch(path);
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

  static final _pattern = '(${_available.map((p) => p.name).join('|')})';
}
