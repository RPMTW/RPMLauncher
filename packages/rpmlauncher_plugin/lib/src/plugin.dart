import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:rpmlauncher_plugin/rpmlauncher_plugin.dart';

class RPMLauncherPlugin {
  static const MethodChannel _channel = MethodChannel('rpmlauncher_plugin');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// Get the system total physical memory in megabytes.
  static Future<MemoryInfo> getTotalPhysicalMemory() async {
    double inMegabytes(double bytes) {
      return bytes / 1024 / 1024;
    }

    if (Platform.isMacOS || Platform.isWindows) {
      double memoryBytes =
          await _channel.invokeMethod('getTotalPhysicalMemory');

      return MemoryInfo(inMegabytes(memoryBytes));
    } else if (Platform.isLinux) {
      File memInfoFile = File('/proc/meminfo');
      String memInfo = await memInfoFile.readAsString();
      String memTotal = LineSplitter.split(memInfo)
          .firstWhere((String line) => line.startsWith('MemTotal:'))
          .replaceAll('MemTotal:', '')
          .replaceAll('kB', '')
          .trim();

      return MemoryInfo(inMegabytes(int.parse(memTotal) * 1024));
    } else {
      throw Exception('Unsupported platform');
    }
  }
}
