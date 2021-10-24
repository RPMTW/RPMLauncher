import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpmlauncher/Utility/LauncherInfo.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/main.dart' as rwl;
import 'package:rpmlauncher/Utility/RPMPath.dart';

void main() {
  testWidgets('Launcher Home', (WidgetTester tester) async {
    LauncherInfo.isDebugMode = kDebugMode;
    HttpOverrides.global = null;
    TestWidgetsFlutterBinding.ensureInitialized();
    await RPMPath.init();
    await I18n.init();
    await tester.runAsync(() async {
      await tester.pumpWidget(rwl.LauncherHome());
    });
  });
  testWidgets('Home Page', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(home: rwl.HomePage()));
    });
  });
}
