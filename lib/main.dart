import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/config/config_helper.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/ui/screens/loading_screen.dart';
import 'package:rpmlauncher/util/launcher_path.dart';
// import 'package:sentry_flutter/sentry_flutter.dart';

import 'util/data.dart';
import 'util/launcher_info.dart';
import 'util/logger.dart';
import 'util/util.dart';

/// Main entry point of the application.
Future<void> main(List<String> args) async {
  launcherArgs = args;

  await run();
}

Future<void> run() async {
  await runZonedGuarded(() async {
    LauncherInfo.startTime = DateTime.now();
    LauncherInfo.isDebugMode = kDebugMode;
    WidgetsFlutterBinding.ensureInitialized();

    await initBeforeRunApp();

    logger.info('Starting');

    runApp(const LoadingScreen());
    // runApp(const SentryScreenshotWidget(child: LoadingScreen()));

    logger.info('Start Done');
  }, (exception, stackTrace) async {
    if (Util.exceptionFilter(exception, stackTrace)) return;

    logger.error(ErrorType.unknown, exception, stackTrace: stackTrace);
    // if (!LauncherInfo.isDebugMode && !kTestMode) {
    //   await Sentry.captureException(exception, stackTrace: stackTrace);
    // }
  });
}

Future<void> initBeforeRunApp() async {
  await LauncherPath.init();
  await configHelper.init();
  await I18n.init();
}
