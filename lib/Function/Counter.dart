import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:provider/src/provider.dart';
import 'package:rpmlauncher/Utility/Loggger.dart';
import 'package:rpmlauncher/path.dart';

class Counter {
  Directory? _dataHome = path.currentDataHome;

  Logger _logger = Logger.currentLogger;

  Directory get dataHome => _dataHome!;

  Logger get logger => _logger;

  Future<void> updateDataHome() async {
    _dataHome = path.currentDataHome;
  }

  static Counter of(BuildContext context) {
    return context.read<Counter>();
  }
}
