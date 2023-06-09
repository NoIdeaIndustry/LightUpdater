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

  WindowManager.instance.setTitle('LightUpdater - ${Config.kCustomWindowName}');

  runApp(const UpdaterPage());
}
