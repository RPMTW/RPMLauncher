import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/model/account/Account.dart';
import 'package:rpmlauncher/model/Game/GameLogs.dart';
import 'package:rpmlauncher/model/IO/Properties.dart';
import 'package:rpmlauncher/screen/account.dart';
import 'package:rpmlauncher/util/config.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/i18n.dart';
import 'package:rpmlauncher/view/row_scroll_view.dart';
import 'package:rpmlauncher/widget/AccountManageAction.dart';
import 'package:rpmlauncher/widget/dialog/agree_eula_dialog.dart';
import 'package:rpmlauncher/widget/dialog/CheckDialog.dart';
import 'package:rpmlauncher/widget/dialog/GameCrash.dart';
import 'package:rpmlauncher/widget/dialog/quick_setup.dart';
import 'package:rpmlauncher/widget/dialog/UnSupportedForgeVersion.dart';
import 'package:rpmlauncher/widget/FileDeleteError.dart';
import 'package:rpmlauncher/widget/rpmtw_design/DynamicImageFile.dart';
import 'package:rpmlauncher/widget/rpmtw_design/NewFeaturesWidget.dart';
import 'package:rpmlauncher/widget/settings/java_path.dart';
import 'package:uuid/uuid.dart';

import '../script/test_helper.dart';

void main() {
  setUpAll(() => TestHelper.init());

  testWidgets("RowScrollView", (WidgetTester tester) async {
    await TestHelper.baseTestWidget(
      tester,
      RowScrollView(
        child: Row(
          children: List.generate(
              100,
              (index) => Column(
                    children: const [
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
      await TestHelper.baseTestWidget(
          tester, const Material(child: JavaPathWidget()));

      expect(find.text("Java 8"), findsOneWidget);
      expect(find.text("Java 16"), findsOneWidget);
      expect(find.text("Java 17"), findsOneWidget);
    },
  );

  testWidgets(
    "I18nText Widget",
    (WidgetTester tester) async {
      await TestHelper.baseTestWidget(
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
      await TestHelper.baseTestWidget(tester,
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
      await TestHelper.baseTestWidget(
          tester,
          const Material(
              child: GameCrash(errorCode: 1, errorLog: "Hello World")));

      expect(find.text('Hello World'), findsOneWidget);
      expect(find.text("${I18n.format("log.game.crash.code")}: 1"),
          findsOneWidget);
    },
  );
  testWidgets(
    "CheckDialog Widget (press ok)",
    (WidgetTester tester) async {
      bool confirm = false;
      await TestHelper.baseTestWidget(
          tester,
          Material(
              child: CheckDialog(
            title: "Tips",
            message: "Hello World",
            onPressedOK: (context) {
              confirm = true;
            },
            onPressedCancel: (context) {
              confirm = false;
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
    "CheckDialog Widget (press cancel)",
    (WidgetTester tester) async {
      bool confirm = false;
      await TestHelper.baseTestWidget(
          tester,
          Material(
              child: CheckDialog(
            title: "Tips",
            message: "Hello World",
            onPressedOK: (context) {
              confirm = true;
            },
            onPressedCancel: (context) {
              confirm = false;
            },
          )));

      Finder cancelButton = find.text(I18n.format("gui.cancel"));

      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      expect(find.text('Hello World'), findsOneWidget);
      expect(find.text("Tips"), findsOneWidget);
      expect(confirm, false);
    },
  );

  testWidgets(
    "QuickSetup widget (agree)",
    (WidgetTester tester) async {
      await TestHelper.baseTestWidget(
          tester, const Material(child: QuickSetup()));

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

      Config.change('init', false);
    },
  );
  testWidgets(
    "QuickSetup widget (disagree)",
    (WidgetTester tester) async {
      await TestHelper.baseTestWidget(
          tester, const Material(child: QuickSetup()));

      expect(find.text(I18n.format('init.quick_setup.title')), findsOneWidget);
      expect(find.byType(SelectorLanguageWidget), findsOneWidget);

      Finder nextButton = find.text(I18n.format("gui.next"));

      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(
          find.text(I18n.format('rpmlauncher.privacy.title')), findsOneWidget);

      Finder disagreeButton = find.text(I18n.format("gui.disagree"));

      await tester.tap(disagreeButton);
      await tester.pumpAndSettle();

      expect(Config.getValue('init'), false);
    },
  );

  testWidgets("LogView Widget", (WidgetTester tester) async {
    String logString = TestData.fabric118Log.getFileString();
    GameLogs logs = GameLogs.empty();
    final List<String> lines = logString.split('\n');
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      if (line.isNotEmpty) {
        logs.addLog(line);
      }
    }

    await TestHelper.baseTestWidget(
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
  }, skip: Platform.isWindows);

  testWidgets(
    "Agree EULA Dialog Widget (Agree)",
    (WidgetTester tester) async {
      Properties properties = Properties({'eula': false.toString()});

      File eulaFile = File(join(
        dataHome.path,
        "eula.txt",
      ));

      await TestHelper.baseTestWidget(
          tester,
          Material(
              child:
                  AgreeEulaDialog(properties: properties, eulaFile: eulaFile)));

      expect(
          find.text(I18n.format("launcher.server.eula.title")), findsOneWidget);
      expect(find.text(I18n.format("launcher.server.eula")), findsOneWidget);

      Finder agreeButton = find.text(I18n.format("gui.agree"));

      await tester.tap(agreeButton);
      await tester.pumpAndSettle();

      Properties eulaProperties =
          Properties.decode(eulaFile.readAsStringSync());
      expect(eulaProperties['eula'], true.toString());
    },
  );

  testWidgets("Agree EULA Dialog Widget (Disagree)",
      (WidgetTester tester) async {
    Properties properties = Properties({'eula': false.toString()});

    File eulaFile = File(join(
      dataHome.path,
      "eula.txt",
    ));

    await TestHelper.baseTestWidget(
        tester,
        Material(
            child:
                AgreeEulaDialog(properties: properties, eulaFile: eulaFile)));
    Finder disagreeButton = find.text(I18n.format("gui.disagree"));

    await tester.tap(disagreeButton);
    await tester.pumpAndSettle();
  });
  testWidgets(
    "New Features Widget",
    (WidgetTester tester) async {
      await TestHelper.baseTestWidget(tester,
          const Material(child: NewFeaturesWidget(child: Text("Hello World"))));

      expect(find.text('Hello World'), findsOneWidget);
      expect(find.byIcon(Icons.star_rate), findsOneWidget);
    },
  );
  testWidgets(
    "Account Manage Button Widget (None account)",
    (WidgetTester tester) async {
      await TestHelper.baseTestWidget(
        tester,
        const Material(child: AccountManageButton()),
      );

      Finder button = find.byIcon(Icons.manage_accounts);

      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.byType(AccountScreen), findsOneWidget);
    },
  );
  testWidgets(
    "Account Manage Button Widget (Has account)",
    (WidgetTester tester) async {
      AccountStorage()
          .add(AccountType.microsoft, "", const Uuid().v4(), "RPMTW");

      await TestHelper.baseTestWidget(
          tester, const Material(child: AccountManageButton()));

      Finder button = find.byType(Tooltip);

      expect(button, findsOneWidget);
      expect(find.byType(InkResponse), findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.byType(AccountScreen), findsOneWidget);
    },
  );
  testWidgets(
    "File Delete Error Widget",
    (WidgetTester tester) async {
      await TestHelper.baseTestWidget(
          tester, const Material(child: FileDeleteError()));

      expect(find.text(I18n.format("rpmlauncher.file.delete.error")),
          findsOneWidget);
    },
  );
  testWidgets("Dynamic Image File Widget", (WidgetTester tester) async {
    File imageFile = File(join(
      dataHome.path,
      "temp",
      "icon.png",
    ));
    imageFile.createSync(recursive: true);
    TestData.rpmlauncherLogo.getFile().copySync(imageFile.path);

    await TestHelper.baseTestWidget(
        tester, Material(child: DynamicImageFile(imageFile: imageFile)));

    expect(find.byType(Image), findsOneWidget);

    imageFile.deleteSync(recursive: true);

    File imageFile2 = File(join(
      dataHome.path,
      "temp",
      "icon2.png",
    ));
    imageFile2.createSync(recursive: true);
    TestData.rpmlauncherLogo.getFile().copySync(imageFile2.path);
    await TestHelper.baseTestWidget(
        tester, Material(child: DynamicImageFile(imageFile: imageFile2)));
  }, skip: Platform.isWindows);
}
