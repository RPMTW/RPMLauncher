import 'dart:io';

class ProcessUtil {
  static List<String> _getChmodArgs(String file, mode) {
    if (mode is num) {
      mode = mode.toString();
    }
    if (mode is String) {
      if (mode.startsWith('0o')) {
        mode = mode.substring(2);
      }
      return [mode, file];
    }
    return [];
  }

  static Future<ProcessResult?> chmod(String file,
      {String mode = '0o777'}) async {
    if (Platform.isLinux || Platform.isMacOS) {
      List<String> args = _getChmodArgs(file, mode);
      return await Process.run('chmod', args);
    }
    return null;
  }

  static Future<ProcessResult?> xdgOpen(String uri) async {
    if (Platform.isLinux) {
      return await Process.run('xdg-open', [uri]);
    }
    return null;
  }
}
