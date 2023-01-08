import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpmlauncher/handler/window_handler.dart';

import '../../helper/test_helper.dart';

void main() {
  setUpAll(() => TestHelper.init());

  testWidgets('Create new window', (tester) async {
    const MethodChannel windowMangerChannel = MethodChannel('window_manager');
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(windowMangerChannel, (message) {
      if (message.method == 'setTitle') {
        return;
      }

      return;
    });

    await TestHelper.baseTestWidget(tester, Material(
      child: Builder(builder: (context) {
        return TextButton(
            child: const Text('click me'),
            onPressed: () async {
              await WindowHandler.createSubWindow(context, '/',
                  title: 'test title');
            });
      }),
    ));

    final button = find.text('click me');
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(WindowHandler.windows, [0, 1]);
    await WindowHandler.close();
  });

  test('Set full screen', () async {
    bool mockIsFullScreen = false;
    const MethodChannel windowMangerChannel = MethodChannel('window_manager');
    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
        .setMockMethodCallHandler(windowMangerChannel, (message) {
      if (message.method == 'setFullScreen') {
        mockIsFullScreen = message.arguments['isFullScreen'];

        return Future.value(null);
      }

      if (message.method == 'isFullScreen') {
        return Future.value(mockIsFullScreen);
      }

      return Future.value(null);
    });

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
