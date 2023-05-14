import 'dart:io';

import 'package:flutter/material.dart';

import 'package:window_manager/window_manager.dart';

import 'package:light_updater/pages/pages.dart';
import 'package:light_updater/utils/utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  WindowManager.instance.setMinimumSize(const Size(850, 450));
  WindowManager.instance.setMaximumSize(const Size(850, 450));
  WindowManager.instance.setSize(const Size(850, 450));
  WindowManager.instance.setResizable(false);

  if (Platform.isWindows) {
    // only works on windows
    // for macos -> xcode config or project -> macos/Runner/Assets.xcassets/AppIcon.appiconset
    // for linux -> .desktop think, must be done manually, good luck with that!
    WindowManager.instance.setIcon(Config.kWindowIcon);
  }

  WindowManager.instance.setTitle('LightUpdater - ${Config.kCustomWindowName}');

  runApp(const UpdaterPage());
}
