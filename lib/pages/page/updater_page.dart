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

  // holds the current updater progress
  Progress progress = Progress.CHECK;

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
        return Config.kCloseIfStarted
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

  void _updateLogic() async {
    print("Running update logic");
    if (progress != Progress.CHECK) return;

    final directory = await Installer.getInstallationDirectory();
    final entries = await Installer.getFilesFromNetwork(
      '${Config.kJsonUrl}/$platform/$platform.json',
    );

    if (entries == null) {
      _updateProgress(Progress.ERROR);
      return;
    }

    // checks if program is running
    if (await _isProgramRunning('my_custom_app.exe')) {
      _updateProgress(Progress.RUN);

      // close and restart updater if kRestartIfRunning is true
      if (Config.kRestartIfRunning) {
        _startTimer();
        await _stopCustom(
            '${directory.path}/local/path/from/dir', 'my_custom_app.exe');
        // you can stop as many app as you wish.
      }
    } else {
      setState(() {
        curIdx = 0;
        totIdx = entries.length;
      });

      _updateProgress(Progress.CHECK);
      final needDownload = List.empty(growable: true);
      for (final entry in entries) {
        if (!await _needDownload(directory.path, entry)) {
          needDownload.add(entry);
        }
      }

      setState(() {
        curIdx = 0;
        totIdx = needDownload.length;
      });

      if (needDownload.isNotEmpty) {
        _updateProgress(Progress.DOWNLOAD);
        for (final entry in needDownload) {
          await _downloadFile(directory.path, entry);
        }
      }

      _updateProgress(Progress.COMPLETE);
      Future.delayed(const Duration(seconds: 2));

      /*
        Call you things here instead...
        final args = [];
        _startCustom(directory.path, python/python.exe, args)
      */
      _startCustom(directory.path, 'local/path/from/dir/my_custom_app.exe', []);
      // you can start as many app as you wish.

      _updateProgress(Progress.RUN);
      if (Config.kCloseIfStarted) {
        _startTimer();
      }
    }
  }

  // update the progress
  void _updateProgress(final Progress status) async {
    setState(() {
      progress = status;
    });

    print(progress.message);
  }

  // start the timer supposed to close the updater after each steps completed
  void _startTimer() {
    curTimerValue = Config.kCloseAfterSecs;
    Timer timer;

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        curTimerValue = Config.kCloseAfterSecs - timer.tick;
      });

      if (timer.tick == Config.kCloseAfterSecs) {
        switch (progress) {
          case Progress.RUN:
            _updateProgress(Progress.CHECK);
            _updateLogic();
            break;
          case Progress.START:
            exit(0);
          default:
            timer.cancel();
        }
      }
    });
  }

  // download the file using entry url
  Future<void> _downloadFile(final String path, final Entry entry) async {
    final localFile = File('$path/${entry.file}');
    final request = await HttpClient()
        .getUrl(Uri.parse('${Config.kHostUrl}/$platform/${entry.file}'));
    final response = await request.close();
    await response.pipe(localFile.openWrite());

    setState(() {
      curFilePath = localFile.absolute.path.replaceAll('/', '\\');
      curIdx++;
    });
  }

  // updates curIdx and returns wether the file needs to be downloaded or not
  Future<bool> _needDownload(final String path, final Entry entry) async {
    setState(() {
      curIdx++;
    });

    final localFile = File('$path/${entry.file}');
    return await Installer.needDownload(localFile, entry.hash);
  }

  // starts a program based on it's name (should work on any os)
  void _startProgram(final String path, List<String> args) async {
    Process.run(path, args);
  }

  // stops a program based on it's name (only works on windows)
  Future<void> _stopProgram(final String name) async {
    await Process.run('taskkill', ['/f', '/im', name]);

    // use the following lines if you want to print whether or not the process has been killed
    /*final process = await Process.run('taskkill', ['/f', '/im', name]);
    if (process.exitCode == 0) {
      print('Process killed: $name');
    } else {
      print('Process not_found: $name');
    }*/
  }

  // creates a lock file (use this to keep track of program state (running or not))
  void _createLockFile(final String path, final String name) {
    final lockFile = File('$path/$name.lock');
    lockFile.createSync();
  }

  // deletes a lock file (use this to keep track of program state (running or not))
  Future<void> _deleteLockFile(final String path, final String name) async {
    final lockFile = File('$path/$name.lock');
    if (await lockFile.exists()) {
      await lockFile.delete();
    }
  }

  Future<bool> _isProgramRunning(final String name) async {
    final result = await Process.run('tasklist', ['/fo', 'csv', '/nh']);
    return LineSplitter.split(result.stdout as String)
        .any((line) => line.toLowerCase().contains(name.toLowerCase()));
  }

  // Use this to start a custom program with a path (where exe is located), a program name, and program args
  void _startCustom(final String path, final String name, List<String> args) {
    _createLockFile(path, name);
    _startProgram('$path/$name', args);
    _updateProgress(Progress.START);
    if (Config.kCloseIfStarted) _startTimer();
  }

  // Use this to close a custom program with a path (where lock file is located), and program name
  Future<void> _stopCustom(final String path, final String name) async {
    await _deleteLockFile(path, name);
    await _stopProgram(name);
  }
}
