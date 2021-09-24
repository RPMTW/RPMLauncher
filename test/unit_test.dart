// ignore_for_file: unused_local_variable

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_context_navigation/no_context_navigation.dart';
import 'package:rpmlauncher/LauncherInfo.dart';
import 'package:rpmlauncher/Screen/About.dart';
import 'package:rpmlauncher/Screen/Account.dart';
import 'package:rpmlauncher/Screen/CurseForgeMod.dart';
import 'package:rpmlauncher/Screen/CurseForgeModPack.dart';
import 'package:rpmlauncher/Screen/FTBModPack.dart';
import 'package:rpmlauncher/Screen/Settings.dart';
import 'package:rpmlauncher/Screen/VersionSelection.dart';
import 'package:rpmlauncher/Utility/Loggger.dart';
import 'package:rpmlauncher/Utility/Updater.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/path.dart';

void main() async {
  await path().init();
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
    test('Need for update', () async {
      bool Dev = (await Updater.checkForUpdate(VersionTypes.dev)).needUpdate;
      // bool Stable =
      //     (await Updater.checkForUpdate(VersionTypes.stable)).needUpdate;

      print("Dev channel ${Dev ? "need update" : "not need update"}");
      // print("Stable channel ${Stable ? "need update" : "not need update"}");

      /// 如果更新通道是 debug ，將不會更新，因此返回 false
      expect(
          (await Updater.checkForUpdate(VersionTypes.debug)).needUpdate, false);
    });
    test('Logger test', () => {Logger.currentLogger.send('Hello World')});
    testWidgets('Settings Screen', (WidgetTester tester) async {
      await TestUttily.BaseTestWidget(tester, SettingScreen());
      expect(find.text(i18n.format("settings.title")), findsOneWidget);
    });
    testWidgets('About Screen', (WidgetTester tester) async {
      await TestUttily.BaseTestWidget(tester, AboutScreen());
    });
    testWidgets('Account Screen', (WidgetTester tester) async {
      await TestUttily.BaseTestWidget(tester, AccountScreen(), async: true);
    });
    testWidgets('VersionSelection Screen', (WidgetTester tester) async {
      await TestUttily.BaseTestWidget(tester, VersionSelection(), async: true);
    });
    testWidgets('ModPackage Screen', (WidgetTester tester) async {
      await TestUttily.BaseTestWidget(tester, CurseForgeModPack(), async: true);
      await TestUttily.BaseTestWidget(tester, FTBModPack(), async: true);
    });
  });
}

class TestUttily {
  static Future<void> _Pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(
        navigatorKey: NavigationService.navigationKey, home: child));
  }

  static Future<void> BaseTestWidget(WidgetTester tester, Widget child,
      {bool async = false}) async {
    if (async) {
      await tester.runAsync(() async {
        await _Pump(tester, child);
      });
    } else {
      await _Pump(tester, child);
    }
  }
}
