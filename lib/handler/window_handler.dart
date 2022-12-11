import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/database/data_box.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/launcher_info.dart';
import 'package:rpmlauncher/util/logger.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart';

class WindowHandler {
  static int id = 0;

  static bool get isMultiWindow => id != 0;
  static bool get isMainWindow => id == 0;

  static String get _kArgument => 'multi_window';

  static WindowController get controller {
    return WindowController.fromWindowId(id);
  }

  static Future<void> init() async {
    setWindowMinSize(const Size(960.0, 640.0));
    setWindowMaxSize(Size.infinite);

    await windowManager.ensureInitialized();
  }

  static void parseArguments(List<String> args) {
    int windowID = 0;
    Map arguments = {};

    int index = args.indexOf(_kArgument);
    if (index != -1) {
      windowID = int.parse(args[index + 1]);
      arguments = json.decode(args[index + 2]);
    }
    String? route = arguments['route'];
    String? title = arguments['title'];

    LauncherInfo.route = route ?? "/";
    id = windowID;
    if (title != null) {
      controller.setTitle(title);
    }
    windowManager.setIcon('assets/images/Logo.png');
  }

  static Future<WindowController> create(String route, {String? title}) async {
    final WindowController window =
        await DesktopMultiWindow.createWindow(json.encode({"route": route}));
    if (title != null) {
      await window.setTitle(title);
    }
    final Size size = WidgetsBinding.instance.window.physicalSize;
    window.setFrame(const Offset(0, 0) & size);

    await window.center();
    await window.show();

    return window;
  }

  static Future<void> close() async {
    await DataBox.close();
    await controller.close();
  }

  static Future<void> setFullScreen(bool value) async {
    await windowManager.setFullScreen(value);
  }

  static Future<bool> isFullScreen() async {
    return await windowManager.isFullScreen();
  }

  static Future<void> setTheme(int themeId) async {
    try {
      final ids = await DesktopMultiWindow.getAllSubWindowIds();

      for (final id in ids) {
        await DesktopMultiWindow.invokeMethod(id, 'setTheme', [themeId]);
      }
    } catch (e, s) {
      logger.error(ErrorType.ui, 'Failed to set theme: $e', stackTrace: s);
    }
  }
}
