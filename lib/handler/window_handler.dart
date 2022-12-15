import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/database/data_box.dart';
import 'package:rpmlauncher/util/launcher_info.dart';
import 'package:window_size/window_size.dart';
import 'package:window_manager/window_manager.dart';

class WindowHandler {
  static int id = 0;

  static bool get isMultiWindow => id != 0;
  static bool get isMainWindow => id == 0;
  static List<int> windows = [id];

  static String get _kArgument => 'sub_window';

  static Future<void> init() async {
    if (kTestMode) return;
    setWindowMinSize(const Size(960.0, 640.0));
    setWindowMaxSize(Size.infinite);

    await windowManager.ensureInitialized();
  }

  static Future<void> parseArguments(List<String> args) async {
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
      await windowManager.setTitle(title);
      await windowManager.center();
      await windowManager.show();
    }
  }

  static Future<void> createSubWindow(BuildContext context, String route,
      {String? title}) async {
    int windowId = id + 1;

    if (kReleaseMode) {
      List<String> arguments = [
        _kArgument,
        windowId.toString(),
        json.encode({'route': route, 'title': title})
      ];

      List<String> originalArgs = Platform.executableArguments;
      if (originalArgs.isNotEmpty) {
        int index = originalArgs.indexOf('--$_kArgument');
        if (index != -1) {
          try {
            originalArgs.removeAt(index);
            originalArgs.removeAt(index + 1); // Remove the window id
            originalArgs
                .removeAt(index + 2); // Remove the window route/title arguments
          } on StateError {
            // ignore
          }
        }

        arguments = [...originalArgs, ...arguments];
      }

      await Process.run(Platform.resolvedExecutable, arguments);
    } else {
      Navigator.pushNamed(context, route);
      if (title != null) await windowManager.setTitle(title);
    }

    windows.add(windowId);
  }

  static Future<void> close() async {
    await DataBox.close();
    await windowManager.close();
  }

  static Future<void> setFullScreen(bool value) async {
    await windowManager.setFullScreen(value);
  }

  static Future<bool> isFullScreen() async {
    return windowManager.isFullScreen();
  }
}
