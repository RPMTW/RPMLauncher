import 'dart:io';

import 'package:flutter/cupertino.dart';
// ignore: implementation_imports
import 'package:provider/src/provider.dart';
import 'package:rpmlauncher/util/Logger.dart';
import 'package:rpmlauncher/util/launcher_path.dart';

class Counter {
  Directory? _dataHome = LauncherPath.currentDataHome;

  final Logger _logger = Logger.currentLogger;

  Directory get dataHome => _dataHome!;

  Logger get logger => _logger;

  Future<void> updateDataHome() async {
    _dataHome = LauncherPath.currentDataHome;
  }

  static Counter of(BuildContext context) {
    return context.read<Counter>();
  }
}
