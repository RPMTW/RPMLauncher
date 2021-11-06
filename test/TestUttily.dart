import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_context_navigation/no_context_navigation.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/Datas.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/LauncherInfo.dart';
import 'package:rpmlauncher/Utility/RPMPath.dart';

enum TestData { minecraftNews }

extension TestDatasExtension on TestData {
  String toDataString() {
    switch (this) {
      case TestData.minecraftNews:
        return "MinecraftNews-2021-11-6.xml";
      default:
        return name;
    }
  }

  File getFile() =>
      File(join(Directory.current.path, 'test', 'data', toDataString()));

  String getFileString() => getFile().readAsStringSync();

  Uint8List getBytesString() => getFile().readAsBytesSync();
}

class TestUttily {
  static TargetPlatformVariant targetPlatformVariant = Platform.isMacOS
      ? TargetPlatformVariant.only(TargetPlatform.macOS)
      : TargetPlatformVariant.desktop();

  static Future<void> _pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(
        navigatorKey: NavigationService.navigationKey, home: child));
  }

  static Future<void> baseTestWidget(WidgetTester tester, Widget child,
      {bool async = false}) async {
    if (async) {
      await tester.runAsync(() async {
        await _pump(tester, child);
      });
    } else {
      await _pump(tester, child);
    }
  }

  static Future<void> init() async {
    LauncherInfo.isDebugMode = kDebugMode;
    await RPMPath.init();
    TestWidgetsFlutterBinding.ensureInitialized();
    await I18n.init();
    await Datas.init();
    HttpOverrides.global = null;
    kTestMode = true;
  }
}
