import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpmlauncher/Screen/About.dart';
import 'package:rpmlauncher/Screen/Account.dart';
import 'package:rpmlauncher/Screen/CurseForgeModPack.dart';
import 'package:rpmlauncher/Screen/Settings.dart';
import 'package:rpmlauncher/Screen/VersionSelection.dart';
import 'package:rpmlauncher/Utility/I18n.dart';

import 'TestUttily.dart';

void main() async {
  setUpAll(() => TestUttily.init());

  group("RPMLauncher Screen Test -", () {
    testWidgets('Settings Screen', (WidgetTester tester) async {
      await TestUttily.baseTestWidget(tester, SettingScreen());
      expect(find.text(I18n.format("settings.title")), findsOneWidget);
    }, variant: TestUttily.targetPlatformVariant);
    testWidgets('About Screen', (WidgetTester tester) async {
      await TestUttily.baseTestWidget(tester, AboutScreen());
    }, variant: TestUttily.targetPlatformVariant);
    testWidgets('Account Screen', (WidgetTester tester) async {
      await TestUttily.baseTestWidget(tester, AccountScreen(), async: true);
    }, variant: TestUttily.targetPlatformVariant);
    testWidgets('VersionSelection Screen', (WidgetTester tester) async {
      await TestUttily.baseTestWidget(tester, VersionSelection(), async: true);

      expect(find.text("1.17.1"), findsOneWidget);
    }, variant: TestUttily.targetPlatformVariant);
    testWidgets('CurseForge ModPack Screen', (WidgetTester tester) async {
      await TestUttily.baseTestWidget(tester, CurseForgeModPack(), async: true);

      expect(find.text("SkyFactory 4"), findsOneWidget);

      // await TestUttily.baseTestWidget(tester, FTBModPack(), async: true);
    }, variant: TestUttily.targetPlatformVariant);
  });
}
