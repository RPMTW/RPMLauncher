import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpmlauncher/main.dart' as rwl;

import 'TestUttily.dart';

void main() {
  setUpAll(() => TestUttily.init());
  testWidgets(
    'Launcher Home',
    (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(rwl.LauncherHome());
      });
    }
  );
  testWidgets(
    'Home Page',
    (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(MaterialApp(home: rwl.HomePage()));
      });
    },
    skip: Platform.isMacOS
  );
}
