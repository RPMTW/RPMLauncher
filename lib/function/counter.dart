import 'dart:io';

import 'package:flutter/cupertino.dart';
// ignore: implementation_imports
import 'package:provider/src/provider.dart';
import 'package:rpmlauncher/util/launcher_info.dart';
import 'package:rpmlauncher/util/logger.dart';
import 'package:rpmlauncher/util/launcher_path.dart';

class Counter {
  final Directory dataHome;
  final Directory defaultDataHome;
  final Logger logger;
  final bool testMode;

  const Counter(
      this.dataHome, this.defaultDataHome, this.logger, this.testMode);

  static Counter of(BuildContext context) {
    return context.read<Counter>();
  }

  factory Counter.create() {
    return Counter(LauncherPath.currentDataHome, LauncherPath.defaultDataHome,
        Logger.current, kTestMode);
  }
}
