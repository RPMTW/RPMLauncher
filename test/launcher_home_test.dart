import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpmlauncher/Screen/HomePage.dart';
import 'package:rpmlauncher/Screen/LauncherHome.dart';

import 'TestUttitily.dart';

void main() {
  setUpAll(() => TestUttily.init());
  testWidgets(
    'Launcher Home',
    (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(LauncherHome());
      });
    }
  );
  testWidgets(
    'Home Page',
    (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(const MaterialApp(home: HomePage()));
      });
    },
    skip: Platform.isMacOS
  );
}
