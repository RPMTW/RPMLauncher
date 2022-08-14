import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/handler/window_handler.dart';
import 'package:rpmlauncher/util/launcher_info.dart';
import 'package:rpmlauncher/util/data.dart';
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
  parseModInfo,
  authorization,
  modpack
}

class Logger {
  final File _logFile;

  const Logger._(this._logFile);

  factory Logger.create() {
    final DateTime now = DateTime.now();
    final File file = File(join(dataHome.absolute.path, 'logs',
        '${now.year}-${now.month}-${now.day}-${now.hour}-log.txt'));
    file.createSync(recursive: true);

    return Logger._(file);
  }

  static final Logger root = Logger.create();
  static Logger? custom;

  static Logger get current => custom ?? root;

  static void setCustomLogger(Logger logger) {
    custom = logger;
  }

  Future<void> _log(Object? object) async {
    if (kDebugMode) {
      print(object);
    }

    try {
      await _logFile.writeAsString(
          "[${DateTime.now().toIso8601String()}] [${LauncherInfo.getFullVersion()}/${WindowHandler.id}] $object\n",
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
    String errorMessage =
        "[${type.name.toCapitalizedWithSpace()} Error] $error";
    stackTrace ??= StackTrace.current;
    errorMessage += "\n$stackTrace";
    _log(errorMessage);

    Sentry.addBreadcrumb(Breadcrumb(
      level: SentryLevel.error,
      message: error?.toString(),
      type: 'error',
      data: {'stackTrace': stackTrace.toString(), 'type': type.name},
      timestamp: DateTime.now(),
    ));
  }
}
