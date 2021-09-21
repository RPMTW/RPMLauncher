import 'dart:io';

import 'package:path/path.dart';

import '../main.dart';

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

  void error(String ErrorType, Object error) {
    send("$ErrorType: $error");
  }
}
