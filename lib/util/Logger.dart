import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/handler/window_handler.dart';
import 'package:rpmlauncher/util/Data.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

enum ErrorType {
  unknown,
  ui,
  dart,
  flutter,
  io,
  network,
  download,
  instance,
  data,
  modInfoParse,
  account,
}

class Logger {
  late final File _logFile;

  Logger([Directory? customDataHome]) {
    DateTime now = DateTime.now();
    _logFile = File(join((customDataHome ?? dataHome).absolute.path, 'logs',
        '${now.year}-${now.month}-${now.day}-${now.hour}-log.txt'));
    _logFile.createSync(recursive: true);
  }

  static final Logger _root = Logger();

  static Logger get currentLogger => _root;

  void _log(Object? object) {
    if (kDebugMode) {
      print(object.toString());
    }
    try {
      _logFile.writeAsStringSync(
          "[${DateTime.now().toString()}] [${WindowHandler.id}] $object\n",
          mode: FileMode.append);
    } catch (e) {
      if (!_logFile.existsSync()) {
        _logFile.createSync(recursive: true);
        _log(object);
      }
    }
  }

  void info(String info) {
    _log("[Info] $info");
    Sentry.addBreadcrumb(Breadcrumb(
      level: SentryLevel.info,
      message: info,
      type: 'console',
      timestamp: DateTime.now(),
    ));
  }

  void error(ErrorType type, Object? error, {StackTrace? stackTrace}) {
    String errorMessage = "[${type.name.toTitleCase()} Error] $error";
    stackTrace = stackTrace ?? StackTrace.current;
    errorMessage += "\n${stackTrace.toString()}";
    _log(errorMessage);
    Sentry.addBreadcrumb(Breadcrumb(
      level: SentryLevel.error,
      message: errorMessage,
      type: 'error',
      data: {'stackTrace': stackTrace.toString()},
      timestamp: DateTime.now(),
    ));
  }
}
