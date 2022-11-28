import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/database/data_box.dart';
import 'package:rpmlauncher/util/launcher_info.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart';

class WindowHandler {
  static int id = 0;

  static bool get isMultiWindow => id != 0;
  static bool get isMainWindow => id == 0;

  /// enabled `window_manager` package
  static bool get _enableManager =>
      (WindowHandler.isMainWindow || kReleaseMode) && !kTestMode;
  static bool? _isFullScreen;
  static String get _kArgument => 'multi_window';

  static WindowController get controller {
    if (kReleaseMode) {
      return _SelfWindowController(id: id);
    } else {
      return WindowController.fromWindowId(id);
    }
  }

  static Future<void> init() async {
    setWindowMinSize(const Size(960.0, 640.0));
    setWindowMaxSize(Size.infinite);

    if (_enableManager) {
      await windowManager.ensureInitialized();
    }
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
  }

  static Future<WindowController> create(String route, {String? title}) async {
    if (kReleaseMode && !Platform.isMacOS) {
      int windowId = id + 1;
      List<String> arguments = [
        _kArgument,
        windowId.toString(),
        json.encode({'route': route, 'title': title})
      ];

      List<String> originalArgs = Platform.executableArguments;
      if (originalArgs.isNotEmpty) {
        int index = originalArgs.indexOf('--multi-window');
        if (index != -1) {
          try {
            originalArgs.removeAt(index);
            originalArgs.removeAt(index + 1); // remove window id
            originalArgs.removeAt(index + 2); // remove window arguments
          } on StateError {
            // ignore
          }
        }

        arguments = [...originalArgs, ...arguments];
      }

      await Process.run(Platform.resolvedExecutable, arguments);

      return _SelfWindowController(id: windowId);
    } else {
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
  }

  static Future<void> close() async {
    await DataBox.close();
    await controller.close();
  }

  static Future<void> setFullScreen(bool value) async {
    if (_enableManager) {
      await windowManager.setFullScreen(value);
    } else {
      if (value) {
        Screen? screen = await getCurrentScreen();
        if (screen != null) {
          setWindowFrame(screen.frame);
        }

        _isFullScreen = true;
      } else {
        setWindowFrame(const Rect.fromLTRB(0, 0, 960.0, 640.0));

        _isFullScreen = false;
      }
    }
  }

  static Future<bool> isFullScreen() async {
    if (_enableManager) {
      _isFullScreen = await windowManager.isFullScreen();
    }

    return _isFullScreen ?? false;
  }
}

class _SelfWindowController implements WindowController {
  final int id;
  const _SelfWindowController({required this.id});

  @override
  Future<void> center() async {
    await windowManager.center();
  }

  @override
  Future<void> close() async {
    await windowManager.close();
  }

  @override
  Future<void> hide() async {
    await windowManager.hide();
  }

  @override
  Future<void> setFrame(Rect frame) async {
    await windowManager.setBounds(frame);
  }

  @override
  Future<void> setFrameAutosaveName(String name) async {
    // TODO: implement setFrameAutosaveName
    throw UnimplementedError();
  }

  @override
  Future<void> setTitle(String title) async {
    await windowManager.setTitle(title);
  }

  @override
  Future<void> show() async {
    await windowManager.show();
  }

  @override
  Future<bool> resizable(bool resizable) async {
    return resizable;
  }

  @override
  int get windowId => id;
}
