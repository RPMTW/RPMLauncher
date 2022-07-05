import 'dart:isolate';

import 'package:rpmlauncher/function/counter.dart';
import 'package:rpmlauncher/util/launcher_info.dart';
import 'package:rpmlauncher/util/logger.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/launcher_path.dart';
import 'package:rpmtw_api_client/rpmtw_api_client.dart';

class IsolateOption<T> {
  bool _initialized = false;

  final Counter _counter;
  final T _argument;
  final List<SendPort>? _ports;

  IsolateOption._(this._counter, this._argument, this._ports);

  factory IsolateOption.create(T argument, {List<ReceivePort>? ports}) {
    return IsolateOption<T>._(Counter.of(navigator.context), argument,
        ports?.map((e) => e.sendPort).toList());
  }

  Counter get counter {
    _checkInit();
    return _counter;
  }

  T get argument {
    _checkInit();
    return _argument;
  }

  void sendData(dynamic data, {int index = 0}) {
    _checkInit();
    SendPort? port = _ports?[index];
    port?.send(data);
  }

  void _checkInit() {
    if (!_initialized) {
      throw Exception(
          'IsolateOption is not initialized, please call IsolateOption#init()');
    }
  }

  void init() {
    if (_initialized) {
      return;
    }

    LauncherPath.setCustomDataHome(_counter.dataHome);
    Logger.setCustomLogger(_counter.logger);
    kTestMode = _counter.testMode;
    RPMTWApiClient.init();

    _initialized = true;
  }
}
