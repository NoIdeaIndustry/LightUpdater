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

  if (!Platform.isMacOS) {
    // does not work on macos (must do on xcode config if you want to config this)
    WindowManager.instance.setIcon(Config.kWindowIcon);
  }

  WindowManager.instance.setTitle('LightUpdater - ${Config.kCustomWindowName}');
  WindowManager.instance.setAlwaysOnTop(true);

  runApp(const UpdaterPage());
}
