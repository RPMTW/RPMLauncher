import 'dart:io';

class utility {
  late var _LwjglVersionList = [];

  OpenFileManager(Dir) async {
    if (!Directory(Dir).existsSync()) {
      Directory(Dir).createSync(recursive: true);
    }
    if (Platform.isLinux) {
      await Process.run("xdg-open", [Dir]);
    } else if (Platform.isWindows) {
      await Process.run("start", [Dir], runInShell: true);
    } else if (Platform.isMacOS) {
      await Process.run("open", [Dir]);
    }
  }

  bool ParseLibRule(Map<String, dynamic> lib) {
    if (lib["rules"] != null) {
      if (lib["rules"].length > 1) {
        if (lib["rules"][0]["action"] == 'allow' &&
            lib["rules"][1]["action"] == 'disallow' &&
            lib["rules"][1]["os"]["name"] == 'osx') {
          return this.getOS() == 'osx';
        } else {
          return true;
        }
      } else {
        if (lib["rules"][0]["action"] == 'allow' &&
            lib["rules"][0]["os"] != null) return this.getOS() != 'osx';
      }
    }
    return false;
  }

  String? getOS() {
    if (Platform.isWindows) {
      return "windows";
    }
    if (Platform.isLinux) {
      return "linux";
    }
    if (Platform.isMacOS) {
      return "osx";
    }
    return null;
  }
}
