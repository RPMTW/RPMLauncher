import 'package:flutter_test/flutter_test.dart';
import 'package:rpmlauncher/Screen/About.dart';
import 'package:rpmlauncher/Screen/Account.dart';

import 'TestUttily.dart';

void main() async {
  setUpAll(() => TestUttily.init());

  group("RPMLauncher Screen Test -", () {
    // testWidgets('Settings Screen', (WidgetTester tester) async {
    //   await TestUttily.baseTestWidget(tester, SettingScreen());
    //   expect(find.text(I18n.format("settings.title")), findsOneWidget);
    // }, variant: TargetPlatformVariant.desktop());
    testWidgets('About Screen', (WidgetTester tester) async {
      await TestUttily.baseTestWidget(tester, AboutScreen());
    }, variant: TargetPlatformVariant.desktop());
    testWidgets('Account Screen', (WidgetTester tester) async {
      await TestUttily.baseTestWidget(tester, AccountScreen(), async: true);
    }, variant: TargetPlatformVariant.desktop());
    // testWidgets('VersionSelection Screen', (WidgetTester tester) async {
    //   await TestUttily.baseTestWidget(tester, VersionSelection(), async: true);
    // }, variant: TargetPlatformVariant.desktop());
    // testWidgets('ModPackage Screen', (WidgetTester tester) async {
    //   await TestUttily.baseTestWidget(tester, CurseForgeModPack(), async: true);
    //   await TestUttily.baseTestWidget(tester, FTBModPack(), async: true);
    // }, variant: TargetPlatformVariant.desktop());
  });
}
