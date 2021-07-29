import 'dart:io';

import 'package:path/path.dart';

late var home;

_getData() {
  Map<String, String> envVars = Platform.environment;
  if (Platform.isLinux) {
    home = envVars['HOME'];
    return join(home, ".local", "share");
  } else if (Platform.isMacOS) {
    home = envVars['HOME'];
  } else if (Platform.isWindows) {
    home = envVars['UserProfile'];
    return join(home, "AppData", "Roaming");
  }
}

_getConfig() {
  Map<String, String> envVars = Platform.environment;
  if (Platform.isLinux) {
    home = envVars['HOME'];
    return join(home, ".config");
  } else if (Platform.isMacOS) {
    home = envVars['HOME'];
  } else if (Platform.isWindows) {
    home = envVars['UserProfile'];
    return join(home, "AppData", "Local");
  }
}

var dataHome = Directory(join(_getData(), "RPMLauncher"));
var configHome = Directory(join(_getConfig(), "RPMLauncher"));