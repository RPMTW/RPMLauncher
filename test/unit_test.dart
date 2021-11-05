import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_context_navigation/no_context_navigation.dart';
import 'package:rpmlauncher/Utility/LauncherInfo.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/ModInfo.dart';
import 'package:rpmlauncher/Screen/About.dart';
import 'package:rpmlauncher/Screen/Account.dart';
import 'package:rpmlauncher/Screen/CurseForgeModPack.dart';
import 'package:rpmlauncher/Screen/FTBModPack.dart';
import 'package:rpmlauncher/Screen/Settings.dart';
import 'package:rpmlauncher/Screen/VersionSelection.dart';
import 'package:rpmlauncher/Function/Analytics.dart';
import 'package:rpmlauncher/Utility/Loggger.dart';
import 'package:rpmlauncher/Utility/Updater.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/RPMPath.dart';

void main() async {
  LauncherInfo.isDebugMode = kDebugMode;
  await RPMPath.init();
  TestWidgetsFlutterBinding.ensureInitialized();
  await I18n.init();
  setUpAll(() {
    HttpOverrides.global = null;
    kTestMode = true;
  });

  void logger(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  group('RPMLauncher Unit Test -', () {
    test('i18n', () async {
      I18n.getLanguageCode();
      logger(I18n.format('init.quick_setup.content'));
    });
    test('Launcher info', () {
      logger("Launcher Version: ${LauncherInfo.getVersion()}");
      logger(
          "Launcher Version Type (i18n): ${Updater.toI18nString(LauncherInfo.getVersionType())}");
      logger("Launcher Executing File: ${LauncherInfo.getExecutingFile()}");
    });
    testWidgets('Check dev updater', (WidgetTester tester) async {
      LauncherInfo.isDebugMode = false;
      late VersionInfo dev;
      await tester.runAsync(() async {
        dev = await Updater.checkForUpdate(VersionTypes.dev);
      });

      await TestUttily.baseTestWidget(tester, Container());

      if (dev.needUpdate) {
        logger("Dev channel need update");
        await Updater.download(dev);
      } else {
        logger("Dev channel not need update");
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
    test('Logger test', () {
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
          loader: ModLoaders.fabric,
          name: "RPMTW",
          description: "Hello RPMTW World",
          version: "1.0.1",
          curseID: null,
          id: "rpmtw",
          filePath: "");

      ModInfo conflictsMod = ModInfo(
          loader: ModLoaders.forge,
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
    testWidgets('Settings Screen', (WidgetTester tester) async {
      await TestUttily.baseTestWidget(tester, SettingScreen());
      expect(find.text(I18n.format("settings.title")), findsOneWidget);
    });
    testWidgets('About Screen', (WidgetTester tester) async {
      await TestUttily.baseTestWidget(tester, AboutScreen());
    });
    testWidgets('Account Screen', (WidgetTester tester) async {
      await TestUttily.baseTestWidget(tester, AccountScreen(), async: true);
    });
    testWidgets('VersionSelection Screen', (WidgetTester tester) async {
      await TestUttily.baseTestWidget(tester, VersionSelection(), async: true);
    });
    testWidgets('ModPackage Screen', (WidgetTester tester) async {
      await TestUttily.baseTestWidget(tester, CurseForgeModPack(), async: true);
      await TestUttily.baseTestWidget(tester, FTBModPack(), async: true);
    });
  });
}

class TestUttily {
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
}
