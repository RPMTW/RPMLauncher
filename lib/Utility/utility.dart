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

  Map ParseLibMaven(lib){
   Map Result = {};
   String PackageName = lib["name"].toString().split(":")[0];
   String split_1 = lib["name"].toString().split("${PackageName}:").join("");
   String FileVersion = split_1.split(":")[split_1.split(":").length -1];
   String Filename = split_1.replaceAll(":", "-");
   String split_2 = Filename.split(FileVersion)[0];
   String Url = "${lib["url"]}${PackageName.replaceAll(".", "/")}/${split_2.substring(0,split_2.length-1)}/${FileVersion}/${Filename}";

   Result["Filename"] = "${Filename}.jar";
   Result["Url"] = "${Url}.jar";
   // Result["Sha1Hash"] = "${Url}.sha1";
   return Result;
  }
}
