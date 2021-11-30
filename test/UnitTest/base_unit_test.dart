import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpmlauncher/Utility/LauncherInfo.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/Game/ModInfo.dart';
import 'package:rpmlauncher/Function/Analytics.dart';
import 'package:rpmlauncher/Utility/Logger.dart';
import 'package:rpmlauncher/Utility/Updater.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/main.dart';
import 'dart:developer';

import '../TestUttily.dart';

void main() async {
  setUpAll(() => TestUttily.init());

  const MethodChannel _channel = MethodChannel('rpmlauncher_plugin');

  setUp(() {
    _channel.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getTotalPhysicalMemory') {
        return 8589934592.00; // 8GB
      }
    });
  });

  tearDown(() {
    _channel.setMockMethodCallHandler(null);
  });

  group('RPMLauncher Unit Test -', () {
    test(
      'i18n',
      () async {
        I18n.getLanguageCode();
        log(I18n.format('init.quick_setup.content'));
      },
    );
    test('Launcher info', () async {
      log("Launcher Version: ${LauncherInfo.version}");
      log("Launcher Version Type (i18n): ${Updater.toI18nString(LauncherInfo.getVersionType())}");
      log("Launcher Executing File: ${LauncherInfo.getExecutingFile()}");
      log("Launcher DataHome: $dataHome");
      log("PhysicalMemory: ${await Uttily.getTotalPhysicalMemory()} MB");
    });
    testWidgets('Check dev updater', (WidgetTester tester) async {
      LauncherInfo.isDebugMode = false;
      late VersionInfo dev;
      await tester.runAsync(() async {
        dev = await Updater.checkForUpdate(VersionTypes.dev);
      });

      await TestUttily.baseTestWidget(tester, Container());

      if (dev.needUpdate) {
        log("Dev channel need update");
        await Updater.download(dev);
      } else {
        log("Dev channel not need update");
      }
    });
    test('Check debug updater', () async {
      /// 如果更新通道是 debug ，將不會收到更新資訊，因此返回 false
      expect(
          (await Updater.checkForUpdate(VersionTypes.debug)).needUpdate, false);
    });
    // test('Check stable updater', () async {
    //   LauncherInfo.isDebugMode = false;
    //   bool Stable =
    //       (await Updater.checkForUpdate(VersionTypes.stable)).needUpdate;
    //   print("Stable channel ${Stable ? "need update" : "not need update"}");
    // });
    test('log test', () {
      Logger.currentLogger.info('Hello World');
      Logger.currentLogger.error(ErrorType.unknown, "Test Unknown Error",
          stackTrace: StackTrace.current);
    });
    test('Google Analytics', () async {
      Analytics ga = Analytics();
      await ga.ping();
    });
    test('Check Minecraft Fabric Mod Conflicts', () async {
      ModInfo myMod = ModInfo(
          loader: ModLoader.fabric,
          name: "RPMTW",
          description: "Hello RPMTW World",
          version: "1.0.1",
          curseID: null,
          id: "rpmtw",
          filePath: "");

      ModInfo conflictsMod = ModInfo(
          loader: ModLoader.forge,
          name: "Conflicts Mod",
          description: "",
          version: "1.0.0",
          curseID: null,
          id: "conflicts_mod",
          conflicts: ConflictMods(
              {"rpmtw": ConflictMod(modID: "rpmtw", versionID: "1.0.1")}),
          filePath: "");

      expect(conflictsMod.conflicts!.isConflict(myMod), true);
    });
  });
}
