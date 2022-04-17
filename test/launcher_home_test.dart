import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpmlauncher/screen/HomePage.dart';
import 'package:rpmlauncher/screen/LauncherHome.dart';

import 'util/test_util.dart';

void main() {
  setUpAll(() => TestUtil.init());
  testWidgets('Launcher Home', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: LauncherHome()));
    });
  });
  testWidgets('Home Page', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
    });
  }, skip: Platform.isMacOS);
}
