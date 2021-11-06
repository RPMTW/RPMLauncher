import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpmlauncher/Model/MinecraftNews.dart';
import 'package:rpmlauncher/View/MinecraftNewsView.dart';
import 'package:xml/xml.dart';

import 'TestUttily.dart';

void main() async {
  setUpAll(() => TestUttily.init());

  group("RPMLauncher View Test -", () {
    testWidgets('MinecraftNewsView', (WidgetTester tester) async {
      MinecraftNews _news = MinecraftNews.fromXml(
          XmlDocument.parse(TestData.minecraftNews.getFileString()));

      await TestUttily.baseTestWidget(
          tester, Material(child: MinecraftNewsView(news: _news)),
          async: true);

      expect(find.text("Minecraft Snapshot 21w44a"), findsWidgets);
      expect(find.text("A Minecraft Java Snapshot"), findsWidgets);

      await tester.runAsync(() async {
        expect(
            find.image(Image.network(
              "https://minecraft.net/content/dam/games/minecraft/screenshots/snapshot-21w44a-1x1.jpg",
              fit: BoxFit.contain,
            ).image),
            findsWidgets);
      });
    }, variant: TestUttily.targetPlatformVariant);
  });
}
