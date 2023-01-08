import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_context_navigation/no_context_navigation.dart';
import 'package:provider/provider.dart';
import 'package:rpmlauncher/function/counter.dart';
import 'package:rpmlauncher/main.dart';
import 'package:rpmlauncher/route/generate_route.dart';
import 'package:rpmlauncher/ui/theme/theme_provider.dart';
import 'package:rpmlauncher/util/launcher_info.dart';

class TestHelper {
  static Future<void> _pump(
    WidgetTester tester,
    Widget child,
  ) async {
    await tester.pumpWidget(Provider(
      create: (context) {
        return Counter.create();
      },
      child: ThemeProvider(
        builder: (context, theme) => MaterialApp(
          navigatorKey: NavigationService.navigationKey,
          home: child,
          onGenerateRoute: onGenerateRoute,
        ),
      ),
    ));
  }

  static Future<void> baseTestWidget(WidgetTester tester, Widget child,
      {bool async = false,
      Duration asyncDuration = const Duration(seconds: 2)}) async {
    if (async) {
      await tester.runAsync(() async {
        await _pump(tester, child);
        await Future.delayed(asyncDuration);
      });
      await tester.pumpAndSettle();
    } else {
      await _pump(tester, child);
      await tester.pump();
    }
  }

  static Future<void> init() async {
    LauncherInfo.isDebugMode = kDebugMode;
    kTestMode = true;
    TestWidgetsFlutterBinding.ensureInitialized();
    await initBeforeRunApp();
  }
}
