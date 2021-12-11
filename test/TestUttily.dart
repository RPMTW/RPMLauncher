import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_context_navigation/no_context_navigation.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/Data.dart';
import 'package:rpmlauncher/Utility/LauncherInfo.dart';

enum TestData {
  minecraftNews,
  minecraftMeta,
  forge112Args,
  fabric117Args,
  versionManifest
}

extension TestDataExtension on TestData {
  String toFileName() {
    switch (this) {
      case TestData.minecraftNews:
        return "MinecraftNews-2021-11-6.xml";
      case TestData.minecraftMeta:
        return "Minecraft-1.18-meta.json";
      case TestData.forge112Args:
        return "Forge-1.12.2-args.json";
      case TestData.fabric117Args:
        return "Fabric-1.17.1-args.json";
      case TestData.versionManifest:
        return "Minecraft-Version-Manifest-V2.json";
      default:
        return name;
    }
  }

  File getFile() =>
      File(join(Directory.current.path, 'test', 'data', toFileName()));

  String getFileString() => getFile().readAsStringSync();

  Uint8List getBytesString() => getFile().readAsBytesSync();
}

class TestUttily {
  static Future<void> _pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(
        navigatorKey: NavigationService.navigationKey, home: child));
  }

  static Future<int> pumpAndSettle(WidgetTester tester) async {
    return await TestAsyncUtils.guard<int>(() async {
      final TestWidgetsFlutterBinding binding = tester.binding;
      int count = 0;
      do {
        await binding.pump(
            Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate);
        count += 1;
      } while (binding.hasScheduledFrame);
      return count;
    });
  }

  static Future<void> baseTestWidget(WidgetTester tester, Widget child,
      {bool async = false,
      Duration asyncDuration = const Duration(seconds: 2)}) async {
    if (async) {
      await tester.runAsync(() async {
        await _pump(tester, child);
        await Future.delayed(asyncDuration);
      });
      await tester.pumpAndSettle();
      // await pumpAndSettle(tester);
    } else {
      await _pump(tester, child);
      await tester.pump();
    }
  }

  static Future<void> init() async {
    LauncherInfo.isDebugMode = kDebugMode;
    kTestMode = true;
    TestWidgetsFlutterBinding.ensureInitialized();
    await Data.init();
    HttpOverrides.global = null;
  }
}
