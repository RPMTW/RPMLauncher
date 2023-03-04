import 'dart:io';
import 'dart:isolate';

import 'package:rpmlauncher/util/launcher_info.dart';
import 'package:rpmlauncher/util/logger.dart';
import 'package:rpmlauncher/util/launcher_path.dart';
import 'package:rpmtw_api_client/rpmtw_api_client.dart';

class IsolateOption<T> {
  bool _initialized = false;

  final T _argument;
  final List<SendPort>? _ports;
  final Directory _currentDataHome;
  final Directory _defaultDataHome;
  final Logger _logger;
  final bool _isTestMode;

  IsolateOption._(this._argument, this._ports, this._currentDataHome,
      this._defaultDataHome, this._logger, this._isTestMode);

  factory IsolateOption.create(T argument, {List<SendPort>? ports}) {
    return IsolateOption<T>._(
      argument,
      ports,
      LauncherPath.currentDataHome,
      LauncherPath.defaultDataHome,
      Logger.current,
      kTestMode,
    );
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

  SendPort? getPort(int index) {
    _checkInit();
    return _ports?[index];
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

    LauncherPath.setCustomDataHome(_currentDataHome, _defaultDataHome);
    Logger.setCustomLogger(_logger);
    kTestMode = _isTestMode;
    RPMTWApiClient.init();

    _initialized = true;
  }
}
