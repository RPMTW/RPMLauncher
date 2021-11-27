import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/View/RowScrollView.dart';
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
}
