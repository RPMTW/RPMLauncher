import 'dart:io';

import 'package:path/path.dart';
import 'package:rpmlauncher/path.dart';

late final File LogFile;

class Logger {
  static void init() {
    DateTime now = DateTime.now();
    LogFile = File(join(dataHome.absolute.path, 'logs',
        '${now.year}-${now.month}-${now.day}-${now.hour}-${now.minute}-${now.second}-log.txt'));
    LogFile.createSync(recursive: true);
  }

  static void send(Object? object) {
    print(object);
    LogFile.writeAsStringSync("[${DateTime.now().toIso8601String()}] $object\n",
        mode: FileMode.append);
  }
}
