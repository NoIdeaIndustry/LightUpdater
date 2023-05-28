import 'dart:io';

class FileLogger {
  static final File logs = File('${Directory.current.path}/logs.txt');

  static void init() {
    if (logs.existsSync()) {
      logs.deleteSync();
    }

    logs.createSync();

    print(logs.absolute.path);
  }

  static void writeToLogs(String content) {
    print('Logs: \'$content\'');
    logs.writeAsStringSync('$content\n', mode: FileMode.append);
  }
}
