import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:provider/src/provider.dart';
import 'package:rpmlauncher/path.dart';

class Counter {
  Directory? _dataHome = path.currentDataHome;

  Directory get dataHome => _dataHome!;

  Future<void> updateDataHome() async {
    _dataHome = path.currentDataHome;
  }

  static Counter of(BuildContext context) {
    return context.read<Counter>();
  }
}
