import 'dart:convert';
import 'dart:io';

class Console {
  static Future<ProcessResult> runCustomProcess(
    String executable,
    List<String> arguments,
    String workingDirectory,
    bool inShell,
  ) async {
    return Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: inShell,
    );
  }

  static Future<ProcessResult> runProcess(
    String processName,
    List<String> arguments,
    String workingDirectory,
  ) async {
    if (Platform.isMacOS) {
      return Process.run(
        'open',
        ['-a', processName, ...arguments],
        workingDirectory: workingDirectory,
      );
    } else if (Platform.isLinux) {
      return Process.run(
        'xdg-open',
        [processName, ...arguments],
        workingDirectory: workingDirectory,
      );
    } else if (Platform.isWindows) {
      return Process.run(
        '$workingDirectory/$processName',
        arguments,
        workingDirectory: workingDirectory,
      );
    } else {
      throw UnsupportedError(
        'Unsupported platform: ${Platform.operatingSystem}',
      );
    }
  }

  static String? isProcessRunning(String processName) {
    ProcessResult result;

    if (Platform.isMacOS) {
      result = Process.runSync('ps', ['-ax']);
    } else if (Platform.isLinux) {
      result = Process.runSync('ps', ['-eo', 'pid,user,%cpu,%mem,command']);
    } else if (Platform.isWindows) {
      result = Process.runSync('tasklist', ['/fo', 'csv', '/nh']);
    } else {
      throw UnsupportedError(
        'Unsupported platform: ${Platform.operatingSystem}',
      );
    }

    String? processLine;
    LineSplitter.split(result.stdout as String).any((line) {
      final isRunning = line.toLowerCase().contains(processName.toLowerCase());
      if (isRunning) processLine = line;
      return isRunning;
    });

    if (processLine == null) return null;
    return processLine!.split(',')[1].replaceAll('"', '');
  }

  static String? isCustomProcessRunning(
      String processName, String command, List<String> args) {
    ProcessResult result = Process.runSync(command, args);

    String? processLine;
    LineSplitter.split(result.stdout as String).any((line) {
      final isRunning = line.toLowerCase().contains(processName.toLowerCase());
      if (isRunning) processLine = line;
      return isRunning;
    });

    if (processLine == null) return null;
    return RegExp(r'\d+')
        .allMatches(processLine!)
        .map((match) => match.group(0))
        .first;
  }

  static ProcessResult killProcessById(String pid) {
    if (Platform.isMacOS || Platform.isLinux) {
      return Process.runSync('kill', ['-9', pid]);
    } else if (Platform.isWindows) {
      return Process.runSync('taskkill', ['/f', '/pid', pid]);
    } else {
      throw UnsupportedError(
        'Unsupported platform: ${Platform.operatingSystem}',
      );
    }
  }
}
