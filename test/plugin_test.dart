import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpmlauncher/Utility/LauncherInfo.dart';
import 'package:rpmlauncher_plugin/rpmlauncher_plugin.dart';

void main() {
  const MethodChannel channel = MethodChannel('rpmlauncher_plugin');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getPlatformVersion') {
        return 'Linux Ubuntu 21.10';
      }
    });
  });

  setUpAll(() => kTestMode = true);

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await RPMLauncherPlugin.platformVersion, 'Linux Ubuntu 21.10');
  });
}
