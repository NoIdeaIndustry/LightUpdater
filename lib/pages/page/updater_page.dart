import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:light_updater/components/components.dart';
import 'package:light_updater/miscellaneous/console.dart';
import 'package:light_updater/miscellaneous/file_logger.dart';
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

  // holds the remote entries found on host
  List<Entry> _entries = [];

  // holds the entries that needs to be downloaded
  final List<Entry> _downloads = [];

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
    FileLogger.writeToLogs('STARTING UPDATE PROCESS...');
    directory = Platforms.getInstallDirectory();
    FileLogger.writeToLogs(
      'Found suitable install directory at: \'${directory.absolute.path}\'',
    );

    await _stopRunningPrograms();
    if (progress == Progress.RUN) return;

    await _getNetworkEntries();

    await _updateProgress(Progress.CHECK);
    setState(() {
      curIdx = 0;
      totIdx = _entries.length;
    });
    await _checkFileIntegrity();

    await _updateProgress(Progress.DOWNLOAD);
    setState(() {
      curIdx = 0;
      totIdx = _downloads.length;
    });
    await _downloadFiles();

    await _updateProgress(Progress.COMPLETE);
    await _startRunningPrograms();
  }

  Future<void> _getNetworkEntries() async {
    FileLogger.writeToLogs('RETRIEVING REMOTE FILES...');
    final data = await Installer.getFilesFromNetwork(
      '${Config.kJsonUrl}/$platform/$platform.json',
    );
    FileLogger.writeToLogs('Found ${data.length} remote files!');
    if (data.isEmpty) _updateProgress(Progress.ERROR);
    setState(() => _entries = data);
  }

  Future<void> _checkFileIntegrity() async {
    FileLogger.writeToLogs('CHECKING FILES INTEGRITY...');
    List<Entry> downloads = [];
    for (final entry in _entries) {
      if (await Installer.checkFilesIntegrity(entry, directory.path)) {
        downloads.add(entry);
        FileLogger.writeToLogs('File \'${entry.file}\' needs to be updated!');
      }
      setState(() => curIdx++);
    }

    FileLogger.writeToLogs(
      'Integrity check done for ${_entries.length} files!',
    );
  }

  Future<void> _downloadFiles() async {
    FileLogger.writeToLogs('DOWNLOADING MISSING FILES...');
    if (_downloads.isEmpty) {
      FileLogger.writeToLogs('No missing files detected.');
    }
    for (final entry in _downloads) {
      final file = File('${directory.path}/${entry.file}');
      await Installer.downloadFile(
        '${Config.kHostUrl}/$platform/${entry.file}}',
        file.path,
      );
      setState(() {
        curFilePath = file.absolute.path.replaceAll('/', '\\');
        curIdx++;
      });
      FileLogger.writeToLogs('File \'${entry.file}\' successfully downloaded!');
    }
  }

  // custom method to stop all the programm we want
  Future<void> _stopRunningPrograms() async {
    FileLogger.writeToLogs('CHECKING RUNNING PROGRAMMS...');
    final pid = Console.isProcessRunning('my_app_name');
    if (pid != null) {
      await _updateProgress(Progress.RUN);
    }

    if (Config.kRestartIfRunning && progress == Progress.RUN) {
      _startTimer();
      if (pid != null) {
        _stopProgram('my_app_name', pid);
      }
    } else {}

    if (progress != Progress.RUN) {
      FileLogger.writeToLogs('No running programms found.');
    }
  }

  // custom method to start all the programm we want
  Future<void> _startRunningPrograms() async {
    await _updateProgress(Progress.START);

    // start with a relative path based on 'directory', edit according to app extension
    _startProgram(
      'folder/my_app_name${Platform.isMacOS ? '.app' : '.exe'}',
      [],
    );
    // here add the programms you want to start

    if (Config.kCloseOnceStarted) {
      _startTimer();
    } else {}
  }

  // update the progress
  Future<void> _updateProgress(final Progress status) async {
    setState(() {
      progress = status;
    });
  }

  // starts a program based on it's name (should work on any os)
  void _startProgram(String path, List<String> args) async {
    FileLogger.writeToLogs('Starting process at: \'$path\'');
    final process = await Console.runProcess(
      path,
      args,
      directory.path,
    );
    FileLogger.writeToLogs(
      'Process started with pid: ${process.pid}',
    );
  }

  // stops a program based on it's name (only works on windows)
  void _stopProgram(String name, String pid) {
    var process = Console.killProcessById(pid);
    // use the following lines if you want to print whether or not the process has been killed
    if (process.exitCode == 0) {
      FileLogger.writeToLogs('Process killed: \'$name\' with pid: \'$pid\'');
    } else {
      FileLogger.writeToLogs('Process killed: \'$name\' with pid: \'$pid\'');
    }
  }

  // start the timer supposed to close the updater after each steps completed
  void _startTimer() {
    curTimerValue = Config.kCloseAfterSecs;

    closeTimer = CountdownTimer(
      const Duration(seconds: Config.kCloseAfterSecs),
      const Duration(seconds: 1),
    );

    closeTimer.listen((timer) {
      setState(() => curTimerValue -= 1);
    }, onDone: () {
      switch (progress) {
        case Progress.RUN:
          _updateLogic();
          break;
        case Progress.START:
          exit(0);
        default:
          break;
      }
    });
  }
}
