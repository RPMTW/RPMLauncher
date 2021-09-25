import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpmlauncher/LauncherInfo.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:rpmlauncher/main.dart' as RWL;
import 'package:rpmlauncher/path.dart';

void main() {
  testWidgets('Launcher Home', (WidgetTester tester) async {
    LauncherInfo.isDebugMode = kDebugMode;
    HttpOverrides.global = null;
    await path().init();
    TestWidgetsFlutterBinding.ensureInitialized();
    await i18n.init();
    await tester.runAsync(() async {
      await tester.pumpWidget(RWL.LauncherHome());
    });
  });
  testWidgets('Home Page', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(home: RWL.HomePage()));
    });
  });
}
