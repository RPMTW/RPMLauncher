import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpmlauncher/screen/HomePage.dart';
import 'package:rpmlauncher/screen/main_screen.dart';

import 'util/test_util.dart';

void main() {
  setUpAll(() => TestUtil.init());
  testWidgets('Launcher Home', (WidgetTester tester) async {
    await tester.pumpWidget(const MainScreen());
  });
  testWidgets('Home Page', (WidgetTester tester) async {
    await TestUtil.baseTestWidget(tester, const HomePage(), async: true);
  }, skip: Platform.isMacOS);
}
