import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/Extensions.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../main.dart';

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

  Logger([Directory? _dataHome]) {
    DateTime now = DateTime.now();
    _logFile = File(join((_dataHome ?? dataHome).absolute.path, 'logs',
        '${now.year}-${now.month}-${now.day}-${now.hour}-${now.hour}-log.txt'));
    _logFile.createSync(recursive: true);
  }

  static final Logger _root = Logger();

  static Logger get currentLogger => _root;

  void send(Object? object) {
    if (kDebugMode) {
      print(object.toString());
    }
    try {
      _logFile.writeAsStringSync("[${DateTime.now().toString()}] $object\n",
          mode: FileMode.append);
    } catch (e) {
      if (!_logFile.existsSync()) {
        _logFile.createSync(recursive: true);
        send(object);
      }
    }
  }

  void info(String info) {
    send("[Info] $info");
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
    send(errorMessage);
    Sentry.addBreadcrumb(Breadcrumb(
      level: SentryLevel.error,
      message: errorMessage,
      type: 'error',
      data: {'stackTrace': stackTrace.toString()},
      timestamp: DateTime.now(),
    ));
  }
}
