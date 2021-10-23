import 'dart:io';

List<String> _getArgs(String file, mode) {
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

Future<ProcessResult?> chmod(String file, {String mode = '0o777'}) async {
  if (Platform.isLinux || Platform.isMacOS) {
    List<String> args = _getArgs(file, mode);
    return await Process.run('chmod', args);
  }
}
