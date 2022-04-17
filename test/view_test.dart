import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Model/Game/MinecraftNews.dart';
import 'package:rpmlauncher/Model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/View/InstanceView.dart';
import 'package:rpmlauncher/View/MinecraftNewsView.dart';
import 'package:xml/xml.dart';

import 'util/test_util.dart';

void main() async {
  setUpAll(() => TestUtil.init());

  group("RPMLauncher View Test -", () {
    testWidgets('Minecraft News View', (WidgetTester tester) async {
      MinecraftNews news = MinecraftNews.fromXml(
          XmlDocument.parse(TestData.minecraftNews.getFileString()));

      await TestUtil.baseTestWidget(
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
        await TestUtil.baseTestWidget(tester,
            const Material(child: InstanceView(side: MinecraftSide.client)),
            async: true);

        Finder notFoundText = find.text(I18n.format('homepage.instance.found'));

        expect(notFoundText, findsOneWidget);

        /// 建立一個安裝檔
        InstanceConfig.unknown().createConfigFile();
        await tester.pumpAndSettle();
      },
    );
  });
}
