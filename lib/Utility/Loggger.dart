import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

import '../main.dart';

enum ErrorType { unknown, ui, dart, flutter, io, network }

class Logger {
  late final File _logFile;

  Logger([Directory? _dataHome]) {
    DateTime now = DateTime.now();
    _logFile = File(join((_dataHome ?? dataHome).absolute.path, 'logs',
        '${now.year}-${now.month}-${now.day}-${now.hour}-log.txt'));
    _logFile.createSync(recursive: true);
  }

  static final Logger _root = Logger();

  static Logger get currentLogger => _root;

  void send(Object? object) {
    if (kDebugMode) {
      print(object);
    }
    _logFile.writeAsStringSync(
        "[${DateTime.now().toIso8601String()}] $object\n",
        mode: FileMode.append);
  }

  void info(String info) {
    send("[Info] $info");
  }

  void error(ErrorType type, Object error) {
    send("[${type.name} Error] $error");
  }
}
