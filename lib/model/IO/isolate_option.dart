import 'dart:isolate';

import 'package:rpmlauncher/function/counter.dart';
import 'package:rpmlauncher/util/LauncherInfo.dart';
import 'package:rpmlauncher/util/Logger.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/launcher_path.dart';

class IsolateOption<T> {
  bool _initialized = false;

  final Counter _counter;
  final T _argument;
  final SendPort? _port;

  IsolateOption._(this._counter, this._argument, this._port);

  factory IsolateOption.create(T argument, {SendPort? port}) {
    return IsolateOption<T>._(Counter.of(navigator.context), argument, port);
  }

  Counter get counter {
    init();
    return _counter;
  }

  T get argument {
    init();
    return _argument;
  }

  void sendData(dynamic data) {
    init();
    _port?.send(data);
  }

  void init() {
    if (_initialized) {
      return;
    }

    LauncherPath.setCustomDataHome(_counter.dataHome);
    Logger.setCustomLogger(_counter.logger);
    kTestMode = _counter.testMode;

    _initialized = true;
  }
}
