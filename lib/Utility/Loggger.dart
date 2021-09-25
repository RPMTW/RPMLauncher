import 'dart:io';

import 'package:path/path.dart';

import '../main.dart';

enum ErrorType { Unknown, UI, Dart, Flutter, IO, Network }

extension ErrorTypeToString on ErrorType {
  String toFixedString() {
    return this.toString().split('ErrorType.').join();
  }
}

class Logger {
  late final File _LogFile;

  Logger([Directory? _dataHome]) {
    DateTime now = DateTime.now();
    _LogFile = File(join((_dataHome ?? dataHome).absolute.path, 'logs',
        '${now.year}-${now.month}-${now.day}-${now.hour}-log.txt'));
    _LogFile.createSync(recursive: true);
  }

  static final Logger _root = Logger();

  static Logger get currentLogger => _root;

  void send(Object? object) {
    print(object);
    _LogFile.writeAsStringSync(
        "[${DateTime.now().toIso8601String()}] $object\n",
        mode: FileMode.append);
  }

  void info(Object info) {
    send("[Info] $info");
  }

  void error(ErrorType type, Object error) {
    send("[${type.toFixedString()} Error] $error");
  }
}
