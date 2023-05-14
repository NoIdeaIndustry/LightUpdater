import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:light_updater/components/components.dart';
import 'package:light_updater/miscellaneous/installer.dart';
import 'package:light_updater/models/models.dart';
import 'package:light_updater/utils/utils.dart';

import 'package:quiver/async.dart';

import 'package:light_updater/miscellaneous/platform.dart';
import 'package:light_updater/miscellaneous/progress.dart';

class UpdaterPage extends StatefulWidget {
  const UpdaterPage({super.key});

  @override
  State<UpdaterPage> createState() => _UpdaterPageState();
}

class _UpdaterPageState extends State<UpdaterPage> {
  // holds the current platform detected
  final platform = Platforms.getCurrent().name;

  // resolved at runtime, holds the install directory
  Directory directory = Directory("");

  // holds the current updater progress
  Progress progress = Progress.NULL;

  // used to tell the programm to shutdown after 'closeAfterSecs' seconds
  late CountdownTimer closeTimer;
  int curTimerValue = 5;

  // holds download/check progress (ex: curIdx/totIdx files remaining.)
  late int curIdx = 0, totIdx = 0;

  // holds the current file being downloaded/checked
  String curFilePath = "";

  @override
  void dispose() {
    closeTimer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _updateLogic();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color.fromARGB(255, 25, 25, 25),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                progress.message,
                style: Styles.defaultLightStyle,
                textAlign: TextAlign.center,
              ),
              ..._buildContent(),
              CustomSpacer.mediumHeightSpacer(),
              const CustomWatermark(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent() {
    switch (progress) {
      case Progress.CHECK:
        return [
          CustomSpacer.customHeightSpacer(25),
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(color: Colors.white30),
          ),
          CustomSpacer.customHeightSpacer(25),
          Text(
            '$curIdx/$totIdx files remaining...',
            style: Styles.defaultLightStyle,
            textAlign: TextAlign.center,
          ),
        ];
      case Progress.DOWNLOAD:
        if (curFilePath == "") return [];
        final cropPath = ".../${curFilePath.substring(
          curFilePath.indexOf(Config.appFolderName),
          curFilePath.length,
        )}";
        return [
          CustomSpacer.smallHeightSpacer(),
          Text(
            '$curIdx/$totIdx files remaining...',
            style: Styles.defaultLightStyle,
            textAlign: TextAlign.center,
          ),
          CustomSpacer.customHeightSpacer(25),
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(color: Colors.white30),
          ),
          CustomSpacer.customHeightSpacer(25),
          const Text(
            'Installation path',
            style: Styles.defaultLightLightStyle,
            textAlign: TextAlign.center,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 35.0, right: 35.0),
            child: Text(
              cropPath.replaceAll('\\', '/'),
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: Styles.smallDefaultLightStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ];
      case Progress.START:
        return Config.kCloseOnceStarted
            ? [
                Text(
                  "Closing in $curTimerValue seconds.",
                  style: Styles.defaultLightStyle,
                  textAlign: TextAlign.center,
                ),
              ]
            : [];
      case Progress.RUN:
        return Config.kRestartIfRunning
            ? [
                Text(
                  "Restarting in $curTimerValue seconds.",
                  style: Styles.defaultLightStyle,
                  textAlign: TextAlign.center,
                ),
              ]
            : [
                const Text(
                  "You must close the program before running the updater.",
                  style: Styles.defaultLightStyle,
                  textAlign: TextAlign.center,
                ),
              ];
      default:
        return [];
    }
  }

  Future<void> _updateLogic() async {
    print("Running update logic");
    await _updateProgress(Progress.CHECK);

    directory = Platforms.getInstallDirectory();

    await _stopRunningPrograms();
    if (progress == Progress.RUN) return;

    // getting platform associated json file for files download
    final _entries = await Installer.getFilesFromNetwork(
      '${Config.kJsonUrl}/$platform/$platform.json',
    );

    // no entries found? means an error occured
    if (_entries.isEmpty) {
      await _updateProgress(Progress.ERROR);
      return;
    }

    setState(() {
      curIdx = 0;
      totIdx = _entries.length;
    });

    final _downloads = await _checkFileIntegrity(_entries);
    await _updateProgress(Progress.DOWNLOAD);
    setState(() {
      curIdx = 0;
      totIdx = _downloads.length;
    });
    await _downloadFiles(_downloads);
    await _updateProgress(Progress.COMPLETE);

    _startRunningPrograms();
  }

  Future<List<Entry>> _checkFileIntegrity(final List<Entry> entries) async {
    List<Entry> downloads = [];
    for (final entry in entries) {
      if (await Installer.checkFilesIntegrity(entry, directory.path)) {
        downloads.add(entry);
      }

      setState(() {
        curIdx++;
      });
    }

    return downloads;
  }

  Future<void> _downloadFiles(final List<Entry> entries) async {
    for (final entry in entries) {
      final file = File('${directory.path}/${entry.name}');
      await Installer.downloadFile(
        '${Config.kHostUrl}/$platform/${entry.name}}',
        file.path,
      );
      setState(() {
        curFilePath = file.absolute.path.replaceAll('/', '\\');
        curIdx++;
      });
    }
  }

  // custom method to stop all the programm we want
  Future<void> _stopRunningPrograms() async {
    if (await _isProgramRunning('my_programme.exe')) {
      await _updateProgress(Progress.RUN);
    }

    if (Config.kRestartIfRunning && progress == Progress.RUN) {
      await _stopCustom(directory.path, 'my_programme.exe');
      // here add the programms you want to stop from running

      _startTimer();
    } else {}
  }

  // custom method to start all the programm we want
  Future<void> _startRunningPrograms() async {
    await _updateProgress(Progress.START);

    _startCustom(directory.path, 'my_programme.exe', []);
    // here add the programms you want to start

    if (Config.kCloseOnceStarted) {
      _startTimer();
    }
  }

  // update the progress
  Future<void> _updateProgress(final Progress status) async {
    setState(() {
      progress = status;
    });
  }

  // start the timer supposed to close the updater after each steps completed
  void _startTimer() {
    curTimerValue = Config.kCloseAfterSecs;

    closeTimer = CountdownTimer(
      const Duration(seconds: Config.kCloseAfterSecs),
      const Duration(seconds: 1),
    );

    closeTimer.listen((timer) {
      setState(() {
        curTimerValue -= 1;
      });
    }, onDone: () {
      switch (progress) {
        case Progress.RUN:
          _updateLogic();
          break;
        case Progress.START:
          exit(0);
        default:
          closeTimer.cancel();
          break;
      }
    });
  }

  // starts a program based on it's name (should work on any os)
  void _startProgram(final String path, List<String> args) async {
    Process.run(path, args, workingDirectory: directory.path);
  }

  // stops a program based on it's name (only works on windows)
  Future<void> _stopProgram(final String name) async {
    final ProcessResult result;
    if (Platform.isMacOS) {
      result = await Process.run('killall', [name]);
    } else if (Platform.isLinux) {
      result = await Process.run('pkill', ['-f', name, '-SIGTERM']);
    } else {
      result = await Process.run('taskkill', ['/f', '/im', name]);
    }

    /*
    if (result.exitCode == 0) {
      print('Process killed: $name');
    } else {
      print('Process not_found: $name');
    }*/
  }

  // creates a lock file (use this to keep track of program state (running or not))
  void _createLockFile(final String path, final String name) {
    final lockFile = File('$path/$name.lock');
    lockFile.createSync(recursive: true);
  }

  // deletes a lock file (use this to keep track of program state (running or not))
  Future<void> _deleteLockFile(final String path, final String name) async {
    final lockFile = File('$path/$name.lock');
    if (await lockFile.exists()) {
      await lockFile.delete();
    }
  }

  // check if a programm is running based on it's name
  Future<bool> _isProgramRunning(final String name) async {
    ProcessResult result;
    if (Platform.isMacOS) {
      result = await Process.run('ps', ['-ax']);
    } else if (Platform.isLinux) {
      result = await Process.run('ps', ['-eo', 'pid,user,%cpu,%mem,command']);
    } else {
      result = await Process.run('tasklist', ['/fo', 'csv', '/nh']);
    }
    final found = LineSplitter.split(result.stdout as String)
        .any((line) => line.toLowerCase().contains(name.toLowerCase()));
    return found;
  }

  // Use this to start a custom program with a path (where exe is located), a program name, and program args
  void _startCustom(final String path, final String name, List<String> args) {
    _createLockFile(path, name.substring(0, name.length - 4));
    _startProgram('$path/$name', args);
  }

  // Use this to close a custom program with a path (where lock file is located), and program name
  Future<void> _stopCustom(final String path, final String name) async {
    await _deleteLockFile(path, name);
    await _stopProgram(name);
  }
}
