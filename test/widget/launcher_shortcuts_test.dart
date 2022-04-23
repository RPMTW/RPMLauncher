import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpmlauncher/widget/launcher_shortcuts.dart';

import '../util/test_util.dart';

void main() {
  setUpAll(() => TestUtil.init());

  testWidgets('key down esc (can pop)', (tester) async {
    await TestUtil.baseTestWidget(tester, Builder(builder: (context) {
      return LauncherShortcuts(
          child: TextButton(
        child: const Text('Press me'),
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) => const AlertDialog(title: Text('Hello')));
        },
      ));
    }));
    Finder button = find.text('Press me');

    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsNothing);
  });

  testWidgets('key down esc (can\'t pop)', (tester) async {
    await TestUtil.baseTestWidget(tester, Builder(builder: (context) {
      return LauncherShortcuts(
          child: TextButton(
        child: const Text('Press me'),
        onPressed: () {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const AlertDialog(title: Text('Hello')));
        },
      ));
    }));
    Finder button = find.text('Press me');

    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsOneWidget);
  });
}
