import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/screen/loading_screen.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'util/data.dart';
import 'util/launcher_info.dart';
import 'util/logger.dart';
import 'util/util.dart';

Future<void> main(List<String> args) async {
  launcherArgs = args;

  await run();
}

Future<void> run() async {
  await runZonedGuarded(() async {
    LauncherInfo.startTime = DateTime.now();
    LauncherInfo.isDebugMode = kDebugMode;
    WidgetsFlutterBinding.ensureInitialized();

    await Data.init();

    logger.info("Starting");

    runApp(const LoadingScreen());

    logger.info("Start Done");
  }, (exception, stackTrace) async {
    if (Util.exceptionFilter(exception, stackTrace)) return;

    logger.error(ErrorType.unknown, exception, stackTrace: stackTrace);
    if (!LauncherInfo.isDebugMode && !kTestMode) {
      await Sentry.captureException(exception, stackTrace: stackTrace);
    }
  });
}
