import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:desktop_multi_window/src/channels.dart';
import 'package:rpmlauncher/handler/window_handler.dart';

import '../script/test_helper.dart';

void main() {
  setUpAll(() => TestHelper.init());

  test("Create new window", () async {
    multiWindowChannel.setMockMethodCallHandler((call) async {
      switch (call.method) {
        case "createWindow":
          return 1;
      }
    });
    final WindowController window =
        await WindowHandler.create("/", title: "test title");
    expect(window.windowId, 1);
    await WindowHandler.close();
  });

  test("Set full screen", () async {
    multiWindowChannel.setMockMethodCallHandler((call) async {
      switch (call.method) {
        case 'createWindow':
          return 1;
      }
    });
    const MethodChannel windowSizeChannel = MethodChannel('flutter/windowsize');
    windowSizeChannel.setMockMethodCallHandler((call) async {
      switch (call.method) {
        case 'getWindowInfo':
          return {
            'frame': [0.0, 0.0, 1920.0, 1080.0],
            'scaleFactor': 1.0,
            'screen': null
          };
      }
    });

    final WindowController window =
        await WindowHandler.create("/", title: "test title");
    expect(window.windowId, 1);
    bool isFullScreen = await WindowHandler.isFullScreen();
    expect(isFullScreen, false);
    await WindowHandler.setFullScreen(true);
    isFullScreen = await WindowHandler.isFullScreen();
    expect(isFullScreen, true);
    await WindowHandler.setFullScreen(false);
    isFullScreen = await WindowHandler.isFullScreen();
    await WindowHandler.close();
  });
}
