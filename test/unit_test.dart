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
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/path.dart';

void main() async {
  LauncherInfo.isDebugMode = kDebugMode;
  await path.init();
  TestWidgetsFlutterBinding.ensureInitialized();
  await i18n.init();
  setUpAll(() {
    HttpOverrides.global = null;
  });
  group('RPMLauncher Unit Test -', () {
    test('i18n', () async {
      i18n.getLanguageCode();
      print(i18n.format('init.quick_setup.content'));
    });
    test('Launcher info', () {
      print("Launcher Version: ${LauncherInfo.getVersion()}");
      print(
          "Launcher Version Type (i18n): ${Updater.toI18nString(LauncherInfo.getVersionType())}");
      print("Launcher Executing File: ${LauncherInfo.getExecutingFile()}");
    });
    testWidgets('Check dev updater', (WidgetTester tester) async {
      LauncherInfo.isDebugMode = false;
      late VersionInfo Dev;
      await tester.runAsync(() async {
        Dev = await Updater.checkForUpdate(VersionTypes.dev);
      });

      await TestUttily.baseTestWidget(tester, Container());

      if (Dev.needUpdate) {
        print("Dev channel need update");
        await Updater.download(Dev);
      } else {
        print("Dev channel not need update");
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
      Logger.currentLogger.error(ErrorType.Unknown, "Test Unknown Error");
    });
    test('Google Analytics', () async {
      Analytics ga = Analytics();
      await ga.ping();
    });
    test('Check Minecraft Fabric Mod Conflicts', () async {
      ModInfo myMod = ModInfo(
          loader: ModLoaders.Fabric,
          name: "RPMTW",
          description: "Hello RPMTW World",
          version: "1.0.1",
          curseID: null,
          id: "rpmtw",
          filePath: "");

      ModInfo conflictsMod = ModInfo(
          loader: ModLoaders.Forge,
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
      expect(find.text(i18n.format("settings.title")), findsOneWidget);
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
