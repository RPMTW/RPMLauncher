import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpmlauncher/model/Game/instance.dart';
import 'package:rpmlauncher/model/Game/MinecraftNews.dart';
import 'package:rpmlauncher/model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/view/instance_view.dart';
import 'package:rpmlauncher/view/MinecraftNewsView.dart';

import 'script/test_helper.dart';

void main() async {
  setUpAll(() => TestHelper.init());

  group("RPMLauncher View Test -", () {
    testWidgets('Minecraft News View', (WidgetTester tester) async {
      MinecraftNews news = MinecraftNews.formMap(
          json.decode(TestData.minecraftNews.getFileString()));

      await TestHelper.baseTestWidget(
          tester, Material(child: MinecraftNewsView(news: news)),
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

      await tester.runAsync(
          () async => await Future.delayed(const Duration(seconds: 5)));

      Finder newsWidget = find.byType(ListTile);

      await tester.tap(newsWidget.first);
      await tester.pumpAndSettle();

      Finder newsLinkWidget = find.byIcon(Icons.open_in_browser);

      await tester.tap(newsLinkWidget.first);
      await tester.pumpAndSettle();

      Finder newsImage = find.byType(InkWell);

      await tester.tap(newsImage.first);
      await tester.pumpAndSettle();
    });
    testWidgets(
      "Instance View",
      (WidgetTester tester) async {
        await TestHelper.baseTestWidget(tester,
            const Material(child: InstanceView(side: MinecraftSide.client)),
            async: true);

        final Finder notFoundText =
            find.text(I18n.format('homepage.instance.found'));

        expect(notFoundText, findsOneWidget);

        /// 建立一個安裝檔
        final InstanceConfig config = InstanceConfig.unknown()
          ..createConfigFile();
        await tester.pumpAndSettle();

        final Instance instance = Instance.fromUUID(config.uuid)!;
        expect(instance.uuid, config.uuid);
      },
    );
  });
}
