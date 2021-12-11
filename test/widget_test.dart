import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpmlauncher/Model/Game/GameLogs.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/View/RowScrollView.dart';
import 'package:rpmlauncher/Widget/Dialog/CheckDialog.dart';
import 'package:rpmlauncher/Widget/Dialog/GameCrash.dart';
import 'package:rpmlauncher/Widget/Dialog/QuickSetup.dart';
import 'package:rpmlauncher/Widget/Dialog/UnSupportedForgeVersion.dart';
import 'package:rpmlauncher/Widget/Settings/JavaPath.dart';

import 'TestUttily.dart';

void main() {
  setUpAll(() => TestUttily.init());

  testWidgets("RowScrollView", (WidgetTester tester) async {
    await TestUttily.baseTestWidget(
      tester,
      RowScrollView(
        child: Row(
          children: List.generate(
              100,
              (index) => Column(
                    children: [
                      Text("Hello"),
                      Text("World"),
                    ],
                  )).toList(),
        ),
      ),
    );

    expect(find.text("Hello"), findsWidgets);
    expect(find.text("World"), findsWidgets);

    await tester.drag(find.text('Hello').first, const Offset(0.0, -300));
    await tester.pump();
  });
  testWidgets(
    "Java Path Widget",
    (WidgetTester tester) async {
      await TestUttily.baseTestWidget(
          tester, Material(child: JavaPathWidget()));

      expect(find.text("${I18n.format("java.version")}: 8"), findsOneWidget);
    },
  );

  testWidgets(
    "I18nText Widget",
    (WidgetTester tester) async {
      await TestUttily.baseTestWidget(
          tester,
          Material(
              child: Column(
            children: [
              I18nText("gui.ok"),
              I18nText.errorInfoText(),
              I18nText.tipsInfoText()
            ],
          )));

      expect(find.text(I18n.format('gui.ok')), findsOneWidget);
      expect(find.text(I18n.format('gui.error.info')), findsOneWidget);
      expect(find.text(I18n.format('gui.tips.info')), findsOneWidget);
    },
  );
  testWidgets(
    "UnSupportedForgeVersion Widget",
    (WidgetTester tester) async {
      await TestUttily.baseTestWidget(tester,
          Material(child: UnSupportedForgeVersion(gameVersion: "1.7.10")));

      expect(
          find.text(I18n.format('version.list.mod.loader.forge.error',
              args: {"version": "1.7.10"})),
          findsOneWidget);
    },
  );
  testWidgets(
    "GameCrash Widget",
    (WidgetTester tester) async {
      await TestUttily.baseTestWidget(
          tester,
          Material(
              child: GameCrash(
            errorCode: 1,
            errorLog: "Hello World",
            newWindow: false,
          )));

      expect(find.text('Hello World'), findsOneWidget);
      expect(find.text("${I18n.format("log.game.crash.code")}: 1"),
          findsOneWidget);
    },
  );
  testWidgets(
    "CheckDialog Widget",
    (WidgetTester tester) async {
      bool confirm = false;
      await TestUttily.baseTestWidget(
          tester,
          Material(
              child: CheckDialog(
            title: "Tips",
            message: "Hello World",
            onPressedOK: () {
              confirm = true;
            },
          )));

      Finder confirmButton = find.text(I18n.format("gui.confirm"));

      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(find.text('Hello World'), findsOneWidget);
      expect(find.text("Tips"), findsOneWidget);
      expect(confirm, true);
    },
  );

  testWidgets(
    "QuickSetup Widget",
    (WidgetTester tester) async {
      await TestUttily.baseTestWidget(tester, Material(child: QuickSetup()));

      expect(find.text(I18n.format('init.quick_setup.title')), findsOneWidget);
      expect(find.byType(SelectorLanguageWidget), findsOneWidget);

      Finder nextButton = find.text(I18n.format("gui.next"));

      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(
          find.text(I18n.format('rpmlauncher.privacy.title')), findsOneWidget);

      Finder agreeButton = find.text(I18n.format("gui.agree"));

      await tester.tap(agreeButton);
      await tester.pumpAndSettle();

      expect(Config.getValue('init'), true);
    },
  );
  testWidgets(
    "LogView Widget",
    (WidgetTester tester) async {
      String logString = TestData.fabric118Log.getFileString();
      GameLogs logs = GameLogs.empty();
      final List<String> lines = logString.split('\n');
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];
        if (line.isNotEmpty) {
          logs.addLog(line);
        }
      }

      await TestUttily.baseTestWidget(
          tester,
          Material(
              child: ListView(children: logs.map((e) => e.widget).toList())));

      expect(find.text('Loading for game Minecraft 1.18'), findsOneWidget);

      expect(find.text('main'), findsWidgets);

      await tester.dragUntilVisible(find.text("已中斷宇宙通訊的連線"),
          find.byType(ListView), const Offset(0.0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Render thread'), findsWidgets);
      expect(find.text("已中斷宇宙通訊的連線"), findsOneWidget);
    },
  );
}
