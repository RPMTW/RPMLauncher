import 'dart:io';

import 'package:path/path.dart';
import 'package:rpmlauncher/path.dart';

class Logger {
  late final File _LogFile;
  Logger() {
    DateTime now = DateTime.now();
    _LogFile = File(join(dataHome.absolute.path, 'logs',
        '${now.year}-${now.month}-${now.day}-${now.hour}-log.txt'));
    _LogFile.createSync(recursive: true);
  }

  void send(Object? object) {
    print(object);
    _LogFile.writeAsStringSync(
        "[${DateTime.now().toIso8601String()}] $object\n",
        mode: FileMode.append);
  }
}
